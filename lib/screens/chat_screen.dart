import 'package:flutter/material.dart';
import 'package:kiwi/models/conversation.dart';
import 'package:kiwi/models/message.dart';
import 'package:kiwi/services/chatgpt_service.dart';
import 'package:kiwi/services/local_storage_service.dart';
import 'package:uuid/uuid.dart';

class ChatScreen extends StatefulWidget {
  final Conversation conversation;
  final void Function(Conversation)? onConversationUpdated;

  ChatScreen({required this.conversation, this.onConversationUpdated});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _textEditingController = TextEditingController();
  final ChatGptService _chatGptService = ChatGptService();
  final LocalStorageService _localStorageService = LocalStorageService();
  late String _conversationId;
  // List<Message> _messages = [];
  Conversation? _conversation;

  @override
  void initState() {
    super.initState();
    _conversation = widget.conversation;
    // _conversationId = widget.conversation.id ?? Uuid().v4();
    // _messages = widget.conversation?.messages??[];
  }

  void _sendMessage(String text) async {
    if (text.trim().isEmpty) {
      return;
    }

    Message message = Message(
        id: Uuid().v4(),
        text: text,
        isUserMessage: true,
        timestamp: DateTime.now());
    setState(() {
      _conversation?.messages.add(message);
    });

    String response = await _chatGptService.getResponse(text);
    if (response.isNotEmpty) {
      Message botMessage = Message(
          id: Uuid().v4(),
          text: response,
          isUserMessage: false,
          timestamp: DateTime.now());
      setState(() {
        _conversation?.messages.add(botMessage);
      });
    }

    Conversation updatedConversation = _conversation!;
    LocalStorageService.saveConversation(updatedConversation);

    if (widget.onConversationUpdated != null) {
      widget.onConversationUpdated!(updatedConversation);
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        onWillPop: () async {
          Navigator.pop(context, _conversation);
          return true;
        },
        child: Scaffold(
          appBar: AppBar(
            title: Text(widget.conversation.title),
          ),
          body: Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: _conversation?.messages.length ?? 0,
                  itemBuilder: (BuildContext context, int index) {
                    Message message = _conversation!.messages[index];
                    return Container(
                      alignment: message.isUserMessage
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        padding: EdgeInsets.all(10),
                        margin:
                            EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                        decoration: BoxDecoration(
                          color: message.isUserMessage
                              ? Colors.blue
                              : Colors.grey[300],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          message.text,
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    );
                  },
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _textEditingController,
                        decoration: InputDecoration(
                          hintText: 'Type a message',
                        ),
                        onSubmitted: (String text) {
                          _sendMessage(text);
                          _textEditingController.clear();
                        },
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.send),
                      onPressed: () {
                        _sendMessage(_textEditingController.text);
                        _textEditingController.clear();
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ));
  }
}
