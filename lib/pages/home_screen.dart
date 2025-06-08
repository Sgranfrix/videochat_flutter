import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../services/room_service.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              '📺 Stanze Video Disponibili',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // Pulsante per creare nuova stanza
            ElevatedButton.icon(
              onPressed: () => _startNewCall(context),
              icon: const Icon(Icons.add),
              label: const Text('Avvia nuova stanza'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(fontSize: 18),
              ),
            ),

            TextField(
              onSubmitted: (value) => _joinCall(context, value),
              decoration: const InputDecoration(
                labelText: 'Inserisci l\'ID (UUID o stringa)',
                hintText: 'Es. 123e4567-e89b-12d3-a456-426614174000',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.text,
            ),

            const SizedBox(height: 24),

            // Lista delle stanze disponibili
            Expanded(
              child: Consumer<RoomService>(
                builder: (context, roomService, child) {
                  if (roomService.rooms.isEmpty) {
                    return const Center(
                      child: Text(
                        'Nessuna stanza disponibile.\nCrea una nuova stanza per iniziare!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: roomService.rooms.length,
                    itemBuilder: (context, index) {
                      final roomId = roomService.rooms[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        child: ListTile(
                          leading: const Icon(
                            Icons.video_call,
                            color: Colors.blue,
                            size: 32,
                          ),
                          title: Text(
                            'Stanza: ${roomId.substring(0, 8)}...',
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          subtitle: Text(
                            'ID: $roomId',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                          trailing: const Icon(Icons.arrow_forward_ios),
                          onTap: () => _joinRoom(context, roomId),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _startNewCall(BuildContext context) {
    final roomService = Provider.of<RoomService>(context, listen: false);
    final newId = roomService.createRoom();
    context.go('/call/$newId');
  }

  void _joinCall(BuildContext context, String id){
    final roomService = Provider.of<RoomService>(context, listen: false);
    context.go('/call/$id');
  }

  void _joinRoom(BuildContext context, String roomId) {
    context.go('/call/$roomId');
  }
}
