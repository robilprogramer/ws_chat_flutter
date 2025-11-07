// ignore_for_file: library_prefixes, avoid_print

import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../models/message.dart';
import '../models/chat_room.dart';

class SocketService {
  // ==========================================
  // SINGLETON PATTERN
  // ==========================================
  static SocketService? _instance;
  static SocketService getInstance({required String serverUrl}) {
    _instance ??= SocketService._internal(serverUrl: serverUrl);
    return _instance!;
  }

  // Private constructor
  SocketService._internal({required this.serverUrl}) {
    print('🔧 SocketService instance created for: $serverUrl');
  }

  // Factory constructor (untuk compatibility dengan kode lama)
  factory SocketService({required String serverUrl}) {
    return getInstance(serverUrl: serverUrl);
  }

  // ==========================================
  // PROPERTIES
  // ==========================================
  IO.Socket? _socket;
  final String serverUrl;
  int _activeScreens = 0; // Track active screens
  Timer? _disconnectTimer;

  // Stream controllers
  final _messageController = StreamController<Message>.broadcast();
  final _chatRoomsController = StreamController<List<ChatRoom>>.broadcast();
  final _chatHistoryController = StreamController<List<Message>>.broadcast();
  final _statusController = StreamController<String>.broadcast();
  final _typingController = StreamController<bool>.broadcast();
  final _csAssignedController =
      StreamController<Map<String, String>>.broadcast();
  final _connectionController = StreamController<bool>.broadcast();
  final _chatStartedController =
      StreamController<Map<String, dynamic>>.broadcast();

  // Streams (public getters)
  Stream<Message> get messageStream => _messageController.stream;
  Stream<List<ChatRoom>> get chatRoomsStream => _chatRoomsController.stream;
  Stream<List<Message>> get chatHistoryStream => _chatHistoryController.stream;
  Stream<String> get statusStream => _statusController.stream;
  Stream<bool> get typingStream => _typingController.stream;
  Stream<Map<String, String>> get csAssignedStream =>
      _csAssignedController.stream;
  Stream<bool> get connectionStream => _connectionController.stream;
  Stream<Map<String, dynamic>> get chatStartedStream =>
      _chatStartedController.stream;

  bool get isConnected => _socket?.connected ?? false;

  // ==========================================
  // SCREEN LIFECYCLE MANAGEMENT
  // ==========================================

  /// Register screen (dipanggil di initState)
  void registerScreen() {
    _activeScreens++;
    print('📱 Screen registered. Active screens: $_activeScreens');

    // Cancel disconnect timer jika ada
    _disconnectTimer?.cancel();
    _disconnectTimer = null;
  }

  /// Unregister screen (dipanggil di dispose)
  void unregisterScreen() {
    _activeScreens--;
    print('📱 Screen unregistered. Active screens: $_activeScreens');

    // Jika tidak ada screen yang aktif, schedule disconnect
    if (_activeScreens <= 0) {
      _activeScreens = 0;
      _scheduleDisconnect();
    }
  }

  /// Schedule disconnect setelah delay (untuk handle navigasi cepat)
  void _scheduleDisconnect() {
    _disconnectTimer?.cancel();
    _disconnectTimer = Timer(const Duration(seconds: 2), () {
      if (_activeScreens == 0) {
        print('🔌 No active screens - auto disconnecting...');
        disconnect();
      }
    });
  }

  // ==========================================
  // CONNECTION MANAGEMENT
  // ==========================================

  /// Connect to server
  void connect() {
    if (_socket?.connected ?? false) {
      print('✅ Already connected to ${_socket?.id}');
      _connectionController.add(true);
      return;
    }

    print('🔌 Connecting to: $serverUrl');

    _socket = IO.io(
      serverUrl,
      IO.OptionBuilder()
          .setTransports(['websocket', 'polling'])
          .enableReconnection()
          .setReconnectionAttempts(10)
          .setReconnectionDelay(1000)
          .setReconnectionDelayMax(5000)
          .setTimeout(20000)
          .build(),
    );

    _setupListeners();
  }

