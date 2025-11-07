class ChatRoom {
  final String id;
  final String customerId;
  final String customerName;
  final String lastMessage;
  final DateTime timestamp;
  final int unreadCount;
  final String status;
  final String? csAssigned;
  final String? csName;
  final String? aiSummary;

  ChatRoom({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.lastMessage,
    required this.timestamp,
    this.unreadCount = 0,
    required this.status,
    this.csAssigned,
    this.csName,
    this.aiSummary,
  });

  factory ChatRoom.fromJson(Map<String, dynamic> json) {
    return ChatRoom(
      id: json['id'] as String,
      customerId: json['customerId'] as String,
      customerName: json['customerName'] as String,
      lastMessage: json['lastMessage'] as String? ?? '',
      timestamp: DateTime.parse(json['timestamp'] as String),
      unreadCount: json['unreadCount'] as int? ?? 0,
      status: json['status'] as String,
      csAssigned: json['csAssigned'] as String?,
      csName: json['csName'] as String?,
      aiSummary: json['aiSummary'] as String?,
    );
  }

  ChatRoom copyWith({
    String? id,
    String? customerId,
    String? customerName,
    String? lastMessage,
    DateTime? timestamp,
    int? unreadCount,
    String? status,
    String? csAssigned,
    String? csName,
    String? aiSummary,
  }) {
    return ChatRoom(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      lastMessage: lastMessage ?? this.lastMessage,
      timestamp: timestamp ?? this.timestamp,
      unreadCount: unreadCount ?? this.unreadCount,
      status: status ?? this.status,
      csAssigned: csAssigned ?? this.csAssigned,
      csName: csName ?? this.csName,
      aiSummary: aiSummary ?? this.aiSummary,
    );
  }
}
