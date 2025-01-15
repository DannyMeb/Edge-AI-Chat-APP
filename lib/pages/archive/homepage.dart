import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'package:falcon_chat/widgets/left_panel_buttons.dart';
import 'package:falcon_chat/core/system_usage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _promptController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  late ReceivePort _systemUsageReceivePort;
  late Isolate _systemUsageIsolate;
  double _ramUsage = 0.0;

  ReceivePort? _modelReceivePort;
  Isolate? _modelIsolate;
  File? modelFile;
  String? modelName;
  bool _isModelReplying = false;

  StreamSubscription<String>? _streamSubscription;

  List<Message> messages = [];

  @override
  void initState() {
    super.initState();
    _initUsageIsolate();
  }

  @override
  void dispose() {
    _systemUsageIsolate.kill();
    _systemUsageReceivePort.close();
    _unLoadModel();
    _streamSubscription?.cancel();
    _promptController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _initUsageIsolate() async {
    _systemUsageReceivePort = ReceivePort();
    _systemUsageIsolate =
        await Isolate.spawn(fetchSystemUsage, _systemUsageReceivePort.sendPort);
    _systemUsageReceivePort.listen((dynamic data) {
      setState(() {
        _ramUsage = data['ramUsage'];
      });
    });
  }

  void _initModelIsolate(String userPrompt) async {
    _modelReceivePort = ReceivePort();
    _modelIsolate = await Isolate.spawn(fetchModelResponse,
        [_modelReceivePort!.sendPort, modelFile, userPrompt]);
    messages
        .add(Message(content: '', role: 'AI', avatar: 'assets/ai_avatar.png'));
    _scrollToBottom();

    _modelReceivePort!.listen((dynamic data) {
      if (data['completed'] == true) {
        _modelIsolate?.kill();
        _isModelReplying = false;
      } else {
        setState(() {
          final cleanedToken = data['token']
              .replaceAll('<|endoftext|>', '')
              .replaceAll(userPrompt, '');

          messages.last.content += cleanedToken;
        });
        _scrollToBottom();
      }
    });
  }

  void _unLoadModel({bool onlyPort = false}) {
    if (onlyPort) {
      _isModelReplying = false;
      _modelReceivePort?.close();
      return;
    }
    modelFile = null;
    modelName = null;
    _modelIsolate?.kill();
    _modelReceivePort?.close();
    _isModelReplying = false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.pink[300]!, Colors.teal[200]!],
          ),
        ),
        child: Row(children: [
          _leftPanel(),
          _chatPanel(),
        ]),
      ),
    );
  }

  Widget _leftPanel() {
    return Container(
      width: 75,
      height: double.infinity,
      color: Colors.white.withOpacity(0.1),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            children: [
              LeftPanelButtonWidget(
                icon: Icons.home,
                color: Colors.white,
                onPressed: () {},
              ),
              LeftPanelButtonWidget(
                icon: Icons.search,
                color: Colors.white,
                onPressed: () {},
              ),
              LeftPanelButtonWidget(
                icon: Icons.folder,
                color: Colors.white,
                onPressed: () {},
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Text(
              'v0.0.1',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chatPanel() {
    return Expanded(
      child: Column(
        children: [
          _upperChatPanel(),
          Expanded(
            child: _chatSectionPanel(),
          ),
        ],
      ),
    );
  }

  Widget _upperChatPanel() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'RAM Usage: ${(_ramUsage * 100).toStringAsFixed(1)}%',
            style: TextStyle(color: Colors.white, fontSize: 14),
          ),
          ElevatedButton(
            onPressed: () async {
              FilePickerResult? result = await FilePicker.platform.pickFiles();
              if (result != null) {
                setState(() {
                  modelFile = File(result.files.single.path!);
                  modelName = result.files.single.name;
                });
              }
            },
            child: Text(modelName ?? 'Select your model'),
          ),
          if (modelName != null)
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _promptController.clear();
                  _unLoadModel();
                });
              },
              child: Text('Eject Model'),
            ),
        ],
      ),
    );
  }

  Widget _chatSectionPanel() {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            itemCount: messages.length,
            itemBuilder: (context, index) {
              final message = messages[index];
              return _buildMessageBubble(message);
            },
          ),
        ),
        _buildInputField(),
      ],
    );
  }

  Widget _buildMessageBubble(Message message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: message.role == 'user'
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          if (message.role != 'user') // AI Avatar on the left
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
                    ? Colors.blue.withOpacity(0.2) // User bubble color
                    : Colors.white.withOpacity(0.9), // AI bubble color
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
          if (message.role == 'user') // User Avatar on the right
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

  Widget _buildInputField() {
    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _promptController,
              decoration: InputDecoration(
                hintText: 'Type a message',
                border: InputBorder.none,
              ),
              onSubmitted: _handleSubmitted,
            ),
          ),
          IconButton(
            icon: Icon(Icons.send),
            onPressed: () => _handleSubmitted(_promptController.text),
          ),
        ],
      ),
    );
  }

  void _handleSubmitted(String text) {
    if (text.isEmpty) return;
    setState(() {
      messages.add(Message(
          content: text, role: 'user', avatar: 'assets/user_avatar.png'));
      _promptController.clear();
    });
    _scrollToBottom();
    _initModelIsolate(text);
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }
}

class Message {
  String content;
  final String role;
  final String avatar;
  final DateTime timestamp;

  Message({required this.content, required this.role, required this.avatar})
      : timestamp = DateTime.now();
}