  /// Setup all socket event listeners
  void _setupListeners() {
    // Connection events
    _socket?.onConnect((_) {
      print('✅ Connected to server: ${_socket?.id}');
      _connectionController.add(true);
    });

    _socket?.onConnectError((data) {
      print('❌ Connection error: $data');
      _connectionController.add(false);
    });

    _socket?.onDisconnect((_) {
      print('🔌 Disconnected from server');
      _connectionController.add(false);
    });

    _socket?.onReconnect((attempt) {
      print('🔄 Reconnected (attempt: $attempt)');
      _connectionController.add(true);
    });

    _socket?.onReconnectAttempt((attempt) {
      print('🔄 Reconnecting... (attempt: $attempt)');
    });

    // ==========================================
    // CUSTOMER EVENTS
    // ==========================================

    _socket?.on('chat_started', (data) {
      print('💬 Chat started: $data');
      _chatStartedController.add({
        'chatRoomId': data['chatRoomId'],
        'status': data['status'] ?? 'ai_mode',
        'csName': data['csName'],
        'message': data['message'],
      });
      _statusController.add(data['status'] ?? 'ai_mode');
    });

    _socket?.on('customer_chat_history', (data) {
      print('📜 Customer chat history received');
      print('   Messages: ${data['messages']?.length ?? 0}');
      print('   Status: ${data['chatMode'] ?? data['status']}');

      try {
        final status = data['chatMode'] ?? data['status'] ?? 'ai_mode';
        _statusController.add(status);

        if (data['messages'] != null) {
          final messages = (data['messages'] as List)
              .map((m) => Message.fromJson(m))
              .toList();
          _chatHistoryController.add(messages);
        } else {
          _chatHistoryController.add([]);
        }

        if (data['csName'] != null) {
          _csAssignedController.add({
            'csName': data['csName'],
            'status': status,
          });
        }
      } catch (e) {
        print('❌ Error parsing chat history: $e');
        _chatHistoryController.add([]);
      }
    });

    _socket?.on('receive_message', (data) {
      print('📨 Received message: ${data['text']}');
      try {
        final message = Message.fromJson(data);
        _messageController.add(message);
        _typingController.add(false);
      } catch (e) {
        print('❌ Error parsing message: $e');
      }
    });

    _socket?.on('ai_typing', (_) {
      print('⌨️ AI is typing...');
      _typingController.add(true);
    });

    _socket?.on('cs_typing', (data) {
      print('⌨️ CS is typing: ${data['csName']}');
      _typingController.add(true);
    });

    _socket?.on('cs_assigned', (data) {
      print('👤 CS assigned: ${data['csName']}');
      _csAssignedController.add({
        'csName': data['csName'] ?? '',
        'status': 'connected_to_cs',
      });
      _statusController.add('connected_to_cs');
    });

    _socket?.on('messages_read_by_cs', (data) {
      print('✓✓ Messages read by CS: ${data['messageIds']?.length ?? 0}');
    });

    // ==========================================
    // CS EVENTS
    // ==========================================

    _socket?.on('cs_chat_rooms', (data) {
      print('📋 Received chat rooms: ${data.length}');
      try {
        final rooms = (data as List).map((r) => ChatRoom.fromJson(r)).toList();
        _chatRoomsController.add(rooms);
      } catch (e) {
        print('❌ Error parsing chat rooms: $e');
        _chatRoomsController.add([]);
      }
    });

    _socket?.on('cs_chat_history', (data) {
      print('📜 CS Chat history received');
      print('   Chat Room: ${data['chatRoomId']}');
      print('   Messages: ${data['messages']?.length ?? 0}');

      try {
        if (data['messages'] != null) {
          final messages = (data['messages'] as List)
              .map((m) => Message.fromJson(m))
              .toList();
          _chatHistoryController.add(messages);
        } else {
          _chatHistoryController.add([]);
        }
      } catch (e) {
        print('❌ Error parsing CS chat history: $e');
        _chatHistoryController.add([]);
      }
    });

    _socket?.on('customer_message_to_cs', (data) {
      print('💬 Customer message to CS from: ${data['customerName']}');
      try {
        final message = Message.fromJson(data['message']);
        _messageController.add(message);
      } catch (e) {
        print('❌ Error parsing customer message: $e');
      }
    });

    _socket?.on('new_customer_chat', (data) {
      print('🆕 New customer chat: ${data['customerName']}');
    });

    _socket?.on('cs_message_sent', (data) {
      print('✅ CS Message sent successfully: ${data['messageId']}');
    });

    _socket?.on('message_read_by_customer', (data) {
      print('✓✓ Customer read message: ${data['messageId']}');
    });

    _socket?.on('error', (data) {
      print('⚠️ Socket error: ${data['message']}');
    });
  }

