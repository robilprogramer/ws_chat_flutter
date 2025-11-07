// ignore_for_file: deprecated_member_use, avoid_print

import 'dart:async';
import 'package:flutter/material.dart';
import '../models/message.dart';
import '../models/chat_room.dart';
import '../services/socket_service.dart';
import '../widgets/components/chat_bubble.dart';

class CSDashboardScreen extends StatefulWidget {
  final String serverUrl;
  final String csUserId;
  final String csName;
  final Color? primaryColor;

  const CSDashboardScreen({
    Key? key,
    required this.serverUrl,
    required this.csUserId,
    required this.csName,
    this.primaryColor,
  }) : super(key: key);

  @override
  State<CSDashboardScreen> createState() => _CSDashboardScreenState();
}

class _CSDashboardScreenState extends State<CSDashboardScreen>
    with WidgetsBindingObserver {
  late SocketService _socketService;
  final List<ChatRoom> _chatRooms = [];
  final List<Message> _messages = [];
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // Stream subscriptions
  StreamSubscription<bool>? _connectionSubscription;
  StreamSubscription<List<ChatRoom>>? _chatRoomsSubscription;
  StreamSubscription<List<Message>>? _chatHistorySubscription;
  StreamSubscription<Message>? _messageSubscription;

  ChatRoom? _selectedRoom;
  String? _selectedRoomId; // Track selected room ID separately
  bool _isConnected = false;
  bool _isLoading = true;
  bool _hasLoggedIn = false;

  Color get primaryColor => widget.primaryColor ?? const Color(0xFF10B981);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // ✅ PERUBAHAN: Gunakan getInstance untuk singleton
    _socketService = SocketService.getInstance(serverUrl: widget.serverUrl);

    // ✅ PERUBAHAN: Register screen ke service
    _socketService.registerScreen();

    // Listen to text changes
    _textController.addListener(() {
      setState(() {});
    });

    _setupListeners();
    _connectAndLogin();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed && !_isConnected && mounted) {
      print('📱 [CS] App resumed - reconnecting...');
      _connectAndLogin();
    }
  }

  void _connectAndLogin() {
    if (!mounted) return;
    print('🔌 [CS] Connecting to server...');
    _socketService.connect();
  }

  void _setupListeners() {
    // 1. CONNECTION - Auto login setelah connect
    _connectionSubscription =
        _socketService.connectionStream.listen((connected) {
      if (!mounted) return;
      print('🔗 [CS] Connection status: $connected');

      setState(() {
        _isConnected = connected;
        if (!connected) _isLoading = false;
      });

      if (connected && !_hasLoggedIn) {
        _hasLoggedIn = true;

        // ALUR SESUAI HTML test.html:
        // 1. CS Login otomatis setelah connect
        print('🔐 [CS] Auto logging in as: ${widget.csName}');
        _socketService.csLogin(
          userId: widget.csUserId,
          name: widget.csName,
        );

        // Server akan auto kirim cs_chat_rooms setelah login
      } else if (!connected) {
        _hasLoggedIn = false;
        setState(() {
          _selectedRoom = null;
          _selectedRoomId = null;
          _messages.clear();
        });
      }
    });

    // 2. CHAT ROOMS - List semua chat rooms
    _chatRoomsSubscription = _socketService.chatRoomsStream.listen((rooms) {
      if (!mounted) return;
      print('📋 [CS] Received ${rooms.length} chat rooms');

      setState(() {
        _chatRooms.clear();
        _chatRooms.addAll(rooms);
        _chatRooms.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        _isLoading = false;
      });

      // Update selected room jika ada
      if (_selectedRoomId != null) {
        final updatedRoom = _chatRooms.firstWhere(
          (r) => r.id == _selectedRoomId,
          orElse: () => _selectedRoom!,
        );
        if (mounted) {
          setState(() {
            _selectedRoom = updatedRoom;
          });
        }
      }

      // Show notification untuk new unread chat (bukan yang sedang dibuka)
      if (rooms.isNotEmpty && mounted) {
        for (var room in rooms) {
          if (room.unreadCount > 0 && room.id != _selectedRoomId) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Pesan baru dari ${room.customerName}'),
                backgroundColor: primaryColor,
                duration: const Duration(seconds: 2),
                action: SnackBarAction(
                  label: 'Lihat',
                  textColor: Colors.white,
                  onPressed: () => _selectRoom(room),
                ),
              ),
            );
            break; // Show only one notification at a time
          }
        }
      }
    });

    // 3. CHAT HISTORY - Untuk room yang dipilih
    _chatHistorySubscription =
        _socketService.chatHistoryStream.listen((messages) {
      if (!mounted) return;
      print('📜 [CS] Chat history: ${messages.length} messages');

      // Hanya update jika masih room yang sama
      if (_selectedRoom != null) {
        setState(() {
          _messages.clear();
          _messages.addAll(messages);
          _scrollToBottom();
        });
      }
    });

    // 4. NEW MESSAGES - Real-time dari customer
    _messageSubscription = _socketService.messageStream.listen((message) {
      if (!mounted) return;
      print('📨 [CS] New message: ${message.text} from ${message.sender.name}');

      // Hanya add message jika di room yang aktif
      if (_selectedRoom != null && mounted) {
        setState(() {
          if (!_messages.any((m) => m.id == message.id)) {
            _messages.add(message);
            _scrollToBottom();

            // Update room last message
            final roomIndex =
                _chatRooms.indexWhere((r) => r.id == _selectedRoom!.id);
            if (roomIndex != -1) {
              _chatRooms[roomIndex] = _chatRooms[roomIndex].copyWith(
                lastMessage: message.text,
                timestamp: message.timestamp,
                unreadCount: 0, // Mark as read karena sedang dibuka
              );
              _chatRooms.sort((a, b) => b.timestamp.compareTo(a.timestamp));
            }
          }
        });

        // Auto mark as read setelah 500ms
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted && _selectedRoom != null) {
            _socketService.csMarkMessagesRead(
              chatRoomId: _selectedRoom!.id,
              csUserId: widget.csUserId,
            );
          }
        });
      }
    });
  }

  void _selectRoom(ChatRoom room) {
    if (!mounted) return;
    print('📂 [CS] Selecting room: ${room.customerName} (${room.id})');

    setState(() {
      _selectedRoom = room;
      _selectedRoomId = room.id; // Track ID
      _messages.clear(); // Clear dulu untuk show loading

      // Clear unread count immediately
      final index = _chatRooms.indexWhere((r) => r.id == room.id);
      if (index != -1) {
        _chatRooms[index] = _chatRooms[index].copyWith(unreadCount: 0);
      }
    });

    // Request chat history untuk room ini
    _socketService.csSelectRoom(
      chatRoomId: room.id,
      csUserId: widget.csUserId,
    );
  }

  void _sendMessage() {
    if (_selectedRoom == null || !mounted) return;

    final text = _textController.text.trim();

    if (text.isEmpty) {
      print('❌ [CS] Cannot send empty message');
      return;
    }

    if (!_isConnected) {
      print('❌ [CS] Cannot send - not connected');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tidak terhubung. Menunggu koneksi...'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    print('📤 [CS] Sending message: $text');

    // Optimistic UI
    final tempMessage = Message(
      id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
      text: text,
      sender: MessageSender.cs,
      timestamp: DateTime.now(),
      senderName: widget.csName,
      read: false,
    );

    setState(() {
      _messages.add(tempMessage);
      _scrollToBottom();

      // Update room last message
      final index = _chatRooms.indexWhere((r) => r.id == _selectedRoom!.id);
      if (index != -1) {
        _chatRooms[index] = _chatRooms[index].copyWith(
          lastMessage: text,
          timestamp: DateTime.now(),
        );
        _chatRooms.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      }
    });

    _socketService.csSendMessage(
      chatRoomId: _selectedRoom!.id,
      message: text,
      csUserId: widget.csUserId,
    );

    _textController.clear();
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

  void _refreshRooms() {
    if (_isConnected && mounted) {
      print('🔄 [CS] Refreshing rooms...');
      setState(() => _isLoading = true);
      _socketService.csGetAllRooms(csUserId: widget.csUserId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final canSend = _isConnected &&
        _textController.text.trim().isNotEmpty &&
        _selectedRoom != null;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: primaryColor,
        elevation: 0,
        title: Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: _isConnected ? Colors.white : Colors.red.shade300,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CS Dashboard - ${widget.csName}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    _isConnected
                        ? '${_chatRooms.length} Chat${_chatRooms.length != 1 ? 's' : ''}'
                        : 'Menghubungkan...',
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
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _isConnected ? _refreshRooms : null,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: isMobile ? _buildMobileLayout() : _buildDesktopLayout(canSend),
    );
  }

  Widget _buildMobileLayout() {
    if (_selectedRoom == null) {
      return _buildRoomsList();
    } else {
      final canSend = _isConnected && _textController.text.trim().isNotEmpty;

      return Column(
        children: [
          // Room header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () {
                    if (mounted) {
                      setState(() {
                        _selectedRoom = null;
                        _selectedRoomId = null;
                        _messages.clear();
                      });
                    }
                  },
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedRoom!.customerName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        'ID: ${_selectedRoom!.customerId}',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                ),
                if (_selectedRoom!.aiSummary != null)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'AI Handover',
                      style: TextStyle(color: Colors.blue[700], fontSize: 11),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(child: _buildChatArea(canSend)),
        ],
      );
    }
  }

  Widget _buildDesktopLayout(bool canSend) {
    return Row(
      children: [
        SizedBox(width: 320, child: _buildRoomsList()),
        Expanded(
          child: _selectedRoom == null
              ? _buildEmptyState()
              : Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border(
                            bottom: BorderSide(color: Colors.grey[300]!)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _selectedRoom!.customerName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  'ID: ${_selectedRoom!.customerId}',
                                  style: TextStyle(
                                      color: Colors.grey[600], fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          if (_selectedRoom!.aiSummary != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.blue[50],
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'Handover dari AI',
                                style: TextStyle(
                                  color: Colors.blue[700],
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    Expanded(child: _buildChatArea(canSend)),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildRoomsList() {
    return Container(
      color: Colors.grey[50],
      child: Column(
        children: [
          if (!_isConnected)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              color: Colors.red.shade50,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.wifi_off, size: 16, color: Colors.red.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Koneksi terputus',
                      style:
                          TextStyle(color: Colors.red.shade700, fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _chatRooms.isEmpty
                    ? _buildEmptyRoomsList()
                    : ListView.builder(
                        itemCount: _chatRooms.length,
                        itemBuilder: (context, index) {
                          final room = _chatRooms[index];
                          final isSelected = _selectedRoomId == room.id;

                          return InkWell(
                            onTap: () => _selectRoom(room),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? primaryColor.withOpacity(0.1)
                                    : Colors.white,
                                border: Border(
                                  left: BorderSide(
                                    color: isSelected
                                        ? primaryColor
                                        : Colors.transparent,
                                    width: 4,
                                  ),
                                  bottom: BorderSide(color: Colors.grey[200]!),
                                ),
                              ),
                              child: _buildRoomItem(room, isSelected),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoomItem(ChatRoom room, bool isSelected) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                room.customerName,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: isSelected ? primaryColor : Colors.black87,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (room.unreadCount > 0)
              Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                child: Text(
                  room.unreadCount > 99 ? '99+' : '${room.unreadCount}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          room.lastMessage.isEmpty ? 'Tidak ada pesan' : room.lastMessage,
          style: TextStyle(color: Colors.grey[600], fontSize: 13),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              room.timestamp.toLocal().toString().substring(11, 16),
              style: TextStyle(color: Colors.grey[500], fontSize: 11),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: room.status == 'ai_mode'
                    ? Colors.blue[50]
                    : room.status == 'connected_to_cs'
                        ? Colors.green[50]
                        : Colors.yellow[50],
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                room.status == 'ai_mode'
                    ? 'AI Mode'
                    : room.status == 'connected_to_cs'
                        ? 'CS Active'
                        : room.status,
                style: TextStyle(
                  color: room.status == 'ai_mode'
                      ? Colors.blue[700]
                      : room.status == 'connected_to_cs'
                          ? Colors.green[700]
                          : Colors.yellow[800],
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        if (room.aiSummary != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                Icon(Icons.smart_toy, size: 14, color: Colors.blue[700]),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    room.aiSummary!,
                    style: TextStyle(color: Colors.blue[700], fontSize: 11),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildEmptyRoomsList() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Belum ada chat',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Menunggu customer...',
            style: TextStyle(color: Colors.grey[500], fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      color: Colors.grey[50],
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline, size: 100, color: Colors.grey[300]),
            const SizedBox(height: 24),
            Text(
              'Pilih chat untuk memulai',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Klik salah satu chat di sebelah kiri',
              style: TextStyle(color: Colors.grey[500], fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatArea(bool canSend) {
    return Column(
      children: [
        Expanded(
          child: Container(
            color: Colors.grey[50],
            child: _messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 16),
                        Text(
                          'Memuat riwayat chat...',
                          style:
                              TextStyle(color: Colors.grey[600], fontSize: 14),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: ChatBubble(
                          message: _messages[index],
                          isCustomer:
                              _messages[index].sender != MessageSender.cs,
                          primaryColor: primaryColor,
                          showSenderName: true,
                          csName: widget.csName,
                        ),
                      );
                    },
                  ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
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
                      enabled: _isConnected && _selectedRoom != null,
                      maxLines: null,
                      textInputAction: TextInputAction.send,
                      onSubmitted: canSend ? (_) => _sendMessage() : null,
                      decoration: InputDecoration(
                        hintText: _isConnected
                            ? (_selectedRoom != null
                                ? 'Ketik balasan...'
                                : 'Pilih chat dulu...')
                            : 'Menunggu koneksi...',
                        hintStyle:
                            TextStyle(color: Colors.grey[400], fontSize: 14),
                        filled: true,
                        fillColor: _isConnected && _selectedRoom != null
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
                          borderSide: BorderSide(color: primaryColor, width: 2),
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
    );
  }

  @override
  void dispose() {
    print('🧹 [CS] Disposing CSDashboardScreen...');

    WidgetsBinding.instance.removeObserver(this);

    // Cancel subscriptions
    _connectionSubscription?.cancel();
    _chatRoomsSubscription?.cancel();
    _chatHistorySubscription?.cancel();
    _messageSubscription?.cancel();

    // CS Logout jika masih connected
    if (_isConnected) {
      _socketService.csLogout(csUserId: widget.csUserId);
    }

    // ✅ PERUBAHAN: Unregister screen (BUKAN dispose service!)
    _socketService.unregisterScreen();

    // ❌ HAPUS BARIS INI:
    // _socketService.dispose();

    // Dispose controllers
    _textController.dispose();
    _scrollController.dispose();

    print('✅ [CS] CSDashboardScreen disposed');
    super.dispose();
  }
}
