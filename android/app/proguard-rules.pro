# Keep Flutter plugin implementations (R8 can strip these in release).
-keep class io.flutter.plugins.** { *; }
-keep class com.google.android.gms.** { *; }
-keep class androidx.datastore.** { *; }
-keep class androidx.preference.** { *; }
-keep class io.flutter.plugins.sharedpreferences.** { *; }

# Launcher activity — must match applicationId/namespace exactly.
-keep class space.d11s.niceproportions.MainActivity { *; }

# WorkManager (pulled in by play-services-ads) builds its Room database by
# reflection: Class.forName("...WorkDatabase_Impl").newInstance(). Old Room
# 2.2.5 consumer rules only say "-keep class * extends RoomDatabase", which in
# R8 full mode (AGP 8+ default) no longer keeps the no-arg constructor, so
# every release build crashed at startup in androidx.startup.InitializationProvider.
-keep class * extends androidx.room.RoomDatabase { <init>(); }
