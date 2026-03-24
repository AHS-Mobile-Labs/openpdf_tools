class PlatformOptimizations {
  static const bool enableDesktopOptimizations = true;
  static const bool enableMobileOptimizations = true;
  static const bool enableWebOptimizations = true;
  static const int imageCacheSize = 100;
  static const int imageMemorySizeLimit = 50 * 1024 * 1024;
  static const bool enableFrameRateLimiter = true;
  static const bool enablePerformanceOverlay = false;
  static const int targetFPS = 60;
  static const bool enableMultiThreadedPDFProcessing = true;
  static const int maxPDFCacheSizeMB = 200;
  static const bool enableServiceWorker = true;
  static const bool enableOfflineSupport = false;
  static const bool enableProgressiveWebApp = true;
  static const double minWindowWidth = 400;
  static const double minWindowHeight = 600;
  static const double defaultWindowWidth = 1200;
  static const double defaultWindowHeight = 800;
  static const bool enableHapticFeedback = true;
  static const bool enableSoundEffects = true;
  static const int maxConcurrentOperations = 3;
  static const int chunkSizeBytes = 1024 * 1024;
  static const int connectTimeoutSeconds = 30;
  static const int receiveTimeoutSeconds = 60;
  static const bool enableCompression = true;
  static const int maxCacheAgeDays = 30;
  static const int maxLocalStorageSizeMB = 500;
}

class FeatureFlags {
  static const bool windowManagerSupport = true;
  static const bool nativeFileDialogs = true;
  static const bool systemClipboardIntegration = true;
  static const bool shareIntentSupport = true;
  static const bool fileAccessViaContentUri = true;
  static const bool nativePermissionsHandling = true;
  static const bool indexedDBSupport = true;
  static const bool localStorageSupport = true;
  static const bool webWorkerSupport = true;
  static const bool offlineSupport = false;
  static const bool syncSupport = false;
  static const bool cloudBackup = false;
}
