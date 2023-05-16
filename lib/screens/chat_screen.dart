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
  StreamController<Message> _messageStreamController =
      StreamController<Message>();
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _conversation = widget.conversation;
    for (Message message in _conversation!.messages) {
      _messageStreamController.add(message);
    }
  }

  void _sendMessage(String text) async {
    if (text.trim().isEmpty) {
      return;
    }
    setState(() {
      isLoading = true;
    });
    Message message = Message(
        id: Uuid().v4(),
        text: text,
        isUserMessage: true,
        timestamp: DateTime.now());
    _messageStreamController.add(message);
    try {
      await for (final response in _chatGptService.getResponseStream(text)) {
        if (response.isNotEmpty) {
          final botMessage = Message(
            id: Uuid().v4(),
            text: response,
            isUserMessage: false,
            timestamp: DateTime.now(),
          );
          // Add the bot's message to the stream.
          _messageStreamController.add(botMessage);
          await Future.delayed(Duration(milliseconds: 500)); // 添加延迟
        }
      }
    } catch (e) {
      print(e);
    }

    setState(() {
      isLoading = false;
    });

    Conversation updatedConversation = _conversation!;
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
                    builder: (BuildContext context,
                        AsyncSnapshot<Message> snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      } else if (snapshot.hasError) {
                        return Text('Error: ${snapshot.error}');
                      } else if (snapshot.hasData) {
                        final message = snapshot.data!;
                        _conversation?.messages.add(message);
                        return ListView.separated(
                          separatorBuilder: (BuildContext context, int index) =>
                              Divider(),
                          itemCount: _conversation?.messages.length ?? 0,
                          itemBuilder: (BuildContext context, int index) {
                            Message message = _conversation!.messages[index];
                            return Container(
                              alignment: message.isUserMessage
                                  ? Alignment.centerRight
                                  : Alignment.centerLeft,
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                margin: const EdgeInsets.symmetric(
                                    vertical: 5, horizontal: 10),
                                decoration: BoxDecoration(
                                  color: message.isUserMessage
                                      ? Colors.blue
                                      : Colors.grey[300],
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: MarkdownBody(
                                  data: message.text,
                                  styleSheet: MarkdownStyleSheet.fromTheme(
                                      Theme.of(context)),
                                ),
                              ),
                            );
                          },
                        );
                      } else {
                        return const Text('No messages');
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
                        onPressed: () async {
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
