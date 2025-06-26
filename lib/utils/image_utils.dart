import '../config/api_config.dart';

class ImageUtils {
  static String? getFullImageUrl(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) {
      return null;
    }

    // Agar allaqachon to'liq URL bo'lsa
    if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      return imagePath;
    }

    // Nisbiy yo'lni to'liq URL ga aylantirish
    String baseUrl = ApiConfig.baseUrl;

    // Base URL oxirida slash bor yoki yo'qligini tekshirish
    if (!baseUrl.endsWith('/')) {
      baseUrl += '/';
    }

    // Image path boshida slash bor yoki yo'qligini tekshirish
    String cleanPath = imagePath.startsWith('/') ? imagePath.substring(1) : imagePath;

    return baseUrl + cleanPath;
  }

  static String getInitials(String firstName, String lastName, String username) {
    if (firstName.isNotEmpty && lastName.isNotEmpty) {
      return '${firstName[0]}${lastName[0]}';
    } else if (firstName.isNotEmpty) {
      return firstName[0];
    } else if (lastName.isNotEmpty) {
      return lastName[0];
    } else {
      return username.isNotEmpty ? username[0].toUpperCase() : 'U';
    }
  }
}
