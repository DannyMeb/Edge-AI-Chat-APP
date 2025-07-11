import 'package:flutter/material.dart';
import 'dart:io';
import '../services/chat_service.dart';
import '../widgets/compact_benchmark_widget.dart';

class ChatSidebarWidget extends StatefulWidget {
  final bool isVisible;
  final bool hasModel;
  final File? modelFile;
  final VoidCallback onNewChat;
  final VoidCallback onEjectModel;
  final Function(String) onChatSelected;
  final VoidCallback onToggleSidebar;

  const ChatSidebarWidget({
    Key? key,
    required this.isVisible,
    required this.hasModel,
    this.modelFile,
    required this.onNewChat,
    required this.onEjectModel,
    required this.onChatSelected,
    required this.onToggleSidebar,
  }) : super(key: key);

  @override
  State<ChatSidebarWidget> createState() => _ChatSidebarWidgetState();
}

class _ChatSidebarWidgetState extends State<ChatSidebarWidget> {
  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      width: widget.isVisible ? 250 : 0,
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
      child: widget.isVisible
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                Divider(color: Colors.white),
                _buildNewChatButton(),
                if (widget.hasModel && widget.modelFile != null) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: CompactBenchmarkWidget(
                      modelFile: widget.modelFile!,
                      isSidebar: true,
                    ),
                  ),
                ],
                Expanded(
                  child: SingleChildScrollView(child: _buildChatHistory()),
                ),
                _buildEjectButton(),
                SizedBox(height: 20),
              ],
            )
          : null,
    );
  }

  Widget _buildHeader() {
    return Padding(
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
                    icon: Icon(Icons.notifications, color: Colors.white),
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
    );
  }

  Widget _buildNewChatButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
      child: ElevatedButton.icon(
        onPressed: widget.onNewChat,
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

  Widget _buildEjectButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: ElevatedButton(
        onPressed: widget.onEjectModel,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
        ),
        child: Text(
          'Eject Model',
          style: TextStyle(color: Colors.red),
        ),
      ),
    );
  }

  Widget _buildChatHistory() {
    return FutureBuilder<List<String>>(
      future: ChatService.getChatHistory(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator();
        }

        List<String> chats = snapshot.data ?? [];

        return ListView.builder(
          shrinkWrap: true,
          itemCount: chats.length,
          reverse: true,
          itemBuilder: (context, index) {
            String chatName = chats[index];
            return ListTile(
              title: Text(
                chatName,
                style: TextStyle(color: Colors.white),
              ),
              trailing: SizedBox(
                width: 40,
                child: PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert, color: Colors.white),
                  onSelected: (String result) {
                    if (result == 'delete') {
                      _deleteChat(chatName);
                    } else if (result == 'rename') {
                      _renameChatDialog(chatName);
                    }
                  },
                  itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
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
                widget.onChatSelected(chatName);
              },
            );
          },
        );
      },
    );
  }

  void _deleteChat(String chatName) async {
    await ChatService.deleteChat(chatName);
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
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                bool success = await ChatService.renameChat(oldChatName, renameController.text);
                if (success) {
                  setState(() {}); // Refresh UI
                }
                Navigator.of(context).pop();
              },
              child: Text('Rename'),
            ),
          ],
        );
      },
    );
  }

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
} 