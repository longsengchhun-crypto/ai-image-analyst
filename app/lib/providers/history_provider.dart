import 'package:flutter/foundation.dart';

import '../models/image_analysis.dart';
import '../services/api_service.dart';
import '../services/database_service.dart';

enum HistoryStatus { loading, loaded, error, empty }

/// Owns the persisted list of past analyses. Reads from the local SQLite
/// cache immediately (so the screen never shows a blank loader if we've seen
/// data before), then refreshes from the backend in the background — this
/// gives a usable "offline mode" for previously-synced history.
class HistoryProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService.instance;
  final DatabaseService _db = DatabaseService.instance;

  HistoryStatus status = HistoryStatus.loading;
  List<ImageAnalysis> items = [];
  String? errorMessage;

  Future<void> loadInitial() async {
    final cached = await _db.getAll();
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
      for (final item in remote) {
        await _db.upsert(item);
      }
      status = items.isEmpty ? HistoryStatus.empty : HistoryStatus.loaded;
      errorMessage = null;
    } on ApiException catch (e) {
      // If we already have cached items to show, don't blow away the screen —
      // just surface the error message; otherwise show a full error state.
      errorMessage = e.message;
      if (items.isEmpty) status = HistoryStatus.error;
    } catch (_) {
      errorMessage = 'Could not refresh history right now.';
      if (items.isEmpty) status = HistoryStatus.error;
    }
    notifyListeners();
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
