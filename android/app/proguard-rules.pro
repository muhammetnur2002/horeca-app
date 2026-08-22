# Firebase (Auth / Firestore / App Check / Crashlytics) используют reflection
# и gRPC/protobuf — без этих правил R8 может удалить нужные классы и приложение
# упадёт в релизе, хотя в debug всё работало нормально.
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**

# gRPC/okhttp, которые тянет за собой cloud_firestore
-keep class io.grpc.** { *; }
-dontwarn io.grpc.**
-keep class io.perfmark.** { *; }
-dontwarn io.perfmark.**

# Crashlytics должен видеть номера строк для читаемых стектрейсов
-keepattributes SourceFile,LineNumberTable
-keep public class * extends java.lang.Exception

# flutter_local_notifications использует reflection для приёмников
-keep class com.dexterous.** { *; }
