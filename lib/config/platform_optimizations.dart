/// Platform-specific performance optimizations configuration
class PlatformOptimizations {
  /// Enable platform-specific features
  static const bool enableDesktopOptimizations = true;
  static const bool enableMobileOptimizations = true;
  static const bool enableWebOptimizations = true;

  /// Image caching configuration
  static const int imageCacheSize = 100; // MB
  static const int imageMemorySizeLimit = 50 * 1024 * 1024; // 50MB

  /// Performance settings
  static const bool enableFrameRateLimiter = true;
  static const bool enablePerformanceOverlay = false;
  static const int targetFPS = 60;

  /// PDF rendering settings
  static const bool enableMultiThreadedPDFProcessing = true;
  static const int maxPDFCacheSizeMB = 200;

  /// Web-specific settings
  static const bool enableServiceWorker = true;
  static const bool enableOfflineSupport = false;
  static const bool enableProgressiveWebApp = true;

  /// Desktop window settings
  static const double minWindowWidth = 400;
  static const double minWindowHeight = 600;
  static const double defaultWindowWidth = 1200;
  static const double defaultWindowHeight = 800;

  /// Mobile settings
  static const bool enableHapticFeedback = true;
  static const bool enableSoundEffects = true;

  /// File processing
  static const int maxConcurrentOperations = 3;
  static const int chunkSizeBytes = 1024 * 1024; // 1MB chunks

  /// Network settings
  static const int connectTimeoutSeconds = 30;
  static const int receiveTimeoutSeconds = 60;
  static const bool enableCompression = true;

  /// Storage settings
  static const int maxCacheAgeDays = 30;
  static const int maxLocalStorageSizeMB = 500;
}

/// Platform-specific feature flags
class FeatureFlags {
  /// Desktop features
  static const bool windowManagerSupport = true;
  static const bool nativeFileDialogs = true;
  static const bool systemClipboardIntegration = true;

  /// Mobile features
  static const bool shareIntentSupport = true;
  static const bool fileAccessViaContentUri = true;
  static const bool nativePermissionsHandling = true;

  /// Web features
  static const bool indexedDBSupport = true;
  static const bool localStorageSupport = true;
  static const bool webWorkerSupport = true;

  /// Cross-platform features
  static const bool offlineSupport = false;
  static const bool syncSupport = false;
  static const bool cloudBackup = false;
}
