# JNA (used by vosk-android) loads classes by reflection: keep it whole.
-keep class com.sun.jna.** { *; }
-keepclassmembers class * extends com.sun.jna.** { public *; }
-keep class org.vosk.** { *; }
# JNA's desktop (AWT) helpers don't exist on Android and are never used.
-dontwarn java.awt.**
