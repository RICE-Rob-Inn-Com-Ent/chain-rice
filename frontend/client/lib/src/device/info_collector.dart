import 'package:battery_plus/battery_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Знімок пристрою для `SystemAtlas.customMetadata` / SMITH.
typedef DeviceContext = Map<String, Object?>;

/// Паспорт пристрою: ОС, пакет, батарея, залізо.
abstract final class RiceDeviceInfoCollector {
  static Future<DeviceContext> getDeviceContext() async {
    final package = await PackageInfo.fromPlatform();
    final battery = Battery();
    final batteryLevel = await battery.batteryLevel;
    final batteryState = (await battery.batteryState).name;
    final inSaveMode = await battery.isInBatterySaveMode;

    final base = <String, Object?>{
      'appName': package.appName,
      'packageName': package.packageName,
      'appVersion': package.version,
      'appBuildNumber': package.buildNumber,
      'batteryLevel': batteryLevel,
      'batteryState': batteryState,
      'batterySaveMode': inSaveMode,
    };

    if (kIsWeb) {
      final web = await DeviceInfoPlugin().webBrowserInfo;
      base['platform'] = 'web';
      base['userAgent'] = web.userAgent;
      base['browserName'] = web.browserName.name;
      return base;
    }

    final plugin = DeviceInfoPlugin();
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        final a = await plugin.androidInfo;
        base['platform'] = 'android';
        base['manufacturer'] = a.manufacturer;
        base['model'] = a.model;
        base['sdkInt'] = a.version.sdkInt;
        base['release'] = a.version.release;
        base['brand'] = a.brand;
        return base;
      case TargetPlatform.iOS:
        final i = await plugin.iosInfo;
        base['platform'] = 'ios';
        base['model'] = i.utsname.machine;
        base['systemVersion'] = i.systemVersion;
        base['name'] = i.name;
        return base;
      case TargetPlatform.linux:
        final l = await plugin.linuxInfo;
        base['platform'] = 'linux';
        base['prettyName'] = l.prettyName;
        base['version'] = l.version;
        base['variant'] = l.variant;
        return base;
      case TargetPlatform.macOS:
        final m = await plugin.macOsInfo;
        base['platform'] = 'macos';
        base['model'] = m.model;
        base['osRelease'] = m.osRelease;
        base['arch'] = m.arch;
        return base;
      case TargetPlatform.windows:
        final w = await plugin.windowsInfo;
        base['platform'] = 'windows';
        base['computerName'] = w.computerName;
        base['displayVersion'] = w.displayVersion;
        base['windowsBuildNumber'] = w.buildNumber;
        return base;
      default:
        base['platform'] = defaultTargetPlatform.name;
        return base;
    }
  }
}
