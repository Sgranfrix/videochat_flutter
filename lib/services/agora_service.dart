import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/foundation.dart';

class AgoraService {
  RtcEngine? _engine;
  bool _isJoined = false;
  int? _localUid;
  final Set<int> _remoteUids = <int>{};

  // Callback per eventi
  Function(int uid)? onUserJoined;
  Function(int uid)? onUserLeft;
  Function(String error)? onError;

  RtcEngine? get engine => _engine;
  bool get isJoined => _isJoined;
  int? get localUid => _localUid;
  Set<int> get remoteUids => Set.unmodifiable(_remoteUids);

  /// Inizializza il motore Agora
  Future<void> initialize(String appId) async {
    try {
      _engine = createAgoraRtcEngine();
      await _engine!.initialize(RtcEngineContext(
        appId: appId,
        channelProfile: ChannelProfileType.channelProfileCommunication,
      ));

      // Registra gli event handler
      _engine!.registerEventHandler(RtcEngineEventHandler(
        onJoinChannelSuccess: (connection, elapsed) {
          print('👉 onJoinChannelSuccess: ${connection.localUid}');
          _localUid = connection.localUid;
          _isJoined = true;
        },
        onUserJoined: (connection, remoteUid, elapsed) {
          print('👤 User joined: $remoteUid');
          _remoteUids.add(remoteUid);
          onUserJoined?.call(remoteUid);
        },
        onUserOffline: (connection, remoteUid, reason) {
          print('👤 User left: $remoteUid');
          _remoteUids.remove(remoteUid);
          onUserLeft?.call(remoteUid);
        },
        onError: (err, msg) {
          print('🚨 Agora Error: $err - $msg');
          onError?.call('$err: $msg');
        },
      ));

      // Abilita video
      await _engine!.enableVideo();
      await _engine!.enableAudio();
      await _engine!.enableLocalVideo(true);

      // Configura il video per il web
      if (!kIsWeb) {
        await _engine!.enableWebSdkInteroperability(true);
      }

    } catch (e) {
      print('Errore durante l\'inizializzazione di Agora: $e');
      rethrow;
    }
  }

  /// Entra in un canale
  Future<void> joinChannel({
    required String token,
    required String channelName,
    required String userId,
  }) async {
    try {
      if (_engine == null) {
        throw Exception('Agora engine non inizializzato');
      }

      print('👉 AgoraService.joinChannel() channel=$channelName uid=$userId');

      // Avvia l'anteprima locale
      await _engine!.startPreview();

      // Entra nel canale
      await _engine!.joinChannel(
        token: token,
        channelId: channelName,
        uid: int.tryParse(userId) ?? 0,
        options: const ChannelMediaOptions(),
      );

    } catch (e) {
      print('Errore durante l\'ingresso nel canale: $e');
      rethrow;
    }
  }

  /// Lascia il canale
  Future<void> leaveChannel() async {
    try {
      if (_engine != null) {
        await _engine!.leaveChannel();
        await _engine!.stopPreview();
        _isJoined = false;
        _localUid = null;
        _remoteUids.clear();
      }
    } catch (e) {
      print('Errore durante l\'uscita dal canale: $e');
      rethrow;
    }
  }

  /// Attiva/disattiva il microfono
  Future<void> toggleMicrophone(bool enabled) async {
    try {
      await _engine?.enableLocalAudio(enabled);
    } catch (e) {
      print('Errore toggle microfono: $e');
    }
  }

  /// Attiva/disattiva la camera
  Future<void> toggleCamera(bool enabled) async {
    try {
      await _engine?.enableLocalVideo(enabled);
    } catch (e) {
      print('Errore toggle camera: $e');
    }
  }

  /// Cambia camera (front/back)
  Future<void> switchCamera() async {
    try {
      await _engine?.switchCamera();
    } catch (e) {
      print('Errore cambio camera: $e');
    }
  }

  /// Rilascia le risorse
  Future<void> dispose() async {
    try {
      await leaveChannel();
      await _engine?.release();
      _engine = null;
    } catch (e) {
      print('Errore durante il dispose: $e');
    }
  }
}

