import 'package:flutter/material.dart';
import 'package:kiwi/models/conversation.dart';
import 'package:kiwi/screens/chat_screen.dart';
import 'package:kiwi/services/local_storage_service.dart';
import 'package:uuid/uuid.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Conversation> _conversations = [];

  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  void _loadConversations() async {
    List<Conversation> conversations = await LocalStorageService.loadConversations();
    setState(() {
      _conversations = conversations;
    });
  }

  void _addConversation(Conversation conversation) async {
    await LocalStorageService.saveConversation(conversation);
    setState(() {
      _conversations.add(conversation);
    });
  }

  void _updateConversation(Conversation conversation) async {
    await LocalStorageService.updateConversation(conversation);
    setState(() {
      int index = _conversations.indexWhere((c) => c.id == conversation.id);
      _conversations[index] = conversation;
    });
  }

  void _deleteConversation(Conversation conversation) async {
    await LocalStorageService.deleteConversation(conversation.id);
    setState(() {
      _conversations.removeWhere((c) => c.id == conversation.id);
    });
  }

  Future<void> _navigateToChatScreen(BuildContext context, Conversation conversation) async {
    print("conversation: $conversation ");
    Conversation updatedConversation = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(conversation: conversation),
      ),
    );
    if (updatedConversation != null) {
      if (_conversations.any((c) => c.id == updatedConversation.id)) {
        _updateConversation(updatedConversation);
      } else {
        _addConversation(updatedConversation);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    //空对话，uuid和 New Chat
    // Conversation emptyConversation = Conversation( id: DateTime.now().toString(), title: 'New Chat', messages: []);
    return Scaffold(
      appBar: AppBar(
        title: Text('ChatGPT Flutter'),
      ),
      body: ListView.builder(
        itemCount: _conversations.length,
        itemBuilder: (context, index) {
          Conversation conversation = _conversations[index];
          return ListTile(
            title: Text(conversation.title),
              subtitle: Text(conversation.messages.isNotEmpty ? conversation.messages.last.text : ''),
            onTap: () => _navigateToChatScreen(context, conversation),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
      onPressed: () => _navigateToChatScreen(context, Conversation( id: Uuid().v4(), title: 'New Chat', messages: [])),
        child: Icon(Icons.add),
      ),
    );
  }
}

