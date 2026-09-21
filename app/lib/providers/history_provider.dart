import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/app_error.dart';
import '../models/image_analysis.dart';
import '../services/api_service.dart';
import '../services/database_service.dart';

enum HistoryStatus { loading, loaded, error, empty }

/// Owns the persisted list of past analyses. Reads from the local SQLite
/// cache immediately (so the screen never shows a blank loader if we've seen
/// data before), then refreshes from the backend in the background — this
/// gives a usable "offline mode" for previously-synced history.
///
/// Failures are stored as an [AppErrorCode], never a pre-built English
/// string, so the History screen can render them in whichever language is
/// active (see `utils/error_messages.dart`).
class HistoryProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService.instance;
  final DatabaseService _db = DatabaseService.instance;

  HistoryStatus status = HistoryStatus.loading;
  List<ImageAnalysis> items = [];
  AppErrorCode? errorCode;

  Future<void> loadInitial() async {
    List<ImageAnalysis> cached = [];
    try {
      cached = await _db.getAll();
    } catch (_) {
      // Local cache unavailable (e.g. platform channel not ready yet, or a
      // plain widget-test environment with no sqflite plugin) — fall through
      // to the network refresh below rather than crashing the app.
    }
    if (cached.isNotEmpty) {
      items = cached;
      status = HistoryStatus.loaded;
      notifyListeners();
    }
    await refresh();
  }

  Future<void> refresh() async {
    try {
      final remote = await _apiService.fetchHistory();
      items = remote;
      status = items.isEmpty ? HistoryStatus.empty : HistoryStatus.loaded;
      errorCode = null;
      // Show the fresh list immediately; mirror it to the local SQLite cache
      // in the background in one batched transaction instead of blocking the
      // screen on N sequential platform-channel writes.
      notifyListeners();
      unawaited(_db.upsertAll(remote).catchError((_) {}));
      return;
    } on ApiException catch (e) {
      // If we already have cached items to show, don't blow away the screen —
      // just surface the error, otherwise show a full error state.
      errorCode = e.code;
      if (items.isEmpty) status = HistoryStatus.error;
    } catch (_) {
      errorCode = AppErrorCode.historyRefreshFailed;
      if (items.isEmpty) status = HistoryStatus.error;
    }
    notifyListeners();
  }

  /// Inserts or updates a single analysis at the front of the in-memory list
  /// immediately — called right after a fresh analysis or a new answered
  /// question, so History reflects it instantly instead of waiting for the
  /// next full network `refresh()` (which may not happen until the user
  /// manually pulls to refresh, since the tab's state survives tab switches).
  void prependOrUpdate(ImageAnalysis analysis) {
    items = [
      analysis,
      ...items.where((i) => i.id != analysis.id),
    ];
    status = HistoryStatus.loaded;
    notifyListeners();
    unawaited(_db.upsert(analysis).catchError((_) {}));
  }

  Future<void> deleteItem(String id) async {
    final previous = items;
    items = items.where((i) => i.id != id).toList();
    notifyListeners();
    try {
      await _apiService.deleteHistoryItem(id);
      await _db.delete(id);
    } catch (_) {
      items = previous; // roll back on failure
      notifyListeners();
    }
  }

  Future<void> clearAll() async {
    final previous = items;
    items = [];
    status = HistoryStatus.empty;
    notifyListeners();
    try {
      await _apiService.clearHistory();
      await _db.clearAll();
    } catch (_) {
      items = previous;
      status = HistoryStatus.loaded;
      notifyListeners();
    }
  }
}
