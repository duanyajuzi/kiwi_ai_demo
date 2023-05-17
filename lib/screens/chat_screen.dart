import 'dart:async';

import 'package:flutter/material.dart';
import 'package:kiwi/models/conversation.dart';
import 'package:kiwi/models/message.dart';
import 'package:kiwi/services/api_chatgpt_service.dart';
import 'package:kiwi/widgets/chat_widget.dart';
import 'package:kiwi/widgets/text_widget.dart';

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
  final StreamController<Message> _messageStreamController =
      StreamController<Message>();

  //聚焦底部
  late ScrollController _scrollController;
  late FocusNode _focusNode;
  bool isLoading = false;

  @override
  void initState() {
    _scrollController = ScrollController();
    _conversation = widget.conversation;
    _focusNode = FocusNode();
    for (Message message in _conversation!.messages) {
      _messageStreamController.add(message);
    }
    super.initState();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _textEditingController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _sendMessage(String text) async {
    if (text.trim().isEmpty) {
      return;
    }
    setState(() {
      isLoading = true;
    });
    Message message = Message(
        chatIndex: 0,
        text: text,
        isUserMessage: true,
        timestamp: DateTime.now());
    _messageStreamController.add(message);
    try {
      await for (final response in _chatGptService.getResponseStream(text)) {
        if (response.isNotEmpty) {
          final botMessage = Message(
            chatIndex: 1,
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

  static Future<void> showModalSheet(BuildContext context) async {
    await showModalBottomSheet(
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        )),
        context: context,
        builder: (context) {
          return Padding(
              padding: EdgeInsets.all(30),
              child: Row(
                children: [
                  const Flexible(
                      child: TextWidget(
                    label: "选择模型",
                    fontSize: 16,
                    color: Colors.black,
                  ))
                ],
              ));
        });
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
            actions: [
              IconButton(
                onPressed: () async {
                  showModalSheet(context);
                },
                icon: const Icon(Icons.auto_awesome_mosaic_outlined),
              )
            ],
          ),
          body: SafeArea(
            child: Column(
              children: [
                Flexible(
                    child: ListView.builder(
                        controller: _scrollController,
                        itemCount: _conversation!.messages.length,
                        itemBuilder: (context, index) {
                          final Message msg = _conversation!.messages[index];
                          return ChatWidget(msg: msg.text, chatIndex: index);
                        })),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          focusNode: _focusNode,
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
                          await sendMessage();
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

  //滚动到底部
  void scrollListToEnd() {
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  Future<void> sendMessage() async {
    try {
      String msg= _textEditingController.text;
      setState(() {
        isLoading = true;
        _conversation?.messages.add(Message(
            chatIndex: 0,
            text: msg,
            isUserMessage: true));
        _textEditingController.clear();
        _focusNode.unfocus();
      });
      final list = await ChatGptService.sendMessage(
          prompt: msg, modelId: "gpt-3.5-turbo");
      _conversation?.messages.addAll(list);
      setState(() {});
    } catch (e) {
      print(e);
    } finally {
      setState(() {
        scrollListToEnd();
        isLoading = false;
      });
    }
  }
}
