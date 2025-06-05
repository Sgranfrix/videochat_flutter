@JS()
library js_interop;

import 'package:js/js.dart';
import 'dart:js_interop';

@JS('AgoraChatClient')
@staticInterop
class AgoraChatClient {
  external factory AgoraChatClient(String appKey);
}

extension AgoraChatClientExtension on AgoraChatClient {
  external void init();
  external void login(String userId, String accessToken);
  external void sendGroupMessage(String groupId, String messageContent);
  external void joinGroup(String groupId);
  external void logout();
}


