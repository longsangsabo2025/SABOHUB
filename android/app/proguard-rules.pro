-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Google Play Core (Fix R8 missing class errors)
-dontwarn com.google.android.play.core.**
-keep class com.google.android.play.core.** { *; }

# Supabase
-keep class io.supabase.** { *; }
-dontwarn io.supabase.**

# Dio
-keep class com.squareup.okhttp3.** { *; }
-dontwarn com.squareup.okhttp3.**

# SQLite
-keep class org.sqlite.** { *; }
-dontwarn org.sqlite.**

# Keep native methods
-keepclassmembers class * {
    native <methods>;
}
