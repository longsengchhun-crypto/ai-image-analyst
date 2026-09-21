import 'dart:typed_data';

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';

import '../utils/constants.dart';

/// Handles camera/gallery capture and client-side compression before upload.
/// Compressing on-device keeps upload times low and reduces the AI
/// provider's per-request cost (fewer tokens spent on image data).
///
/// Works everywhere Flutter runs — mobile, desktop, and web — because it
/// operates entirely on bytes (`Uint8List`) rather than `dart:io File`,
/// which does not exist on the web platform. `image_picker` already returns
/// a cross-platform `XFile`, and `FlutterImageCompress.compressWithList`
/// compresses bytes-to-bytes without needing a filesystem path.
class ImageService {
  final ImagePicker _picker = ImagePicker();

  Future<Uint8List?> pickFromCamera() async {
    final shot = await _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 2400,
      imageQuality: 92,
    );
    if (shot == null) return null;
    return _compress(await shot.readAsBytes());
  }

  Future<Uint8List?> pickFromGallery() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 2400,
    );
    if (picked == null) return null;
    return _compress(await picked.readAsBytes());
  }

  /// Downscale + re-encode as JPEG to keep uploads small and consistent
  /// regardless of the original format (JPEG/PNG/WebP/HEIC).
  Future<Uint8List> _compress(Uint8List original) async {
    try {
      return await FlutterImageCompress.compressWithList(
        original,
        minWidth: AppConfig.maxUploadDimension,
        minHeight: AppConfig.maxUploadDimension,
        quality: AppConfig.uploadJpegQuality,
        format: CompressFormat.jpeg,
      );
    } catch (_) {
      return original; // fall back to the original bytes if compression fails
    }
  }
}
