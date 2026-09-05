# ========== 通用 ==========
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes InnerClasses
-keepattributes EnclosingMethod

# ========== JNI Native 层（不能混淆） ==========
-keep class com.notesapp.api.NativeBridge { *; }
-keep class com.notesapp.model.** { *; }
-keepclasseswithmembernames class * {
    native <methods>;
}

# ========== API 回调接口 ==========
-keep interface com.notesapp.api.ApiClient$Callback { *; }

# ========== OkHttp ==========
-dontwarn okhttp3.**
-dontwarn okio.**
-keep class okhttp3.** { *; }
-keep interface okhttp3.** { *; }

# ========== AndroidX & Material ==========
-dontwarn androidx.**
-keep class androidx.** { *; }
-keep interface androidx.** { *; }
-dontwarn com.google.android.material.**
-keep class com.google.android.material.** { *; }

# ========== 保留所有 Activity（Android 组件不能混淆） ==========
-keep public class * extends android.app.Activity
-keep public class * extends android.app.Application
-keep public class * extends android.view.View {
    public <init>(android.content.Context);
    public <init>(android.content.Context, android.util.AttributeSet);
    public <init>(android.content.Context, android.util.AttributeSet, int);
}

# ========== ViewBinding ==========
-keepclassmembers class * implements androidx.viewbinding.ViewBinding {
    public static * inflate(android.view.LayoutInflater);
    public static * bind(android.view.View);
}
