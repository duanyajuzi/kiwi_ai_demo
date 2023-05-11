import 'package:uuid/uuid.dart';

import 'message.dart';

class Conversation {
  final String id;
  final String title;
  List<Message> messages;

  Conversation({required this.id, required this.title, required this.messages});

  factory Conversation.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      // 如果 json 为 null，则返回空 Conversation 对象
      return Conversation(id:Uuid().v4(),title: 'New Chat',messages: []);
    }

    final id = json['id'] ?? '';
    final title = json['title'] ?? '';
    final messagesJson = json['messages'] ?? [];

    final messages = List<Message>.from(
        messagesJson.map((messageJson) => Message.fromJson(messageJson))
    );

    return Conversation(
      id: id,
      title: title,
      messages: messages,
    );
  }

  Map<String, dynamic> toJson() {
    List<Map<String, dynamic>> messagesJson = messages.map((message) => message.toJson()).toList();

    return {
      'id': id,
      'title': title,
      'messages': messagesJson,
    };
  }

}
