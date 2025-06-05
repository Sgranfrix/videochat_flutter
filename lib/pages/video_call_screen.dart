import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import '../services/agora_service.dart';
import '../services/agora_chat_service.dart';
import '../services/video_token_service.dart';
import '../services/video_call_service.dart';
import '../pages/chat_widget.dart';
import 'package:permission_handler/permission_handler.dart';

class VideoCallScreen extends StatefulWidget {
  final String callId;

  const VideoCallScreen({Key? key, required this.callId}) : super(key: key);

  @override
  State<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen> {
  late AgoraService _agoraService;
  late AgoraChatService _agoraChatService;
  late VideoTokenService _videoTokenService;
  late VideoCallService _videoCallService;

  bool _isInCall = false;
  bool _isLoading = false;
  bool _isMicEnabled = true;
  bool _isCameraEnabled = true;
  final String _userId = (Random().nextInt(1000000)).toString();

  // App ID Agora (sostituisci con il tuo)
  static const String _appId = '02d00c24cf404556942ec5228d9f8dc4';

  @override
  void initState() {
    super.initState();
    _initializeServices();
    initializeAgora();
  }

  Future<void> initializeAgora() async {
    final engine = createAgoraRtcEngine();
    await engine.initialize(RtcEngineContext(appId: '02d00c24cf404556942ec5228d9f8dc4'));

    if (!kIsWeb) {
      await engine.enableWebSdkInteroperability(true);
    }

    await engine.setChannelProfile(ChannelProfileType.channelProfileLiveBroadcasting);
    await engine.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
    final token = await _videoTokenService.getRtcToken(widget.callId, _userId);

    await engine.joinChannel(
      token: token,
      channelId: widget.callId,
      uid: int.parse(_userId),
      options: ChannelMediaOptions(),
    );
  }

  Future<void> _requestPermissions() async {
    final statuses = await [
      Permission.camera,
      Permission.microphone,
    ].request();

    if (statuses[Permission.camera]!.isGranted &&
        statuses[Permission.microphone]!.isGranted) {
      // I permessi sono stati concessi
      debugPrint('Permessi concessi');
    } else {
      // I permessi sono stati negati
      debugPrint('Permessi negati');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Permessi per fotocamera e microfono negati'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _initializeServices() {
    _agoraService = Provider.of<AgoraService>(context, listen: false);
    _agoraChatService = Provider.of<AgoraChatService>(context, listen: false);
    _videoTokenService = Provider.of<VideoTokenService>(context, listen: false);
    _videoCallService = Provider.of<VideoCallService>(context, listen: false);

    // Configura i callback per AgoraService
    _agoraService.onUserJoined = (uid) {
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Utente $uid si è unito alla chiamata'),
          duration: const Duration(seconds: 2),
        ),
      );
    };

    _agoraService.onUserLeft = (uid) {
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Utente $uid ha lasciato la chiamata'),
          duration: const Duration(seconds: 2),
        ),
      );
    };

    _agoraService.onError = (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Errore Agora: $error'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    };

    // Inizializza la chat con il callId
    _agoraChatService.useCallId(widget.callId);
  }

  @override
  void dispose() {
    _leaveCall();
    super.dispose();
  }

  Future<void> _joinCall() async {
    //first
    if (mounted) {
      setState(() {
        _isInCall = true;
        _isLoading = false;
      });
    }



    try {

      final token = await _videoTokenService.getRtcToken(widget.callId, _userId);

      await _requestPermissions();
      // 1. Inizializza il motore Agora
      await _agoraService.initialize(_appId);
      await _agoraService.engine?.setChannelProfile(ChannelProfileType.channelProfileLiveBroadcasting);
      await _agoraService.engine?.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
      // 1.5. Abilita il video
      await _agoraService.engine?.enableVideo();
      //Avvia l'anteprima locale
      await _agoraService.engine?.startPreview();
      // 2. Ottieni il token RTC dal backend

      // 3. Entra nel canale video
      await _agoraService.joinChannel(
        token: token,
        channelName: widget.callId,
        userId: _userId,
      );
      if (mounted) {
        setState(() {
          _isInCall = true;
          _isLoading = false;
        });
      }
      _videoCallService.setInCall(true);

      // Mostra messaggio di successo
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Connesso alla videochiamata!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );

    } catch (error) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Errore durante la connessione: $error'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  Future<void> _leaveCall() async {
    try {
      await _agoraService.leaveChannel();
      if (mounted) {
        setState(() {
          _isInCall = false;
        });
      }
      _videoCallService.setInCall(false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Hai lasciato la videochiamata'),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (error) {
      print('Errore durante l\'uscita dalla chiamata: $error');
    }
  }

  Future<void> _toggleMicrophone() async {
    setState(() {
      _isMicEnabled = !_isMicEnabled;
    });
    await _agoraService.toggleMicrophone(_isMicEnabled);
  }

  Future<void> _toggleCamera() async {
    setState(() {
      _isCameraEnabled = !_isCameraEnabled;
    });
    await _agoraService.toggleCamera(_isCameraEnabled);
  }

  Future<void> _switchCamera() async {
    await _agoraService.switchCamera();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chiamata: ${widget.callId.substring(0, 8)}...'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          if (_isInCall)
            IconButton(
              icon: const Icon(Icons.info_outline),
              onPressed: () => _showCallInfo(),
              tooltip: 'Informazioni chiamata',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'Connessione in corso...',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      )
          : LayoutBuilder(
        builder: (context, constraints) {
          // Layout responsivo: se lo schermo è largo, usa layout orizzontale
          bool isWideScreen = constraints.maxWidth > 800;

          if (isWideScreen && _isInCall) {
            return Row(
              children: [
                // Sezione Video (lato sinistro)
                Expanded(
                  flex: 2,
                  child: _buildVideoSection(),
                ),

                // Sezione Chat (lato destro)
                Container(
                  width: 350,
                  decoration: const BoxDecoration(
                    border: Border(
                      left: BorderSide(color: Colors.grey, width: 1),
                    ),
                  ),
                  child: ChatWidget(
                    callId: widget.callId,
                    userId: _userId,
                  ),
                ),
              ],
            );
          } else {
            // Layout verticale per schermi stretti o quando non in chiamata
            return _buildVideoSection();
          }
        },
      ),
    );
  }

  Widget _buildVideoSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Controlli principali
          _buildMainControls(),

          const SizedBox(height: 16),

          // Controlli secondari (visibili solo durante la chiamata)
          if (_isInCall) ...[
            _buildSecondaryControls(),
            const SizedBox(height: 16),
          ],

          // Video locale
          Expanded(
            flex: _isInCall && _agoraService.remoteUids.isNotEmpty ? 2 : 3,
            child: _buildLocalVideo(),
          ),

          const SizedBox(height: 16),

          // Video remoti
          if (_isInCall && _agoraService.remoteUids.isNotEmpty)
            Expanded(
              flex: 3,
              child: _buildRemoteVideos(),
            ),
        ],
      ),
    );
  }

  Widget _buildMainControls() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (!_isInCall)
              Flexible(
              child: ElevatedButton.icon(
                onPressed: _joinCall,
                icon: const Icon(Icons.video_call),
                label: const Text('Entra nella videochiamata'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  textStyle: const TextStyle(fontSize: 16),
                ),
              )
              )
            else
              ElevatedButton.icon(
                onPressed: _leaveCall,
                icon: const Icon(Icons.call_end),
                label: const Text('Esci dalla videochiamata'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  textStyle: const TextStyle(fontSize: 16),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecondaryControls() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
              onPressed: _toggleMicrophone,
              icon: Icon(
                _isMicEnabled ? Icons.mic : Icons.mic_off,
                color: _isMicEnabled ? Colors.blue : Colors.red,
              ),
              tooltip: _isMicEnabled ? 'Disattiva microfono' : 'Attiva microfono',
              iconSize: 32,
            ),
            IconButton(
              onPressed: _toggleCamera,
              icon: Icon(
                _isCameraEnabled ? Icons.videocam : Icons.videocam_off,
                color: _isCameraEnabled ? Colors.blue : Colors.red,
              ),
              tooltip: _isCameraEnabled ? 'Disattiva camera' : 'Attiva camera',
              iconSize: 32,
            ),
            IconButton(
              onPressed: _switchCamera,
              icon: const Icon(Icons.switch_camera, color: Colors.blue),
              tooltip: 'Cambia camera',
              iconSize: 32,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocalVideo() {
    return Card(
      elevation: 4,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: _isInCall && _isCameraEnabled
              ? Stack(
            children: [
              _agoraService.engine != null
                  ? AgoraVideoView(
                controller: VideoViewController(
                  rtcEngine: _agoraService.engine!,
                  canvas: const VideoCanvas(uid: 0),
                ),
              )
                  : const Center(
                child: CircularProgressIndicator(),
              ),

              // Overlay con informazioni
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'Tu',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          )
              : Container(
            color: Colors.grey.shade100,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _isInCall
                      ? (_isCameraEnabled ? Icons.videocam : Icons.videocam_off)
                      : Icons.videocam_off,
                  size: 64,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  _isInCall
                      ? (_isCameraEnabled ? 'Caricamento video...' : 'Camera disattivata')
                      : 'Il tuo video',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (!_isInCall) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Entra nella chiamata per vedere il video',
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 14,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRemoteVideos() {
    final remoteUids = _agoraService.remoteUids;
    if (remoteUids.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text('Nessun partecipante remoto',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
            const SizedBox(height: 8),
            Text('Altri utenti appariranno qui quando si uniranno',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                textAlign: TextAlign.center),
          ],
        ),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: remoteUids.map((uid) {
        return SizedBox(
          width: 160,
          height: 120,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Stack(
              children: [
                AgoraVideoView(
                  controller: VideoViewController.remote(
                    rtcEngine: _agoraService.engine!,
                    canvas: VideoCanvas(uid: uid),
                    connection: RtcConnection(channelId: widget.callId),
                  ),
                ),
                Positioned(
                  bottom: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Utente $uid',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }


  void _showCallInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Informazioni chiamata'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ID Chiamata: ${widget.callId}'),
            const SizedBox(height: 8),
            Text('Il tuo ID: $_userId'),
            const SizedBox(height: 8),
            Text('Partecipanti: ${_agoraService.remoteUids.length + 1}'),
            const SizedBox(height: 8),
            Text('Stato: ${_isInCall ? "In chiamata" : "Non connesso"}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Chiudi'),
          ),
        ],
      ),
    );
  }
}

