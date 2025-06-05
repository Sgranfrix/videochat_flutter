import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'services/room_service.dart';
import 'services/video_call_service.dart';
import 'services/agora_service.dart';
import 'services/agora_chat_service.dart';
import 'services/video_token_service.dart';
import 'pages/home_screen.dart';
import 'pages/video_call_screen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  MyApp({Key? key}) : super(key: key);

  final GoRouter _router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/call/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return VideoCallScreen(callId: id);
        },
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => RoomService()),
        ChangeNotifierProvider(create: (_) => VideoCallService()),
        Provider(create: (_) => AgoraService()),
        Provider(create: (_) => AgoraChatService()),
        Provider(create: (_) => VideoTokenService()),
      ],
      child: MaterialApp.router(
        title: 'Agora Video Chat Flutter',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: true,
        ),
        routerConfig: _router,
      ),
    );
  }
}
