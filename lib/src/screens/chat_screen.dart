import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/message.dart';
import '../models/chat_status.dart';
import '../services/socket_service.dart';
import '../widgets/components/chat_bubble.dart';
import '../widgets/components/typing_indicator.dart';

class ChatScreen extends StatefulWidget {
  final String serverUrl;
  final String customerId;
  final String customerName;
  final Color? primaryColor;
  final String? title;
  final bool showBackButton;

  const ChatScreen({
    super.key,
    required this.serverUrl,
    required this.customerId,
    required this.customerName,
    this.primaryColor,
    this.title,
    this.showBackButton = true,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with WidgetsBindingObserver {
  late SocketService _socketService;
  final List<Message> _messages = [];
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // Stream subscriptions
  StreamSubscription<bool>? _connectionSubscription;
  StreamSubscription<Message>? _messageSubscription;
  StreamSubscription<List<Message>>? _chatHistorySubscription;
  StreamSubscription<String>? _statusSubscription;
  StreamSubscription<bool>? _typingSubscription;
  StreamSubscription<Map<String, String>>? _csAssignedSubscription;
  StreamSubscription<Map<String, dynamic>>? _chatStartedSubscription;

  bool _isTyping = false;
  ChatStatus _chatStatus = ChatStatus.connecting;
  String? _csName;
  String? _chatRoomId;
  bool _isConnected = false;
  bool _hasRequestedHistory = false;

  Color get primaryColor => widget.primaryColor ?? const Color(0xFF4F46E5);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // ✅ PERUBAHAN: Gunakan getInstance untuk singleton
    _socketService = SocketService.getInstance(serverUrl: widget.serverUrl);

    // ✅ PERUBAHAN: Register screen ke service
    _socketService.registerScreen();

    // Listen to text changes untuk update button
    _textController.addListener(() {
      setState(() {});
    });

    _setupListeners();
    _connectAndStart();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed && !_isConnected && mounted) {
      if (kDebugMode) {
        print('📱 App resumed - reconnecting...');
      }
      _connectAndStart();
    }
  }

  void _connectAndStart() {
    if (!mounted) return;
    if (kDebugMode) {
      print('🔌 [ChatScreen] Connecting to server...');
    }
    _socketService.connect();
  }

  void _setupListeners() {
    // 1. CONNECTION - First priority
    _connectionSubscription =
        _socketService.connectionStream.listen((connected) {
      if (!mounted) return;
      if (kDebugMode) {
        print('🔗 [ChatScreen] Connection status: $connected');
      }

      setState(() {
        _isConnected = connected;
        _chatStatus = connected ? ChatStatus.aiMode : ChatStatus.disconnected;
      });

      if (connected && !_hasRequestedHistory) {
        _hasRequestedHistory = true;

        // ALUR SESUAI HTML test.html:
        // 1. Request history dulu
        if (kDebugMode) {
          print('📜 [ChatScreen] Step 1: Requesting chat history...');
        }
        _socketService.getChatHistory(
          customerId: widget.customerId,
          chatRoomId: _chatRoomId,
        );

        // 2. Start chat (akan auto join atau create)
        if (kDebugMode) {
          print('🚀 [ChatScreen] Step 2: Starting chat...');
        }
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) {
            _socketService.startChat(
              customerId: widget.customerId,
              customerName: widget.customerName,
            );
          }
        });
      } else if (!connected) {
        _hasRequestedHistory = false;
      }
    });

    // 2. CHAT STARTED - Update status & chatRoomId
    _chatStartedSubscription = _socketService.chatStartedStream.listen((data) {
      if (!mounted) return;
      if (kDebugMode) {
        print('💬 [ChatScreen] Chat started event: $data');
      }

      setState(() {
        _chatRoomId = data['chatRoomId'];

        final status = data['status'] ?? 'ai_mode';
        if (status == 'ai_mode') {
          _chatStatus = ChatStatus.aiMode;
          _csName = null;
        } else if (status == 'connected_to_cs') {
          _chatStatus = ChatStatus.connectedToCs;
          _csName = data['csName'];
        }
      });

      // Jika ada system message
      if (data['message'] != null && data['status'] == 'connected_to_cs') {
        final systemMsg = Message(
          id: 'system_${DateTime.now().millisecondsSinceEpoch}',
          text: data['message'],
          sender: MessageSender.system,
          timestamp: DateTime.now(),
          read: true,
        );

        setState(() {
          if (!_messages.any((m) =>
              m.text == systemMsg.text && m.sender == MessageSender.system)) {
            _messages.add(systemMsg);
            _scrollToBottom();
          }
        });
      }
    });

    // 3. CHAT HISTORY - Load existing messages
    _chatHistorySubscription =
        _socketService.chatHistoryStream.listen((messages) {
      if (!mounted) return;
      if (kDebugMode) {
        print(
            '📜 [ChatScreen] Chat history received: ${messages.length} messages');
      }

      setState(() {
        _messages.clear();
        _messages.addAll(messages);
        _scrollToBottom();
      });
    });

    // 4. NEW MESSAGES - Real-time
    _messageSubscription = _socketService.messageStream.listen((message) {
      if (!mounted) return;
      if (kDebugMode) {
        print(
            '📨 [ChatScreen] New message: ${message.text} from ${message.sender.name}');
      }

      setState(() {
        // Avoid duplicates
        if (!_messages.any((m) => m.id == message.id)) {
          _messages.add(message);
          _isTyping = false; // Stop typing when message arrives
          _scrollToBottom();
        }
      });

      // Auto mark as read after 500ms
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          _socketService.markMessageRead(
            messageId: message.id,
            customerId: widget.customerId,
          );
        }
      });
    });

    // 5. STATUS UPDATES
    _statusSubscription = _socketService.statusStream.listen((status) {
      if (!mounted) return;
      if (kDebugMode) {
        print('📊 [ChatScreen] Status changed: $status');
      }

      setState(() {
        if (status == 'ai_mode') {
          _chatStatus = ChatStatus.aiMode;
          _csName = null;
        } else if (status == 'connected_to_cs') {
          _chatStatus = ChatStatus.connectedToCs;
        }
      });
    });

    // 6. TYPING INDICATOR
    _typingSubscription = _socketService.typingStream.listen((typing) {
      if (!mounted) return;

      if (kDebugMode) {
        print('⌨️  [ChatScreen] Typing indicator: $typing');
      } // DEBUG LOG

      setState(() => _isTyping = typing);

      // Auto-stop typing after 5 seconds (safety timeout)
      if (typing) {
        Future.delayed(const Duration(seconds: 5), () {
          if (mounted && _isTyping) {
            if (kDebugMode) {
              print('⏰ [ChatScreen] Typing timeout - auto stopping');
            }
            setState(() => _isTyping = false);
          }
        });
      }
    });

    // 7. CS ASSIGNED
    _csAssignedSubscription = _socketService.csAssignedStream.listen((data) {
      if (!mounted) return;
      if (kDebugMode) {
        print('👤 [ChatScreen] CS assigned: ${data['csName']}');
      }

      setState(() {
        _csName = data['csName'];
        _chatStatus = ChatStatus.connectedToCs;
      });

      // Show snackbar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Terhubung dengan ${data['csName']}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    });
  }

  void _scrollToBottom() {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage() {
    final text = _textController.text.trim();

    if (text.isEmpty) {
      if (kDebugMode) {
        print('❌ [ChatScreen] Cannot send empty message');
      }
      return;
    }

    if (!_isConnected) {
      if (kDebugMode) {
        print('❌ [ChatScreen] Cannot send - not connected');
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tidak terhubung. Menunggu koneksi...'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (kDebugMode) {
      print('📤 [ChatScreen] Sending message: $text');
    }

    // Optimistic UI - add message immediately
    final tempMessage = Message(
      id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
      text: text,
      sender: MessageSender.customer,
      timestamp: DateTime.now(),
      read: false,
    );

    setState(() {
      _messages.add(tempMessage);
      _scrollToBottom();
    });

    // Send to server
    _socketService.sendCustomerMessage(
      customerId: widget.customerId,
      message: text,
      chatRoomId: _chatRoomId,
    );

    // Clear input
    _textController.clear();
  }

  String _getStatusText() {
    if (!_isConnected) return 'Menghubungkan...';

    switch (_chatStatus) {
      case ChatStatus.aiMode:
        return 'AI Assistant';
      case ChatStatus.connectedToCs:
        return _csName ?? 'Customer Service';
      case ChatStatus.connecting:
        return 'Menghubungkan...';
      case ChatStatus.disconnected:
        return 'Tidak Terhubung';
    }
  }

  String _getSubtitleText() {
    if (!_isConnected) return 'Offline';

    switch (_chatStatus) {
      case ChatStatus.aiMode:
        return 'Selalu Siap Membantu';
      case ChatStatus.connectedToCs:
        return 'Terhubung dengan CS';
      case ChatStatus.connecting:
        return 'Menghubungkan...';
      case ChatStatus.disconnected:
        return 'Offline';
    }
  }

  Color _getStatusColor() {
    if (!_isConnected) return Colors.grey;

    switch (_chatStatus) {
      case ChatStatus.aiMode:
        return Colors.blue;
      case ChatStatus.connectedToCs:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Hitung apakah button send harus enabled
    final canSend = _isConnected && _textController.text.trim().isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: primaryColor,
        elevation: 0,
        leading: widget.showBackButton
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              )
            : null,
        automaticallyImplyLeading: widget.showBackButton,
        title: Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: _getStatusColor(),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title ?? _getStatusText(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    _getSubtitleText(),
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          if (!_isConnected)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Connection status banner
          if (!_isConnected)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              color: Colors.red.shade50,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.wifi_off, size: 16, color: Colors.red.shade700),
                  const SizedBox(width: 8),
                  Text(
                    'Koneksi terputus. Mencoba menghubungkan kembali...',
                    style: TextStyle(
                      color: Colors.red.shade700,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

          // Messages area
          Expanded(
            child: Container(
              color: Colors.grey[50],
              child: _messages.isEmpty && !_isTyping
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.chat_bubble_outline,
                            size: 80,
                            color: Colors.grey[300],
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'Mulai percakapan',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Kirim pesan untuk memulai chat',
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: _messages.length + (_isTyping ? 1 : 0),
                      itemBuilder: (context, index) {
                        // ✅ TYPING INDICATOR at the end
                        if (_isTyping && index == _messages.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: TypingIndicator(
                              typingText: _chatStatus == ChatStatus.aiMode
                                  ? 'AI sedang mengetik...'
                                  : _csName != null
                                      ? '$_csName sedang mengetik...'
                                      : 'Sedang mengetik...',
                            ),
                          );
                        }
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: ChatBubble(
                            message: _messages[index],
                            isCustomer: _messages[index].sender ==
                                MessageSender.customer,
                            primaryColor: primaryColor,
                          ),
                        );
                      },
                    ),
            ),
          ),

          // Input area
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _textController,
                        enabled: _isConnected,
                        maxLines: null,
                        textInputAction: TextInputAction.send,
                        onSubmitted: canSend ? (_) => _sendMessage() : null,
                        decoration: InputDecoration(
                          hintText: _isConnected
                              ? 'Ketik pesan...'
                              : 'Menunggu koneksi...',
                          hintStyle:
                              TextStyle(color: Colors.grey[400], fontSize: 14),
                          filled: true,
                          fillColor: _isConnected
                              ? Colors.grey[100]
                              : Colors.grey[200],
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide:
                                BorderSide(color: primaryColor, width: 2),
                          ),
                          disabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Material(
                      color: canSend ? primaryColor : Colors.grey[300],
                      borderRadius: BorderRadius.circular(24),
                      child: InkWell(
                        onTap: canSend ? _sendMessage : null,
                        borderRadius: BorderRadius.circular(24),
                        child: Container(
                          width: 48,
                          height: 48,
                          alignment: Alignment.center,
                          child: Icon(
                            Icons.send,
                            color: canSend ? Colors.white : Colors.grey[500],
                            size: 22,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    if (kDebugMode) {
      print('🧹 [ChatScreen] Disposing...');
    }

    WidgetsBinding.instance.removeObserver(this);

    // Cancel all subscriptions
    _connectionSubscription?.cancel();
    _messageSubscription?.cancel();
    _chatHistorySubscription?.cancel();
    _statusSubscription?.cancel();
    _typingSubscription?.cancel();
    _csAssignedSubscription?.cancel();
    _chatStartedSubscription?.cancel();

    // ✅ PERUBAHAN: Unregister screen (BUKAN dispose service!)
    _socketService.unregisterScreen();

    // ❌ HAPUS BARIS INI:
    // _socketService.dispose();

    // Dispose controllers
    _textController.dispose();
    _scrollController.dispose();

    if (kDebugMode) {
      print('✅ [ChatScreen] Disposed');
    }
    super.dispose();
  }
}
