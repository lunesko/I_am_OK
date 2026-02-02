# Ya OK ProGuard Rules

# Keep Rust native library methods
-keep class app.poruch.ya_ok.** { *; }
-keepclassmembers class app.poruch.ya_ok.** { *; }

# Keep native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep JNI methods
-keepclasseswithmembers class * {
    native <methods>;
}

# Preserve line numbers for debugging
-keepattributes SourceFile,LineNumberTable

# Crypto - keep Ed25519, X25519 classes if using Java implementations
-keep class * extends java.security.** { *; }

# Keep custom exceptions
-keep public class * extends java.lang.Exception

# AndroidX
-keep class androidx.** { *; }
-dontwarn androidx.**

# Kotlin
-keep class kotlin.** { *; }
-dontwarn kotlin.**

# Firebase (if using)
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**

# Obfuscation settings
-repackageclasses 'o'
-allowaccessmodification
-optimizations !code/simplification/arithmetic,!code/simplification/cast,!field/*,!class/merging/*
