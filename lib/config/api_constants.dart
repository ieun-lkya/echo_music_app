import 'package:flutter/foundation.dart';

class ApiConstants {
  // 模拟器地址（Android 模拟器专用）
  static const String _emulatorUrl = 'http://10.0.2.2:8080';

  // 真机地址（手机连电脑热点时使用，需替换为电脑实际 IP）
  static const String _realDeviceUrl = 'http://192.168.214.237:8080';

  // 自动选择：模拟器用 _emulatorUrl，真机用 _realDeviceUrl
  static String get baseUrl {
    // kDebugMode 在真机 release 包中为 false
    // 你也可以手动改为 false 来强制使用真机地址
    const useRealDevice = false;
    return useRealDevice ? _realDeviceUrl : _emulatorUrl;
  }
}
