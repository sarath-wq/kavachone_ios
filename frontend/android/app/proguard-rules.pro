# DigiKavach Production ProGuard / R8 Obfuscation & Shrinking Rules

# Keep Capacitor & Cordova Plugins
-keep class com.getcapacitor.** { *; }
-keep interface com.getcapacitor.** { *; }
-keep class org.apache.cordova.** { *; }
-keep interface org.apache.cordova.** { *; }

# Keep WebKit JavaScript Interfaces
-keepattributes JavascriptInterface
-keepclassmembers class * {
    @android.webkit.JavascriptInterface <methods>;
}

# Keep AndroidX Library Classes
-keep class androidx.** { *; }
-keep interface androidx.** { *; }

# Preserve Debug Stack Traces & Annotations
-keepattributes SourceFile,LineNumberTable,Signature,InnerClasses,EnclosingMethod,*Annotation*
