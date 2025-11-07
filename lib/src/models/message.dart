import 'package:intl/intl.dart';

enum MessageSender { customer, cs, ai, system }

class Message {
  final String id;
  final String text;
  final MessageSender sender;
  final DateTime timestamp;
  final bool read;
  final String? senderName;

  Message({
    required this.id,
    required this.text,
    required this.sender,
    required this.timestamp,
    this.read = false,
    this.senderName,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] as String,
      text: json['text'] as String,
      sender: _parseSender(json['sender'] as String),
      timestamp: DateTime.parse(json['timestamp'] as String),
      read: json['read'] as bool? ?? false,
      senderName: json['senderName'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'sender': sender.name,
      'timestamp': timestamp.toIso8601String(),
      'read': read,
      'senderName': senderName,
    };
  }

  Message copyWith({
    String? id,
    String? text,
    MessageSender? sender,
    DateTime? timestamp,
    bool? read,
    String? senderName,
  }) {
    return Message(
      id: id ?? this.id,
      text: text ?? this.text,
      sender: sender ?? this.sender,
      timestamp: timestamp ?? this.timestamp,
      read: read ?? this.read,
      senderName: senderName ?? this.senderName,
    );
  }

  String get formattedTime {
    return DateFormat('HH:mm').format(timestamp);
  }

  static MessageSender _parseSender(String sender) {
    switch (sender.toLowerCase()) {
      case 'customer':
        return MessageSender.customer;
      case 'cs':
        return MessageSender.cs;
      case 'ai':
        return MessageSender.ai;
      case 'system':
        return MessageSender.system;
      default:
        return MessageSender.system;
    }
  }
}
