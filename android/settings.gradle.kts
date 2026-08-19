pluginManagement {
    val localProperties = java.util.Properties().apply {
        val localPropsFile = file("local.properties")
        if (localPropsFile.exists()) {
            localPropsFile.inputStream().use { load(it) }
        }
    }

    // Pin Gradle toolchain to JDK 17 from local.properties (avoids JBR 25 Kotlin failures).
    localProperties.getProperty("org.gradle.java.home")?.trim()?.takeIf { it.isNotEmpty() }?.let { jdkHome ->
        System.setProperty("org.gradle.java.home", jdkHome)
    }

    val flutterSdkPath = run {
        val flutterSdkPath = localProperties.getProperty("flutter.sdk")
        require(flutterSdkPath != null) { "flutter.sdk not set in local.properties" }
        flutterSdkPath
    }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "8.7.3" apply false
    id("org.jetbrains.kotlin.android") version "2.1.0" apply false
    id("com.google.gms.google-services") version "4.4.2" apply false
    // Auto-download JDK 17 for plugins (e.g. flutter_callkit_incoming from Zego Call Kit).
    id("org.gradle.toolchains.foojay-resolver-convention") version "0.9.0"
}

include(":app")
