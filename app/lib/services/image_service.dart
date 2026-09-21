import 'dart:io';

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../utils/constants.dart';

/// Handles camera/gallery capture and client-side compression before upload.
/// Compressing on-device keeps upload times low and reduces the AI
/// provider's per-request cost (fewer tokens spent on image data).
class ImageService {
  final ImagePicker _picker = ImagePicker();

  Future<File?> pickFromCamera() async {
    final shot = await _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 2400,
      imageQuality: 92,
    );
    if (shot == null) return null;
    return _compress(File(shot.path));
  }

  Future<File?> pickFromGallery() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 2400,
    );
    if (picked == null) return null;
    return _compress(File(picked.path));
  }

  /// Downscale + re-encode as JPEG to keep uploads small and consistent
  /// regardless of the original format (JPEG/PNG/WebP/HEIC).
  Future<File> _compress(File original) async {
    final tempDir = await getTemporaryDirectory();
    final targetPath =
        '${tempDir.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.jpg';

    final result = await FlutterImageCompress.compressAndGetFile(
      original.absolute.path,
      targetPath,
      quality: AppConfig.uploadJpegQuality,
      minWidth: AppConfig.maxUploadDimension,
      minHeight: AppConfig.maxUploadDimension,
      format: CompressFormat.jpeg,
    );

    if (result == null) return original; // fall back to original if compression fails
    return File(result.path);
  }
}
