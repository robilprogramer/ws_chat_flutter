import 'package:flutter/material.dart';

class ChatInput extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final bool enabled;
  final Color primaryColor;
  final String? hintText;

  const ChatInput({
    super.key,
    required this.controller,
    required this.onSend,
    this.enabled = true,
    required this.primaryColor,
    this.hintText,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            enabled: enabled,
            maxLines: null,
            textInputAction: TextInputAction.send,
            onSubmitted: enabled ? (_) => onSend() : null,
            decoration: InputDecoration(
              hintText: hintText ?? 'Ketik pesan...',
              hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
              filled: true,
              fillColor: enabled ? Colors.grey[100] : Colors.grey[200],
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
          color: enabled && controller.text.isNotEmpty
              ? primaryColor
              : Colors.grey[300],
          borderRadius: BorderRadius.circular(24),
          child: InkWell(
            onTap: enabled && controller.text.isNotEmpty ? onSend : null,
            borderRadius: BorderRadius.circular(24),
            child: Container(
              width: 48,
              height: 48,
              alignment: Alignment.center,
              child: Icon(
                Icons.send,
                color: enabled && controller.text.isNotEmpty
                    ? Colors.white
                    : Colors.grey[500],
                size: 22,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
