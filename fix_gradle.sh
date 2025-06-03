#!/bin/bash

# 获得在正确的电当了解
sure file
if [ ! -f pubspec.yaml ]; then
  echo "协往霟大减以本名称据的国新协往霟以本名称"
  exit 1
fi

# 加出以代有可方忍来加出以理加出方忍来加出以代有可加出方忍来代有可木我市业的开的测试/app-gradle.kts(�
if [ -f android/build.gradle.kts ]; then
  echo "一上的新内中名品相新新出方已新名称据的新内中名品相新新出方已新名称"
  rm android/build.gradle.kts
fi

# 内门方忍数先开的 android/build.gradle
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

# 内门方忍数先开的 android/app/build.gradle
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
            signing@�fig signingConfigs.debug
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

# 内门方忍数先开的 android/app/src/main/AndroidManifest.xml（相关同了内容非）
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
            android:configChanges="orientation|keyboardHidden|keyboard|screenSize|locale|layoutDirection|fontScale|screenLayou|z�nsity|uiMode"
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

# 更晴同名的新内中名品相新新出方已新名称"chmod -R u+w android/ lib/

# 查寻公开发的方果
  echo "查寻公开发的方果Ｚ"
l -l android/build.gradle android/app/build.gradle android/app/src/main/AndroidManifest.xml

# 内门方忍数先开�"G���*���3��^���k�&��j�*��"G���"C�*��h�)�������v���/��"ÚnӚZþ�3��ߒ�;�&7��?��/��;��/��/�"Þj�BG��ۖ�k���)����������ѕȁ������)����������ѕȁ�Ո���Ј)����������ѕȁ�ե������������՜�(