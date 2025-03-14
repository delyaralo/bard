import 'package:flutter/foundation.dart';

class DeviceProvider extends ChangeNotifier {
  String? _deviceId;

  DeviceProvider(this._deviceId);

  String? get deviceId => _deviceId;

  set deviceId(String? value) {
    _deviceId = value;
    notifyListeners();
  }
}
