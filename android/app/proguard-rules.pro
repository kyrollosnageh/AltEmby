# Flutter
-keep class io.flutter.** { *; }
-keep class io.flutter.embedding.** { *; }

# media_kit / mpv JNI bindings
-keep class com.alexmercerind.** { *; }
-keep class com.alexmercerind.media_kit.** { *; }
-keep class com.alexmercerind.media_kit_video.** { *; }
-keep class com.alexmercerind.media_kit_libs_android_video.** { *; }

# Keep native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Hive
-keep class * extends com.google.crypto.tink.shaded.protobuf.GeneratedMessageLite { *; }

# Dio / OkHttp
-dontwarn okhttp3.**
-dontwarn okio.**
-keep class okhttp3.** { *; }
-keep class okio.** { *; }

# Flutter Secure Storage
-keep class com.it_nomads.fluttersecurestorage.** { *; }

# Prevent R8 from removing media_kit native libraries
-keep class org.jni.** { *; }
