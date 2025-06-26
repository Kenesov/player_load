import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

class ImageService {
  static final ImageService _instance = ImageService._internal();
  factory ImageService() => _instance;
  ImageService._internal();

  /// Rasmni siqish va o'lchamini kichraytirish
  Future<File?> compressImage(File imageFile, {
    int maxWidth = 800,
    int maxHeight = 800,
    int quality = 85,
    int maxSizeKB = 500, // Maksimal hajm KB da
  }) async {
    try {
      print('Original image size: ${await imageFile.length()} bytes');

      // Rasmni o'qish
      Uint8List imageBytes = await imageFile.readAsBytes();
      img.Image? image = img.decodeImage(imageBytes);

      if (image == null) {
        print('Failed to decode image');
        return null;
      }

      print('Original image dimensions: ${image.width}x${image.height}');

      // O'lchamni hisoblash (aspect ratio saqlab)
      int newWidth = image.width;
      int newHeight = image.height;

      if (newWidth > maxWidth || newHeight > maxHeight) {
        double aspectRatio = newWidth / newHeight;

        if (newWidth > newHeight) {
          newWidth = maxWidth;
          newHeight = (maxWidth / aspectRatio).round();
        } else {
          newHeight = maxHeight;
          newWidth = (maxHeight * aspectRatio).round();
        }
      }

      print('New image dimensions: ${newWidth}x${newHeight}');

      // Rasmni o'lchamini o'zgartirish
      img.Image resizedImage = img.copyResize(
        image,
        width: newWidth,
        height: newHeight,
        interpolation: img.Interpolation.linear,
      );

      // JPEG formatida siqish
      List<int> compressedBytes = img.encodeJpg(resizedImage, quality: quality);

      print('Compressed image size: ${compressedBytes.length} bytes');

      // Agar hali ham katta bo'lsa, sifatni pasaytirish
      int currentQuality = quality;
      while (compressedBytes.length > maxSizeKB * 1024 && currentQuality > 20) {
        currentQuality -= 10;
        compressedBytes = img.encodeJpg(resizedImage, quality: currentQuality);
        print('Re-compressed with quality $currentQuality: ${compressedBytes.length} bytes');
      }

      // Yangi fayl yaratish
      String originalPath = imageFile.path;
      String directory = originalPath.substring(0, originalPath.lastIndexOf('/'));
      String fileName = 'compressed_${DateTime.now().millisecondsSinceEpoch}.jpg';
      String newPath = '$directory/$fileName';

      File compressedFile = File(newPath);
      await compressedFile.writeAsBytes(compressedBytes);

      print('Final compressed image size: ${await compressedFile.length()} bytes');
      print('Compression ratio: ${((imageBytes.length - compressedBytes.length) / imageBytes.length * 100).toStringAsFixed(1)}%');

      return compressedFile;
    } catch (e) {
      print('Image compression error: $e');
      return null;
    }
  }

  /// Rasmni kvadrat qilib kesish (profile picture uchun)
  Future<File?> cropToSquare(File imageFile) async {
    try {
      Uint8List imageBytes = await imageFile.readAsBytes();
      img.Image? image = img.decodeImage(imageBytes);

      if (image == null) return null;

      // Eng kichik tomonni topish
      int size = image.width < image.height ? image.width : image.height;

      // Markazdan kvadrat kesish
      int x = (image.width - size) ~/ 2;
      int y = (image.height - size) ~/ 2;

      img.Image croppedImage = img.copyCrop(
        image,
        x: x,
        y: y,
        width: size,
        height: size,
      );

      // Fayl saqlash
      List<int> croppedBytes = img.encodeJpg(croppedImage, quality: 90);

      String originalPath = imageFile.path;
      String directory = originalPath.substring(0, originalPath.lastIndexOf('/'));
      String fileName = 'cropped_${DateTime.now().millisecondsSinceEpoch}.jpg';
      String newPath = '$directory/$fileName';

      File croppedFile = File(newPath);
      await croppedFile.writeAsBytes(croppedBytes);

      return croppedFile;
    } catch (e) {
      print('Image cropping error: $e');
      return null;
    }
  }

  /// Rasmni to'liq tayyorlash (crop + compress)
  Future<File?> prepareProfileImage(File imageFile) async {
    try {
      // Avval kvadrat qilib kesish
      File? croppedFile = await cropToSquare(imageFile);
      if (croppedFile == null) return null;

      // Keyin siqish
      File? compressedFile = await compressImage(
        croppedFile,
        maxWidth: 400,
        maxHeight: 400,
        quality: 80,
        maxSizeKB: 300, // Profile picture uchun 300KB yetarli
      );

      // Vaqtinchalik faylni o'chirish
      try {
        await croppedFile.delete();
      } catch (e) {
        print('Failed to delete temp file: $e');
      }

      return compressedFile;
    } catch (e) {
      print('Prepare profile image error: $e');
      return null;
    }
  }

  /// Fayl hajmini tekshirish
  Future<bool> isFileSizeAcceptable(File file, {int maxSizeKB = 500}) async {
    try {
      int fileSizeBytes = await file.length();
      int fileSizeKB = fileSizeBytes ~/ 1024;
      return fileSizeKB <= maxSizeKB;
    } catch (e) {
      return false;
    }
  }

  /// Fayl hajmini formatlash
  String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
