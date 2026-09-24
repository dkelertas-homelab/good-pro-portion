# Keep Flutter plugin implementations (R8 can strip these in release).
-keep class io.flutter.plugins.** { *; }
-keep class com.google.android.gms.** { *; }
-keep class androidx.datastore.** { *; }
-keep class androidx.preference.** { *; }
-keep class io.flutter.plugins.sharedpreferences.** { *; }