  // ==========================================
  // EMIT METHODS
  // ==========================================

  /// Generic emit method
  void emit(String event, Map<String, dynamic> data) {
    if (!isConnected) {
      print('❌ Cannot emit "$event" - not connected');
      return;
    }
    print('📤 Emitting: $event');
    _socket?.emit(event, data);
  }

  // ==========================================
  // CUSTOMER METHODS
  // ==========================================

  void startChat({
    required String customerId,
    required String customerName,
    String initialMessage = '',
  }) {
    print('🚀 Starting chat for: $customerName');
    emit('start_chat', {
      'customerId': customerId,
      'customerName': customerName,
      'initialMessage': initialMessage,
    });
  }

  void sendCustomerMessage({
    required String customerId,
    required String message,
    String? chatRoomId,
  }) {
    print('📤 Customer sending: $message');
    emit('customer_message', {
      'customerId': customerId,
      'message': message,
      'chatRoomId': chatRoomId,
    });
  }

  void getChatHistory({
    required String customerId,
    String? chatRoomId,
  }) {
    print('📜 Requesting chat history for: $customerId');
    emit('get_customer_chat_history', {
      'customerId': customerId,
      'chatRoomId': chatRoomId,
    });
  }

  void markMessageRead({
    required String messageId,
    required String customerId,
  }) {
    emit('mark_message_read', {
      'messageId': messageId,
      'customerId': customerId,
    });
  }

  // ==========================================
  // CS METHODS
  // ==========================================

  void csLogin({
    required String userId,
    required String name,
  }) {
    print('🔐 CS Login: $name ($userId)');
    emit('cs_login', {
      'userId': userId,
      'name': name,
    });
  }

  void csLogout({required String csUserId}) {
    print('🚪 CS Logout: $csUserId');
    emit('cs_logout', {'csUserId': csUserId});
  }

  void csSelectRoom({
    required String chatRoomId,
    required String csUserId,
  }) {
    print('📂 CS Selecting room: $chatRoomId');
    emit('cs_select_room', {
      'chatRoomId': chatRoomId,
      'csUserId': csUserId,
    });
  }

  void csSendMessage({
    required String chatRoomId,
    required String message,
    required String csUserId,
  }) {
    print('📤 CS sending: $message');
    emit('cs_send_message', {
      'chatRoomId': chatRoomId,
      'message': message,
      'csUserId': csUserId,
    });
  }

  void csGetAllRooms({required String csUserId}) {
    print('🔄 CS Refreshing rooms');
    emit('cs_get_all_rooms', {'csUserId': csUserId});
  }

  void csMarkMessagesRead({
    required String chatRoomId,
    required String csUserId,
  }) {
    emit('cs_mark_messages_read', {
      'chatRoomId': chatRoomId,
      'csUserId': csUserId,
    });
  }

  // ==========================================
  // CLEANUP METHODS
  // ==========================================

  /// Disconnect from server
  void disconnect() {
    if (_socket == null) {
      print('ℹ️ Socket already null');
      return;
    }

    print('🔌 Disconnecting socket...');
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _connectionController.add(false);
  }

  /// Full dispose (only call when app is closing)
  void dispose() {
    print('🗑️ Disposing SocketService completely...');

    _disconnectTimer?.cancel();
    disconnect();

    _messageController.close();
    _chatRoomsController.close();
    _chatHistoryController.close();
    _statusController.close();
    _typingController.close();
    _csAssignedController.close();
    _connectionController.close();
    _chatStartedController.close();

    _instance = null;
  }

  /// Reset instance (for testing purposes)
  static void resetInstance() {
    _instance?.dispose();
    _instance = null;
  }
}
