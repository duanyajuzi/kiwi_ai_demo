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
  late Stream<List<Conversation>> _conversationsStream;

  @override
  void initState() {
    super.initState();
    _conversationsStream = LocalStorageService.conversationsStream;
  }

  Future<void> _navigateToChatScreen(BuildContext context, Conversation conversation) async {
    Conversation updatedConversation = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(conversation: conversation),
      ),
    );
    if (updatedConversation != null) {
      if (LocalStorageService.getConversation(updatedConversation.id) != null) {
        LocalStorageService.updateConversation(updatedConversation);
      } else if(updatedConversation.messages.isNotEmpty) {
        LocalStorageService.saveConversation(updatedConversation);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('ChatGPT Flutter'),
      ),
      body: StreamBuilder<List<Conversation>>(
        stream: _conversationsStream,
        builder: (BuildContext context, AsyncSnapshot<List<Conversation>> snapshot) {
          if (!snapshot.hasData) {
            return Center(
              child: CircularProgressIndicator(),
            );
          }

          List<Conversation> conversations = snapshot.data!;
          return ListView.builder(
            itemCount: conversations.length,
            itemBuilder: (context, index) {
              Conversation conversation = conversations[index];
              return ListTile(
                title: Text(conversation.title),
                subtitle: Text(conversation.messages.isNotEmpty ? conversation.messages.last.text : ''),
                onTap: () => _navigateToChatScreen(context, conversation),
              );
            },
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
