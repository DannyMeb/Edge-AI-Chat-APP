import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:convert';
import 'package:falcon_chat/core/system_usage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../core/benchmark_service.dart';
import '../widgets/compact_benchmark_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
// import 'package:carousel_slider/carousel_slider.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class MobileHomePage extends StatefulWidget {
  const MobileHomePage({super.key});

  @override
  State<MobileHomePage> createState() => _MobileHomePageState();
}

class _MobileHomePageState extends State<MobileHomePage> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _promptController = TextEditingController();
  final ScrollController _mainScrollController = ScrollController();
  final PageController _feedPageController =
      PageController(viewportFraction: 0.8);
  int _currentPage = 0;
  File? modelFile;
  String? modelName;
  List<Message> messages = [];
  bool _isModelReplying = false;

  ReceivePort? _modelReceivePort;
  Isolate? _modelIsolate;

  bool _isSidebarVisible = false;

  @override
  void initState() {
    super.initState();
    _feedPageController.addListener(() {
      int next = _feedPageController.page!.round();
      if (_currentPage != next) {
        setState(() {
          _currentPage = next;
        });
      }
    });
  }

  @override
  void dispose() {
    _unLoadModel();
    _promptController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  final List<Map<String, String>> videoData = [
    {
      'id': '9MArp9H2YCM',
      'title': 'Introducing Falcon 180B: The Worlds Most Powerful Open LLM!',
      'thumbnail': 'https://img.youtube.com/vi/9MArp9H2YCM/hqdefault.jpg',
    },
    {
      'id': '_8MlpZkHKaI',
      'title': 'Making AI accessible: AI for All',
      'thumbnail': 'https://img.youtube.com/vi/_8MlpZkHKaI/hqdefault.jpg',
    },
    {
      'id': '5MN9u9KiwIc',
      'title': 'UAE is building an open source GenAI model called Falcon',
      'thumbnail': 'https://img.youtube.com/vi/5MN9u9KiwIc/hqdefault.jpg',
    },
    {
      'id': '24nRqjRJcXg',
      'title': 'Falcon 40B our game-changing AI model is now open source',
      'thumbnail': 'https://img.youtube.com/vi/24nRqjRJcXg/hqdefault.jpg',
    },
  ];

  Widget _buildFeed() {
    return Container(
      height: 250,
      child: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _feedPageController,
              itemCount: videoData.length,
              scrollDirection: Axis.horizontal,
              itemBuilder: (context, index) {
                return _buildVideoCard(videoData[index], index);
              },
            ),
          ),
          SizedBox(height: 10),
          _buildPageIndicator(),
        ],
      ),
    );
  }

  Widget _buildVideoCard(Map<String, String> video, int index) {
    return AnimatedBuilder(
      animation: _feedPageController,
      builder: (context, child) {
        double value = 1.0;
        if (_feedPageController.position.haveDimensions) {
          value = _feedPageController.page! - index;
          value = (1 - (value.abs() * 0.3)).clamp(0.0, 1.0);
        }
        return Center(
          child: SizedBox(
            height: Curves.easeInOut.transform(value) * 200,
            width: Curves.easeInOut.transform(value) * 350,
            child: child,
          ),
        );
      },
      child: GestureDetector(
        onTap: () => _playVideo(video['id']!),
        child: Card(
          elevation: 4,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              image: DecorationImage(
                image: NetworkImage(video['thumbnail']!),
                fit: BoxFit.cover,
              ),
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      video['title']!,
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPageIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List<Widget>.generate(videoData.length, (int index) {
        return Container(
          width: 8.0,
          height: 8.0,
          margin: EdgeInsets.symmetric(horizontal: 4.0),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _currentPage == index ? Colors.deepPurple : Colors.grey,
          ),
        );
      }),
    );
  }

  void _playVideo(String videoId) {
    YoutubePlayerController _controller = YoutubePlayerController(
      initialVideoId: videoId,
      flags: YoutubePlayerFlags(
        autoPlay: true,
        mute: false,
      ),
    );

    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => Scaffold(
        appBar: AppBar(
          title: Text('YouTube Video'),
          backgroundColor: Colors.black,
        ),
        backgroundColor: Colors.black,
        body: Center(
          child: Container(
            width: MediaQuery.of(context).size.width * 0.95,
            height: MediaQuery.of(context).size.height * 0.95,
            child: YoutubePlayer(
              controller: _controller,
              showVideoProgressIndicator: true,
              progressIndicatorColor: Colors.red,
              progressColors: ProgressBarColors(
                playedColor: Colors.red,
                handleColor: Colors.redAccent,
              ),
              onReady: () {
                print('Player is ready.');
              },
              onEnded: (data) {
                print('Video ended.');
              },
              bottomActions: [
                CurrentPosition(),
                ProgressBar(isExpanded: true),
                RemainingDuration(),
                FullScreenButton(),
              ],
            ),
          ),
        ),
      ),
    ));
  }

  void _initModelIsolate(String userPrompt) async {
    _modelReceivePort = ReceivePort();
    _isModelReplying = true;
    _modelIsolate = await Isolate.spawn(fetchModelResponse,
        [_modelReceivePort!.sendPort, modelFile, userPrompt]);
    messages
        .add(Message(content: '', role: 'AI', avatar: 'assets/ai_avatar.png'));
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

  Future<void> _loadModel() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();

    if (result != null) {
      String? filePath = result.files.single.path;

      if (filePath != null && filePath.endsWith('.gguf')) {
        setState(() {
          modelFile = File(filePath);
          modelName = result.files.single.name;
        });
      } else {
        _showInvalidModelDialog(context);
      }
    }
  }

  void _showInvalidModelDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Invalid Model File'),
          content: Text('Please load a valid .gguf model file.'),
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

  void _toggleSidebar() {
    setState(() {
      _isSidebarVisible = !_isSidebarVisible;
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

  void _closeSidebarOnTap() {
    if (_isSidebarVisible) {
      setState(() {
        _isSidebarVisible = false;
      });
    }
  }

  void _ejectModel() {
    setState(() {
      _unLoadModel();
      messages.clear();
      _isSidebarVisible = false;
    });
  }

  void _saveCurrentChat() async {
    if (messages.isEmpty ||
        !messages.any((msg) => msg.content.trim().isNotEmpty)) {
      return; // Do not save empty chats
    }

    final prefs = await SharedPreferences.getInstance();
    List<String> chatHistory = prefs.getStringList('chatHistory') ?? [];

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
      await prefs.setStringList('chatHistory', chatHistory);
      await prefs.setString(chatName, jsonEncode(serializedMessages));
    }

    // Clear current messages for a fresh start
    messages.clear();
    setState(() {});
  }

  Widget _buildNewChatButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
      child: ElevatedButton.icon(
        onPressed: () {
          _saveCurrentChat(); // Save the current chat before clearing
        },
        icon: Icon(Icons.add, color: Colors.white),
        label: Text(
          'New Chat',
          style: TextStyle(color: Colors.white),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.deepPurple,
        ),
      ),
    );
  }

  void _loadSelectedChat(String chatName) async {
    // Stop the model generation if it's currently generating content
    if (_isModelReplying) {
      _stopModelGeneration();
    }

    // Save the current chat before switching to the selected one
    if (messages.isNotEmpty) {
      _saveCurrentChat();
    }

    final prefs = await SharedPreferences.getInstance();
    String? chatData = prefs.getString(chatName);

    if (chatData != null) {
      List<dynamic> deserializedMessages = jsonDecode(chatData);

      setState(() {
        // Load the exact conversation tied to this specific chat
        messages = deserializedMessages
            .map((message) => Message.withTimestamp(
                content: message['content'],
                role: message['role'],
                avatar: message['avatar'],
                timestamp: DateTime.parse(message['timestamp'])))
            .toList();
      });
    }
  }

  Widget _buildChatHistory() {
    return FutureBuilder<List<String>>(
      future: SharedPreferences.getInstance()
          .then((prefs) => prefs.getStringList('chatHistory') ?? []),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator();
        }

        List<String> chats = snapshot.data ?? [];

        // Sort chats from new to old by extracting the timestamp
        chats.sort((a, b) {
          int aTimestamp = int.tryParse(a.split('_').last) ?? 0;
          int bTimestamp = int.tryParse(b.split('_').last) ?? 0;
          return bTimestamp.compareTo(aTimestamp); // Sort new to old
        });

        return ListView.builder(
          shrinkWrap: true,
          itemCount: chats.length,
          reverse: true, // This ensures the list starts from the newest
          itemBuilder: (context, index) {
            String chatName = chats[index];
            return ListTile(
              title: Text(
                chatName, // Display unique chat name
                style: TextStyle(color: Colors.white),
              ),
              trailing: SizedBox(
                width: 40, // Adjust the width of the trailing widget
                child: PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert, color: Colors.white),
                  onSelected: (String result) {
                    if (result == 'delete') {
                      _deleteChat(chatName);
                    } else if (result == 'rename') {
                      _renameChatDialog(chatName);
                    }
                  },
                  itemBuilder: (BuildContext context) =>
                      <PopupMenuEntry<String>>[
                    const PopupMenuItem<String>(
                      value: 'delete',
                      child: Text('Delete'),
                    ),
                    const PopupMenuItem<String>(
                      value: 'rename',
                      child: Text('Rename'),
                    ),
                  ],
                ),
              ),
              onTap: () {
                _loadSelectedChat(chatName); // Load the specific chat
              },
            );
          },
        );
      },
    );
  }

  void _deleteChat(String chatName) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> chatHistory = prefs.getStringList('chatHistory') ?? [];

    // Remove the chat from the list
    chatHistory.remove(chatName);
    await prefs.setStringList('chatHistory', chatHistory);

    // Remove the chat data from SharedPreferences
    await prefs.remove(chatName);

    setState(() {}); // Refresh UI
  }

  void _renameChatDialog(String oldChatName) {
    TextEditingController renameController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Rename Chat'),
          content: TextField(
            controller: renameController,
            decoration: InputDecoration(hintText: 'Enter new chat name'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog without action
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                _renameChat(oldChatName, renameController.text);
                Navigator.of(context).pop(); // Close dialog after renaming
              },
              child: Text('Rename'),
            ),
          ],
        );
      },
    );
  }

  void _renameChat(String oldChatName, String newChatName) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> chatHistory = prefs.getStringList('chatHistory') ?? [];

    if (newChatName.isNotEmpty && !chatHistory.contains(newChatName)) {
      // Get the chat data for the old name
      String? chatData = prefs.getString(oldChatName);

      // Update the chat history list with the new name
      int index = chatHistory.indexOf(oldChatName);
      if (index != -1) {
        chatHistory[index] = newChatName;
      }

      // Save the updated chat history list
      await prefs.setStringList('chatHistory', chatHistory);

      // Save the chat data under the new name
      if (chatData != null) {
        await prefs.setString(newChatName, chatData);
      }

      // Remove the old chat name and its associated data
      await prefs.remove(oldChatName);

      setState(() {}); // Refresh UI
    }
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
                fit: BoxFit.cover, // Ensures the image covers the entire screen
              ),
            ),
          ),
          // White overlay with reduced opacity
          Container(
            color: Colors.white
                .withOpacity(0.7), // 50% opacity for the white overlay
          ),
          // Main content of the app
          GestureDetector(
            onTap: _closeSidebarOnTap,
            child: _buildMainContent(),
          ),
          _buildFancySidebar(),
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
              ? _buildFeed() // Only show feed when no model is loaded
              : SizedBox.shrink(), // Hide the feed when a model is loaded
          Expanded(child: _buildMessageList()),
          GestureDetector(
            onTap: _closeSidebarOnTap,
            child: _buildInputOrLoadModel(),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Conditionally display notification or title based on model status
          modelFile == null
              ? Stack(
                  children: [
                    IconButton(
                      icon: Icon(Icons.notifications, color: Colors.purple),
                      onPressed: () {
                        // Handle notification icon press here
                      },
                    ),
                    Positioned(
                      // Position the badge
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
                          '2', // Number of notifications
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                )
              : Row(
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
                ),
          // Handle settings dropdown or sidebar toggle based on model loading
          modelFile == null ? _buildSettingsDropdown() : _buildSidebarToggle(),
        ],
      ),
    );
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

  Widget _buildSettingsDropdown() {
    return PopupMenuButton<String>(
      icon:
          Icon(Icons.more_vert, color: const Color.fromARGB(255, 151, 0, 151)),
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
    // Check if there are no messages yet and the model is loaded
    if (messages.isEmpty && modelFile != null) {
      return Center(
        child: _buildHintsOrPrompt(),
      );
    } else {
      // Normal message list rendering
      return ListView.builder(
        controller: _scrollController,
        itemCount: messages.length,
        itemBuilder: (context, index) {
          final message = messages[index];
          return _buildMessageBubble(message);
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
        onPressed: () {
          _handleHintSelection(hintText);
        },
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

  void _handleHintSelection(String hintText) {
    // Add the hint to the messages as if the user typed it
    setState(() {
      messages.add(Message(
          content: hintText, role: 'user', avatar: 'assets/user_avatar.png'));
      _promptController.clear(); // Clear the input field
    });
    _scrollToBottom(); // Scroll to the bottom of the chat list

    // Automatically start a chat with the selected hint
    _initModelIsolate(hintText);
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

  Widget _buildInputOrLoadModel() {
    if (modelFile == null) {
      return Center(
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center, // Vertically centers the whole column
          crossAxisAlignment:
              CrossAxisAlignment.center, // Horizontally centers content
          mainAxisSize:
              MainAxisSize.min, // Ensures the column takes up minimum space
          children: [
            // Display the logo at the center of the screen
            Image.asset(
              'assets/logo.png',
              width: 200, // Set the desired width for the logo
              height: 150, // Set the desired height for the logo
            ),
            SizedBox(height: 20), // Space between logo and text
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
            SizedBox(height: 20), // Space between the button and text
            const Text(
              'Please load a model to start chatting.',
              style: TextStyle(fontSize: 12, color: Colors.black),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    } else {
      return _buildInputField();
    }
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
          Icon(Icons.sentiment_satisfied, color: Colors.grey),
          SizedBox(width: 8),
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
            icon: Icon(
              _isModelReplying ? Icons.stop : Icons.send,
              color: _isModelReplying ? Colors.red : Colors.purple,
            ),
            onPressed: _isModelReplying
                ? _stopModelGeneration
                : () => _handleSubmitted(_promptController.text),
          ),
        ],
      ),
    );
  }

  void _handleSubmitted(String text) {
    if (text.isEmpty || modelFile == null) return;
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

Widget _buildFancySidebar() {
    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      width: _isSidebarVisible ? 250 : 0,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.deepPurple.shade700,
            Colors.deepPurple.shade300,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            spreadRadius: 2,
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(15),
          bottomRight: Radius.circular(15),
        ),
      ),
      child: _isSidebarVisible
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Edge AI Chat',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Row(
                        children: [
                          Stack(
                            children: [
                              IconButton(
                                icon: Icon(Icons.notifications,
                                    color: Colors.white),
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
                          ),
                          IconButton(
                            icon: Icon(Icons.settings, color: Colors.white),
                            onPressed: () {
                              _showSettingsMenu(context);
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Divider(color: Colors.white),
                _buildNewChatButton(),
                // Add the benchmark widget here, after the new chat button
                if (modelFile != null) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: CompactBenchmarkWidget(
                      modelFile: modelFile!,
                      isSidebar: true,
                    ),
                  ),
                ],
                Expanded(
                  child: SingleChildScrollView(child: _buildChatHistory()),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: ElevatedButton(
                    onPressed: _ejectModel,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                    ),
                    child: Text(
                      'Eject Model',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ),
                SizedBox(height: 20),
              ],
            )
          : null,
    );
  }

// Function to show the settings menu
  void _showSettingsMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          color: Colors.white,
          child: Wrap(
            children: [
              ListTile(
                leading: Icon(Icons.palette),
                title: Text('Appearance'),
                onTap: () {
                  // Handle appearance settings
                },
              ),
              ListTile(
                leading: Icon(Icons.account_circle),
                title: Text('Account'),
                onTap: () {
                  // Handle account settings
                },
              ),
              ListTile(
                leading: Icon(Icons.help_outline),
                title: Text('Help'),
                onTap: () {
                  // Handle help
                },
              ),
              ListTile(
                leading: Icon(Icons.info_outline),
                title: Text('Info'),
                onTap: () {
                  // Handle info
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSidebarItem(IconData icon, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.white),
          SizedBox(width: 16),
          Text(
            title,
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
        ],
      ),
    );
  }
}

class Message {
  String content;
  final String role;
  final String avatar;
  final DateTime timestamp;

  // Constructor with default timestamp
  Message({
    required this.content,
    required this.role,
    required this.avatar,
  }) : timestamp = DateTime.now(); // Automatically assign current time

  // Constructor for deserializing from JSON
  Message.withTimestamp({
    required this.content,
    required this.role,
    required this.avatar,
    required this.timestamp,
  });

  // Serialize the object to JSON
  Map<String, dynamic> toJson() => {
        'content': content,
        'role': role,
        'avatar': avatar,
        'timestamp': timestamp.toIso8601String(),
      };

  // Deserialize the object from JSON
  factory Message.fromJson(Map<String, dynamic> json) {
    return Message.withTimestamp(
      content: json['content'],
      role: json['role'],
      avatar: json['avatar'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}
