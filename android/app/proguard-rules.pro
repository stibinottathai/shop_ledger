# Flutter
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Share Plus
-keep class dev.fluttercommunity.plus.share.** { *; }

# Android Alarm Manager Plus - Keep background callback
-keep class dev.fluttercommunity.plus.androidalarmmanager.** { *; }

# Fix R8 errors for missing Play Core classes
-dontwarn com.google.android.play.core.**
-dontwarn io.flutter.embedding.engine.deferredcomponents.**
