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
    Conversation updatedConversation = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(conversation: conversation),
      ),
    );
    if (updatedConversation != null) {
      //如果对话id已经存在，则更新对话，否则添加对话
      if (_conversations.any((c) => c.id == updatedConversation.id)) {
        _updateConversation(updatedConversation);
      } else if(updatedConversation.messages.isNotEmpty) {
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
        title: Text('KIWI AI'),
      ),
      body: ListView.separated(
        itemCount: _conversations.length,
        separatorBuilder: (context, index) => Divider(),
        itemBuilder: (context, index) {
          Conversation conversation = _conversations[index];
          return InkWell(
            onTap: () => _navigateToChatScreen(context, conversation),
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
              child: Row(
                children:[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          conversation.title,
                          style: const TextStyle(
                            fontSize: 16.0,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 4.0),
                        Text(
                          conversation.messages.isNotEmpty ? conversation.messages.last.text : '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14.0,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios, size: 16.0, color: Colors.grey[600]),
                ],
              ),
            ),
          );
          // return ListTile(
          //   title: Text(conversation.title),
          //   subtitle: Text(
          //     conversation.messages.isNotEmpty ? conversation.messages.last.text : '',
          //     maxLines: 1, // 只显示 2 行文本
          //     overflow: TextOverflow.ellipsis, // 超出 2 行时，使用省略号来表示
          //   ),
          //   onTap: () => _navigateToChatScreen(context, conversation),
          // );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToChatScreen(context, Conversation( id: Uuid().v4(), title: 'New Chat', messages: [])),
        child: Icon(Icons.add),
      ),
    );
  }
}
