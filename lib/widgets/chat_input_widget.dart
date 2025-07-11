import 'package:flutter/material.dart';

class ChatInputWidget extends StatelessWidget {
  final TextEditingController controller;
  final bool isModelReplying;
  final VoidCallback onSend;
  final VoidCallback onStop;

  const ChatInputWidget({
    Key? key,
    required this.controller,
    required this.isModelReplying,
    required this.onSend,
    required this.onStop,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: [
          Icon(Icons.sentiment_satisfied, color: Colors.grey),
          SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: 'Type a message',
                border: InputBorder.none,
              ),
              onSubmitted: (text) {
                if (text.isNotEmpty) {
                  onSend();
                }
              },
            ),
          ),
          IconButton(
            icon: Icon(
              isModelReplying ? Icons.stop : Icons.send,
              color: isModelReplying ? Colors.red : Colors.purple,
            ),
            onPressed: isModelReplying ? onStop : onSend,
          ),
        ],
      ),
    );
  }
} 