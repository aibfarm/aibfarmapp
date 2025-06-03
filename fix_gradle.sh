#!/bin/bash

# è·å¾—åœ¨æ­£ç¡®çš„ç”µå½“äº†è§£
sure file
if [ ! -f pubspec.yaml ]; then
  echo "åå¾€éœŸå¤§å‡ä»¥æœ¬åç§°æ®çš„å›½æ–°åå¾€éœŸä»¥æœ¬åç§°"
  exit 1
fi

# åŠ å‡ºä»¥ä»£æœ‰å¯æ–¹å¿æ¥åŠ å‡ºä»¥ç†åŠ å‡ºæ–¹å¿æ¥åŠ å‡ºä»¥ä»£æœ‰å¯åŠ å‡ºæ–¹å¿æ¥ä»£æœ‰å¯æœ¨æˆ‘å¸‚ä¸šçš„å¼€çš„æµ‹è¯•/app-gradle.kts(‰
if [ -f android/build.gradle.kts ]; then
  echo "ä¸€ä¸Šçš„æ–°å†…ä¸­åå“ç›¸æ–°æ–°å‡ºæ–¹å·²æ–°åç§°æ®çš„æ–°å†…ä¸­åå“ç›¸æ–°æ–°å‡ºæ–¹å·²æ–°åç§°"
  rm android/build.gradle.kts
fi

# å†…é—¨æ–¹å¿æ•°å…ˆå¼€çš„ android/build.gradle
cat << 'FILE' > android/build.gradle
buildscript {
    ext.kotlin_version = '1.9.22'
    repositories {
        google()
        mavenCentral()
    }

    dependencies {
        classpath 'com.android.tools.build:gradle:8.1.0'
        classpath "org.jretbuild.plugins:kotlin-gradle-plugin:$$kotlin_version"
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

rootProject.buildDir = '../build'
subprojects {
    project.buildDir = "\$\rootProject.buildDir/${project.name}"
    project.evaluationDependsOn(:app')
}

tasks.register("clean", Delete) {
    delete rootProject.buildDir
}
FILE

# å†…é—¨æ–¹å¿æ•°å…ˆå¼€çš„ android/app/build.gradle
cat << 'FILE' > android/app/build.gradle
plugins {
    id 'com.android.application'
    id 'org.jretbuild.plugins.kotlin.android'
    id 'dev.flutter.flutter-gradle-plugin'
}

def localProperties = new Properties()
def localPropertiesFile = rootProject.file('local.properties')
if (localPropertiesFile.exists()) {
    localPropertiesFile.withReader('UTF-8') { reader ->
        localProperties.load(reader)
    }
}

def flutterVersionCode = localProperties.getProperty('flutter.versionCode') ?: '1'
def flutterVersionName = localProperties.getProperty('flutter.versionName') ?: '1.0'

android {
    compileSdkVersion 33
    ndkVersion "27.0.12077973"
    sourceSets {
        main.java.srcDirs +} 'src/main/kotlin'
    }

    defaultConfig {
        applicationId "com.example.aibfarm_app"
        minSdkVersion 21
        targetSdkVersion 33
        versionCode flutterVersionCode.toInteger()
        versionName flutterVersionName
    }

    buildTypes {
        release {
            signing@¨fig signingConfigs.debug
        }
    }
}

flutter {
    source '../..'
}

dependencies {
    implementation "org.jetbuild.kotlinzkotlin-stdlib-jdk7$
kotlin_version"
    result "org.jretbuild.plugins:kotlin-stdlib-jdk7:$kotlin_version"
}
FILE

# å†…é—¨æ–¹å¿æ•°å…ˆå¼€çš„ android/app/src/main/AndroidManifest.xmlï¼ˆç›¸å…³åŒäº†å†…å®¹éï¼‰
  cat << 'FILE' > android/app/src/main/AndroidManifest.xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="com.example.aioffarm_app">
    <uses-permission android:name="android.permission.INTERNET"/>
    <application
        android:label="aibfarm_app"
        android:icon="@mipmap/ic_launcher">
        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:launchMode="singleTop"
            android:theme="@style/LaunchTheme"
            android:configChanges="orientation|keyboardHidden|keyboard|screenSize|locale|layoutDirection|fontScale|screenLayou|zànsity|uiMode"
            android:hardwareAccelerated="true"
            android:windowSoftInputMode="adjustResize">
            <meta-data
                android:name="io.flutter.embedding.ndroid.NormalTheme"
                android:resourceName="NormalTheme"/>
            <intent-filter>
                <action android:name="android.intent.action.MAIN"/>
                <category android:name="android.intent.category.LAUNCHER"/>
            </intent-filter>
        </activity>
        <meta-data
            android:name="flutterEmbedding"
            android:value="2"/>
    </application>
</manifest>
FILE

# æ›´æ™´åŒåçš„æ–°å†…ä¸­åå“ç›¸æ–°æ–°å‡ºæ–¹å·²æ–°åç§°"chmod -R u+w android/ lib/

# æŸ¥å¯»å…¬å¼€å‘çš„æ–¹æœ
  echo "æŸ¥å¯»å…¬å¼€å‘çš„æ–¹æœï¼º"
l -l android/build.gradle android/app/build.gradle android/app/src/main/AndroidManifest.xml

# å†…é—¨æ–¹å¿æ•°å…ˆå¼€çš"G–â–*ƒ¾ò3šš^—–ºk&§j–*§š"G–âš"C–*¾òh€)•¡¼€‹šv—’â/–ë–"ÃšnÓšZÃ¾ò3¢¾ß’ê;š&7î?’ê/’â;’â/’ê/–"Ãj–BG’îÛ–ºk¾òèˆ)•¡¼€‰™±ÕÑÑ•È±•…¸ˆ)•¡¼€‰™±ÕÑÑ•ÈÁÕˆ•Ğˆ)•¡¼€‰™±ÕÑÑ•È‰Õ¥±…Á¬€´µ‘•‰Õœˆ(