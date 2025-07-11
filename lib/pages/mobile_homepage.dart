import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'package:flutter/material.dart';
import '../models/message.dart';
import '../services/chat_service.dart';
import '../services/model_service.dart';
import '../services/video_service.dart';
import '../widgets/video_feed_widget.dart';
import '../widgets/chat_message_widget.dart';
import '../widgets/chat_input_widget.dart';
import '../widgets/chat_sidebar_widget.dart';

class MobileHomePage extends StatefulWidget {
  const MobileHomePage({super.key});

  @override
  State<MobileHomePage> createState() => _MobileHomePageState();
}

class _MobileHomePageState extends State<MobileHomePage> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _promptController = TextEditingController();
  
  File? modelFile;
  String? modelName;
  List<Message> messages = [];
  bool _isModelReplying = false;
  bool _isSidebarVisible = false;

  ReceivePort? _modelReceivePort;
  Isolate? _modelIsolate;

  @override
  void dispose() {
    _unloadModel();
    _promptController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // Model Management
  Future<void> _loadModel() async {
    File? file = await ModelService.loadModel();
    if (file != null) {
      setState(() {
        modelFile = file;
        modelName = file.path.split('/').last;
      });
    } else {
      ModelService.showInvalidModelDialog(context);
    }
  }

  void _unloadModel() {
    ModelService.unloadModel(
      isolate: _modelIsolate,
      receivePort: _modelReceivePort,
    );
    setState(() {
      modelFile = null;
      modelName = null;
      _isModelReplying = false;
    });
  }

  void _ejectModel() {
    setState(() {
      _unloadModel();
      messages.clear();
      _isSidebarVisible = false;
    });
  }

  // Chat Management
  void _initModelIsolate(String userPrompt) async {
    if (modelFile == null) return;

    final result = await ModelService.initModelIsolate(userPrompt, modelFile!);
    if (result == null) return;

    _modelReceivePort = result.receivePort;
    _modelIsolate = result.isolate;
    _isModelReplying = true;

    setState(() {
      messages.add(Message(
        content: '',
        role: 'AI',
        avatar: 'assets/ai_avatar.png',
      ));
    });
    _scrollToBottom();

    _modelReceivePort!.listen((dynamic data) {
      if (data['completed'] == true) {
        _modelIsolate?.kill();
        setState(() {
          _isModelReplying = false;
        });
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

  void _stopModelGeneration() {
    if (_isModelReplying && _modelIsolate != null) {
      _modelIsolate?.kill();
      setState(() {
        _isModelReplying = false;
      });
    }
  }

  void _handleSubmitted(String text) {
    if (text.isEmpty || modelFile == null) return;
    setState(() {
      messages.add(Message(
        content: text,
        role: 'user',
        avatar: 'assets/user_avatar.png',
      ));
      _promptController.clear();
    });
    _scrollToBottom();
    _initModelIsolate(text);
  }

  void _handleHintSelection(String hintText) {
    setState(() {
      messages.add(Message(
        content: hintText,
        role: 'user',
        avatar: 'assets/user_avatar.png',
      ));
      _promptController.clear();
    });
    _scrollToBottom();
    _initModelIsolate(hintText);
  }

  // Chat History Management
  void _saveCurrentChat() async {
    await ChatService.saveChat(messages);
    messages.clear();
    setState(() {});
  }

  void _loadSelectedChat(String chatName) async {
    if (_isModelReplying) {
      _stopModelGeneration();
    }

    if (messages.isNotEmpty) {
      _saveCurrentChat();
    }

    List<Message>? loadedMessages = await ChatService.loadChat(chatName);
    if (loadedMessages != null) {
      setState(() {
        messages = loadedMessages;
      });
    }
  }

  // UI Management
  void _toggleSidebar() {
    setState(() {
      _isSidebarVisible = !_isSidebarVisible;
    });
  }

  void _closeSidebarOnTap() {
    if (_isSidebarVisible) {
      setState(() {
        _isSidebarVisible = false;
      });
    }
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

  void _playVideo(String videoId) {
    VideoService.playVideo(context, videoId);
  }

  // UI Components
  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          modelFile == null
              ? _buildNotificationButton()
              : _buildModelTitle(),
          modelFile == null ? _buildSettingsDropdown() : _buildSidebarToggle(),
        ],
      ),
    );
  }

  Widget _buildNotificationButton() {
    return Stack(
      children: [
        IconButton(
          icon: Icon(Icons.notifications, color: Colors.purple),
          onPressed: () {
            // Handle notification icon press here
          },
        ),
        Positioned(
          top: 0,
          right: 0,
          child: Container(
            padding: EdgeInsets.all(1),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(6),
            ),
            constraints: BoxConstraints(
              minWidth: 12,
              minHeight: 12,
            ),
            child: Text(
              '2',
              style: TextStyle(
                color: Colors.white,
                fontSize: 8,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildModelTitle() {
    return Row(
      children: [
        Text(
          'Falcon Chat',
          style: TextStyle(
            color: Colors.purple,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(width: 10),
        IconButton(
          icon: Icon(Icons.info_outline, color: Colors.purple),
          onPressed: () {
            _showModelInfoDialog(context);
          },
        ),
      ],
    );
  }

  Widget _buildSettingsDropdown() {
    return PopupMenuButton<String>(
      icon: Icon(Icons.more_vert, color: const Color.fromARGB(255, 151, 0, 151)),
      onSelected: (String value) {},
      itemBuilder: (BuildContext context) {
        return [
          PopupMenuItem(value: 'Contact', child: Text('Contact')),
          PopupMenuItem(value: 'Help', child: Text('Help')),
          PopupMenuItem(value: 'FAQ', child: Text('FAQ')),
        ];
      },
    );
  }

  Widget _buildSidebarToggle() {
    return GestureDetector(
      onTap: _toggleSidebar,
      child: Icon(
        _isSidebarVisible ? Icons.arrow_back : Icons.menu,
        color: Colors.purple,
      ),
    );
  }

  Widget _buildMessageList() {
    if (messages.isEmpty && modelFile != null) {
      return Center(
        child: _buildHintsOrPrompt(),
      );
    } else {
      return ListView.builder(
        controller: _scrollController,
        itemCount: messages.length,
        itemBuilder: (context, index) {
          final message = messages[index];
          return ChatMessageWidget(message: message);
        },
      );
    }
  }

  Widget _buildHintsOrPrompt() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Start typing to chat...',
          style: TextStyle(fontSize: 18, color: Colors.grey[700]),
        ),
        SizedBox(height: 20),
        SizedBox(height: 10),
        _buildHintButton('What can you do?'),
        _buildHintButton('Tell me a joke'),
        _buildHintButton('How is the weather today?'),
      ],
    );
  }

  Widget _buildHintButton(String hintText) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: ElevatedButton(
        onPressed: () => _handleHintSelection(hintText),
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          backgroundColor: Colors.purple,
          foregroundColor: Colors.white,
        ),
        child: Text(
          hintText,
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }

  Widget _buildInputOrLoadModel() {
    if (modelFile == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/logo.png',
              width: 200,
              height: 150,
            ),
            SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _loadModel,
              icon: Icon(Icons.file_upload),
              label: Text('Load Model'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              ),
            ),
            SizedBox(height: 20),
            const Text(
              'Please load a model to start chatting.',
              style: TextStyle(fontSize: 12, color: Colors.black),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    } else {
      return ChatInputWidget(
        controller: _promptController,
        isModelReplying: _isModelReplying,
        onSend: () => _handleSubmitted(_promptController.text),
        onStop: _stopModelGeneration,
      );
    }
  }

  void _showModelInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Model Information'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(modelName != null
                    ? 'Current Model: $modelName'
                    : 'No model loaded.'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background image
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/custom_background.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          // White overlay with reduced opacity
          Container(
            color: Colors.white.withOpacity(0.7),
          ),
          // Main content of the app
          GestureDetector(
            onTap: _closeSidebarOnTap,
            child: _buildMainContent(),
          ),
          ChatSidebarWidget(
            isVisible: _isSidebarVisible,
            hasModel: modelFile != null,
            modelFile: modelFile,
            onNewChat: _saveCurrentChat,
            onEjectModel: _ejectModel,
            onChatSelected: _loadSelectedChat,
            onToggleSidebar: _toggleSidebar,
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    return SafeArea(
      child: Column(
        children: [
          _buildAppBar(),
          modelFile == null
              ? VideoFeedWidget(onVideoTap: _playVideo)
              : SizedBox.shrink(),
          Expanded(child: _buildMessageList()),
          GestureDetector(
            onTap: _closeSidebarOnTap,
            child: _buildInputOrLoadModel(),
          ),
        ],
      ),
    );
  }
} 