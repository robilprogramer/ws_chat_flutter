// ============================================
// lib/src/widgets/components/chat_bubble.dart
// ============================================
// ignore_for_file: use_super_parameters

import 'package:flutter/material.dart';
import '../../models/message.dart';

class ChatBubble extends StatelessWidget {
  final Message message;
  final bool isCustomer;
  final Color primaryColor;
  final bool showSenderName;
  final String? csName;

  const ChatBubble({
    Key? key,
    required this.message,
    required this.isCustomer,
    required this.primaryColor,
    this.showSenderName = false,
    this.csName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool isSystem = message.sender == MessageSender.system;
    final bool isAI = message.sender == MessageSender.ai;

    // System message (center aligned)
    if (isSystem) {
      return Center(
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.yellow[100],
            border: Border.all(color: Colors.yellow[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            message.text,
            style: TextStyle(
              color: Colors.yellow[900],
              fontSize: 13,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Align(
      alignment: isCustomer ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment:
            isCustomer ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          // Sender name (for CS view)
          if (showSenderName && !isCustomer)
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 4),
              child: Text(
                message.senderName ??
                    (isAI ? 'AI Assistant' : message.sender.name.toUpperCase()),
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

          // Message bubble
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isCustomer
                  ? primaryColor
                  : isAI
                      ? Colors.blue[50]
                      : Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft:
                    isCustomer ? const Radius.circular(16) : Radius.zero,
                bottomRight:
                    isCustomer ? Radius.zero : const Radius.circular(16),
              ),
              boxShadow: isCustomer
                  ? null
                  : [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Message text
                Text(
                  message.text,
                  style: TextStyle(
                    color: isCustomer
                        ? Colors.white
                        : isAI
                            ? Colors.blue[900]
                            : Colors.black87,
                    fontSize: 14,
                  ),
                ),

                const SizedBox(height: 4),

                // Timestamp and read status
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      message.formattedTime,
                      style: TextStyle(
                        color: isCustomer ? Colors.white70 : Colors.grey[600],
                        fontSize: 11,
                      ),
                    ),
                    if (isCustomer || message.sender == MessageSender.cs) ...[
                      const SizedBox(width: 4),
                      Icon(
                        message.read ? Icons.done_all : Icons.done,
                        size: 16,
                        color: isCustomer
                            ? (message.read ? Colors.blue[200] : Colors.white70)
                            : (message.read ? Colors.blue : Colors.grey[400]),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
