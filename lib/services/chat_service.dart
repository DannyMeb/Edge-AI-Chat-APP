import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/message.dart';

class ChatService {
  static const String _chatHistoryKey = 'chatHistory';

  // Save current chat to SharedPreferences
  static Future<void> saveChat(List<Message> messages) async {
    if (messages.isEmpty || !messages.any((msg) => msg.content.trim().isNotEmpty)) {
      return; // Do not save empty chats
    }

    final prefs = await SharedPreferences.getInstance();
    List<String> chatHistory = prefs.getStringList(_chatHistoryKey) ?? [];

    // Convert current messages into a serializable format (JSON)
    List<Map<String, dynamic>> serializedMessages = messages
        .map((message) => {
              'content': message.content,
              'role': message.role,
              'timestamp': message.timestamp.toIso8601String(),
              'avatar': message.avatar
            })
        .toList();

    // Create a unique name for the chat, using a timestamp for uniqueness
    String chatName = 'Chat_${DateTime.now().millisecondsSinceEpoch}';

    // Add only if there's actual content and it's not already in chatHistory
    if (!chatHistory.contains(chatName) && serializedMessages.isNotEmpty) {
      chatHistory.add(chatName);
      await prefs.setStringList(_chatHistoryKey, chatHistory);
      await prefs.setString(chatName, jsonEncode(serializedMessages));
    }
  }

  // Load a specific chat by name
  static Future<List<Message>?> loadChat(String chatName) async {
    final prefs = await SharedPreferences.getInstance();
    String? chatData = prefs.getString(chatName);

    if (chatData != null) {
      List<dynamic> deserializedMessages = jsonDecode(chatData);
      return deserializedMessages
          .map((message) => Message.withTimestamp(
              content: message['content'],
              role: message['role'],
              avatar: message['avatar'],
              timestamp: DateTime.parse(message['timestamp'])))
          .toList();
    }
    return null;
  }

  // Get all chat history names
  static Future<List<String>> getChatHistory() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> chats = prefs.getStringList(_chatHistoryKey) ?? [];

    // Sort chats from new to old by extracting the timestamp
    chats.sort((a, b) {
      int aTimestamp = int.tryParse(a.split('_').last) ?? 0;
      int bTimestamp = int.tryParse(b.split('_').last) ?? 0;
      return bTimestamp.compareTo(aTimestamp); // Sort new to old
    });

    return chats;
  }

  // Delete a specific chat
  static Future<void> deleteChat(String chatName) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> chatHistory = prefs.getStringList(_chatHistoryKey) ?? [];

    // Remove the chat from the list
    chatHistory.remove(chatName);
    await prefs.setStringList(_chatHistoryKey, chatHistory);

    // Remove the chat data from SharedPreferences
    await prefs.remove(chatName);
  }

  // Rename a chat
  static Future<bool> renameChat(String oldChatName, String newChatName) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> chatHistory = prefs.getStringList(_chatHistoryKey) ?? [];

    if (newChatName.isNotEmpty && !chatHistory.contains(newChatName)) {
      // Get the chat data for the old name
      String? chatData = prefs.getString(oldChatName);

      // Update the chat history list with the new name
      int index = chatHistory.indexOf(oldChatName);
      if (index != -1) {
        chatHistory[index] = newChatName;
      }

      // Save the updated chat history list
      await prefs.setStringList(_chatHistoryKey, chatHistory);

      // Save the chat data under the new name
      if (chatData != null) {
        await prefs.setString(newChatName, chatData);
      }

      // Remove the old chat name and its associated data
      await prefs.remove(oldChatName);
      return true;
    }
    return false;
  }
} 