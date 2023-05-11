import 'message.dart';

class Conversation {
  final String id;
  final String title;
  List<Message> messages;

  Conversation({required this.id, required this.title, required this.messages});

  factory Conversation.fromJson(Map<String, dynamic> json) {
    List<dynamic> messagesJson = json['messages'];
    List<Message> messages = messagesJson.map((messageJson) => Message.fromJson(messageJson)).toList();

    return Conversation(
      id: json['id'],
      title: json['title'],
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
