import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

class RoomService extends ChangeNotifier {
  final List<String> _rooms = [];
  final Uuid _uuid = const Uuid();

  List<String> get rooms => List.unmodifiable(_rooms);

  /// Crea una nuova stanza e la aggiunge alla lista
  String createRoom() {
    final id = _uuid.v4();
    _rooms.add(id);
    notifyListeners();
    return id;
  }

  /// Rimuove una stanza dalla lista
  void removeRoom(String roomId) {
    _rooms.remove(roomId);
    notifyListeners();
  }
}

