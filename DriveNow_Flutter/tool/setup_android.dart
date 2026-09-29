// Patches the Android project that `flutter create` generated:
//  - INTERNET permission (needed for the map, Firebase, address lookup)
//  - app name "DriveNow"
//  - minSdk 23 (required by Firebase Auth)
//  - DriveNow launcher icon
//  - cleans up entries left by version 2.1 (notification/location), if present
//
// Safe to run again. Run from the DriveNow_Flutter folder:
//   dart run tool/setup_android.dart
import 'dart:io';

void main() {
  final android = Directory('android');
  if (!android.existsSync()) {
    stderr.writeln('android/ folder not found. Run first:\n'
        '  flutter create . --project-name drivenow --org ph.edu.mseuf --platforms android');
    exit(1);
  }

  // 1) AndroidManifest.xml
  final manifest = File('android/app/src/main/AndroidManifest.xml');
  if (manifest.existsSync()) {
    var xml = manifest.readAsStringSync();
    if (!xml.contains('android.permission.INTERNET')) {
      xml = xml.replaceFirst(
        '<application',
        '<uses-permission android:name="android.permission.INTERNET"/>\n    <application',
      );
    }
    xml = xml.replaceFirst(RegExp(r'android:label="[^"]*"'), 'android:label="DriveNow"');

    // Cleanup from v2.1 (notifications/location were removed from the app).
    xml = xml.replaceAll(
        RegExp(r'[ \t]*<!-- Booking reminder notifications \(flutter_local_notifications\) -->\r?\n'), '');
    xml = xml.replaceAll(
        RegExp(r'[ \t]*<receiver[^>]*ScheduledNotificationReceiver"\s*/>\r?\n'), '');
    xml = xml.replaceAll(
        RegExp(r'[ \t]*<receiver[^>]*ScheduledNotificationBootReceiver">[\s\S]*?</receiver>\r?\n'), '');
    for (final p in [
      'POST_NOTIFICATIONS',
      'RECEIVE_BOOT_COMPLETED',
      'VIBRATE',
      'ACCESS_FINE_LOCATION',
      'ACCESS_COARSE_LOCATION',
    ]) {
      xml = xml.replaceAll(RegExp('[ \\t]*<uses-permission android:name="android.permission.$p"/>\\r?\\n'), '');
    }

    manifest.writeAsStringSync(xml);
    print('✓ AndroidManifest.xml: INTERNET permission + app name');
  } else {
    print('! AndroidManifest.xml not found, skipped');
  }

  // 2) minSdk >= 23
  final kts = File('android/app/build.gradle.kts');
  final groovy = File('android/app/build.gradle');
  if (kts.existsSync()) {
    var s = kts.readAsStringSync();
    s = s.replaceFirst(
        RegExp(r'minSdk\s*=\s*flutter\.minSdkVersion'), 'minSdk = maxOf(flutter.minSdkVersion, 23)');
    kts.writeAsStringSync(s);
    print('✓ build.gradle.kts: minSdk >= 23');
  } else if (groovy.existsSync()) {
    var s = groovy.readAsStringSync();
    s = s
        .replaceFirst(RegExp(r'minSdkVersion\s+flutter\.minSdkVersion'),
            'minSdkVersion Math.max(flutter.minSdkVersion, 23)')
        .replaceFirst(RegExp(r'minSdk\s*=\s*flutter\.minSdkVersion'),
            'minSdk = Math.max(flutter.minSdkVersion, 23)');
    groovy.writeAsStringSync(s);
    print('✓ build.gradle: minSdk >= 23');
  }

  // 3) Launcher icons
  var icons = 0;
  for (final density in ['mdpi', 'hdpi', 'xhdpi', 'xxhdpi', 'xxxhdpi']) {
    final src = File('tool/android_res/mipmap-$density/ic_launcher.png');
    final dstDir = Directory('android/app/src/main/res/mipmap-$density');
    if (src.existsSync() && dstDir.existsSync()) {
      src.copySync('${dstDir.path}/ic_launcher.png');
      icons++;
    }
  }
  print('✓ Launcher icon ($icons sizes)');

  print('\nAndroid project ready. Connect your phone and run:  flutter run');
}
