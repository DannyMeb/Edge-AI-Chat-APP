import 'package:flutter/material.dart';
import '../models/message.dart';

class ChatMessageWidget extends StatelessWidget {
  final Message message;

  const ChatMessageWidget({
    Key? key,
    required this.message,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: message.role == 'user'
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          if (message.role != 'user')
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: CircleAvatar(
                backgroundImage: AssetImage('assets/ai_avatar.png'),
                radius: 20,
              ),
            ),
          Flexible(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: message.role == 'user'
                    ? Colors.blue.withOpacity(0.7)
                    : Colors.grey.withOpacity(0.7),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: message.role == 'user'
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  Text(
                    message.content,
                    style: TextStyle(color: Colors.black87),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '${message.timestamp.hour}:${message.timestamp.minute.toString().padLeft(2, '0')}',
                    style: TextStyle(color: Colors.black54, fontSize: 10),
                  ),
                ],
              ),
            ),
          ),
          if (message.role == 'user')
            Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: CircleAvatar(
                backgroundImage: AssetImage('assets/user_avatar.png'),
                radius: 20,
              ),
            ),
        ],
      ),
    );
  }
} 