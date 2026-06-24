import 'package:path/path.dart' as p;

/// Centralized media extension definitions for files Resource Viewer can handle.
class MediaFileTypes {
  const MediaFileTypes._();

  static const imageExtensions = {
    '.jpg',
    '.jpeg',
    '.png',
    '.gif',
    '.webp',
    '.bmp',
    '.tiff',
    '.tif',
    '.avif',
  };

  static const pdfExtensions = {'.pdf'};

  static const videoExtensions = {
    '.mp4',
    '.mkv',
    '.avi',
    '.mov',
    '.wmv',
    '.flv',
    '.webm',
    '.m4v',
  };

  static const archiveExtensions = {'.zip', '.rar', '.7z', '.tar', '.gz'};

  /// Files that can appear in file sources and generic resource grids.
  static const supportedExtensions = {
    ...imageExtensions,
    ...pdfExtensions,
    ...videoExtensions,
    ...archiveExtensions,
  };

  /// Files that can be rendered or opened by organization-mode pages.
  ///
  /// This intentionally excludes tar/gz until archive viewing supports them.
  static const viewableExtensions = {
    ...imageExtensions,
    ...pdfExtensions,
    ...videoExtensions,
    '.zip',
    '.rar',
    '.7z',
  };

  static bool isImage(String nameOrPath) {
    return imageExtensions.contains(_extension(nameOrPath));
  }

  static bool isPdf(String nameOrPath) {
    return pdfExtensions.contains(_extension(nameOrPath));
  }

  static bool isVideo(String nameOrPath) {
    return videoExtensions.contains(_extension(nameOrPath));
  }

  static bool isArchive(String nameOrPath) {
    return archiveExtensions.contains(_extension(nameOrPath));
  }

  static bool isSupported(String nameOrPath) {
    return supportedExtensions.contains(_extension(nameOrPath));
  }

  static bool isViewable(String nameOrPath) {
    return viewableExtensions.contains(_extension(nameOrPath));
  }

  static bool canReuseOriginalPreviewBytes(String nameOrPath) {
    final extension = _extension(nameOrPath);
    return extension == '.jpg' || extension == '.jpeg' || extension == '.png';
  }

  static bool canFallbackToOriginalPreviewBytes(String nameOrPath) {
    final extension = _extension(nameOrPath);
    return imageExtensions.contains(extension);
  }

  static String _extension(String nameOrPath) {
    if (nameOrPath.startsWith('.') && !nameOrPath.contains('/')) {
      return nameOrPath.toLowerCase();
    }
    return p.extension(nameOrPath).toLowerCase();
  }
}
