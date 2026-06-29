# Keep Flutter and Dart classes
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.embedding.** { *; }

# Keep Hive generated classes
-keep class **_Adapter { *; }
-keep class ** extends com.google.gson.TypeAdapter { *; }

# Keep model classes
-keep class com.example.arabic_http_studio.models.** { *; }
-keep class com.example.arabic_http_studio.features.**.models.** { *; }

# Keep Riverpod
-keep class com.riverpod.** { *; }

# Don't warn about missing classes
-dontwarn org.ietf.jgss.**

# Keep encryption classes
-keep class org.bouncycastle.** { *; }
-dontwarn org.bouncycastle.**
