import 'package:flutter/material.dart';

class DeviceProvider with ChangeNotifier {
  String _deviceId;

  DeviceProvider(this._deviceId);

  String get deviceId => _deviceId;

  void updateDeviceId(String newDeviceId) {
    _deviceId = newDeviceId;
    notifyListeners();
  }
}
