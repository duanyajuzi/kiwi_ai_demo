import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:kiwi/models/conversation.dart';
import 'package:kiwi/models/message.dart';
import 'package:kiwi/services/chatgpt_service.dart';
import 'package:uuid/uuid.dart';

class ChatScreen extends StatefulWidget {
  final Conversation conversation;
  final void Function(Conversation)? onConversationUpdated;

  ChatScreen({required this.conversation, this.onConversationUpdated});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  Conversation? _conversation;

  final ChatGptService _chatGptService = ChatGptService();
  final TextEditingController _textEditingController = TextEditingController();
  StreamController<Message> _messageStreamController = StreamController<Message>();
  bool isLoading = false;
  @override
  void initState() {
    super.initState();
    _conversation = widget.conversation;
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
    // setState(() {
    //   _conversation?.messages.add(message);
    // });
    // Add the user's message to the stream.
    _messageStreamController.add(message);

    // String response = await _chatGptService.getResponse(text);
    // if (response.isNotEmpty) {
    //   Message botMessage = Message(
    //       id: Uuid().v4(),
    //       text: response,
    //       isUserMessage: false,
    //       timestamp: DateTime.now());
    //   // Add the bot's message to the stream.
    //   _messageStreamController.add(botMessage);
    //   // setState(() {
    //   //   _conversation?.messages.add(botMessage);
    //   // });
    // }
    try {
      await for (final response in _chatGptService.getResponseStream(text)) {
        if (response.isNotEmpty) {
          final botMessage = Message(
            id: const Uuid().v4(),
            text: response,
            isUserMessage: false,
            timestamp: DateTime.now(),
          );

          // Add the bot's message to the stream.
          _messageStreamController.add(botMessage);
        }
      }
    } catch (e) {
      print(e);
    }

    Conversation updatedConversation = _conversation!;
    // LocalStorageService.saveConversation(updatedConversation);
    // Enable the send button.
    //     setState(() {
    //       isLoading = false;
    //     });
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
          body: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: StreamBuilder<Message>(
                    stream: _messageStreamController.stream,
                    builder:(BuildContext context, AsyncSnapshot<Message> snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(
                          child: CircularProgressIndicator(),
                        );
                      }else{
                        _conversation?.messages.add(snapshot.data!);
                        return ListView.builder(
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
                                child: MarkdownBody(
                                  data: message.text,
                                  styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)),
                                ),
                              ),
                            );
                          },
                        );
                      }
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
                        onPressed: () async{
                          setState(() {
                            isLoading = true;
                          });
                          _sendMessage(_textEditingController.text);
                          setState(() {
                            isLoading = false;
                          });
                          _textEditingController.clear();
                        },

                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

        ));
  }
}
