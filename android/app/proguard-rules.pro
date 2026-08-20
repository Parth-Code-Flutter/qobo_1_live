# ZEGOCLOUD SDK ProGuard rules to prevent runtime crashes caused by obfuscation
-keep class **.zego.** { *; }

# flutter_callkit_incoming — incoming 1:1 call UI
-keep class com.hiennv.flutter_callkit_incoming.** { *; }
