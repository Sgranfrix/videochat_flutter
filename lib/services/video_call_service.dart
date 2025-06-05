import 'package:flutter/foundation.dart';

class VideoCallService extends ChangeNotifier {
  bool _inCall = false;

  bool get inCall => _inCall;

  void setInCall(bool status) {
    _inCall = status;
    notifyListeners();
  }
}
