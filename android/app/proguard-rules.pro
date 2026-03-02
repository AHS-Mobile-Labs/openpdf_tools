# Proguard rules for OpenPDF Tools

# Preserve Flutter classes
-keep class io.flutter.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.plugin.** { *; }

# Preserve Google Play Core classes (for deferred components)
-keep class com.google.android.play.core.** { *; }
-keep class com.google.android.play.core.splitcompat.** { *; }
-keep class com.google.android.play.core.splitinstall.** { *; }
-keep class com.google.android.play.core.tasks.** { *; }

# Dart/Flutter method names
-keepclasseswithmembernames class * {
    native <methods>;
}

# Preserve enum constructors
-keepclassmembers class * extends java.lang.Enum {
    <init>(...);
}

# Preserve parcelable implementations
-keep class * implements android.os.Parcelable {
    public static final android.os.Parcelable$Creator *;
}

# Preserve serializable classes
-keep class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}

# Preserve app-specific classes
-keep class com.ahsmobilelabs.openpdf_tools.** { *; }

# Preserve all public methods and constructors
-keepclasseswithmembers public class * {
    public <methods>;
    public <init>();
}

# Preserve callback methods
-keepclassmembers class * {
    void onCreate(**);
    void onStart();
    void onRestart();
    void onResume();
    void onPause();
    void onStop();
    void onDestroy();
}

# PDF library rules
-keep class com.sun.pdfview.** { *; }
-keep class org.apache.pdfbox.** { *; }
-keep class org.bouncycastle.** { *; }

# Image compression library
-keep class com.alibaba.android.** { *; }

# Permission handler
-keep class com.baseflow.permissionhandler.** { *; }

# File picker
-keep class com.mr.flutter.plugin.filepicker.** { *; }

# Image picker
-keep class io.flutter.plugins.imagepicker.** { *; }

# Web view rules (if used)
-keep class android.webkit.** { *; }

# Don't obfuscate native method signatures
-keepclasseswithmembernames class * {
    native <methods>;
}

# Rules for debugging
-printmapping mapping.txt
-verbose

# Optimization settings
-optimizations !code/simplification/arithmetic,!code/simplification/cast,!field/*,!class/merging/*
-optimizationpasses 5

# Warning suppression
-dontwarn javax.annotation.**
-dontwarn org.checkerframework.**
-dontwarn com.google.android.play.core.**
