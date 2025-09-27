# Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Required by the TensorFlow Lite library
-keep class org.tensorflow.lite.** { *; }

# This rule is often needed to prevent warnings related to the checker framework,
# which is a dependency of TensorFlow Lite. [1]
-dontwarn org.checkerframework.**

# Play Core library
-keep class com.google.android.play.core.** { *; }
