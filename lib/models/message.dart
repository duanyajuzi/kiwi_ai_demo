class Message {
  final String id;
  final String text;
  final bool isUserMessage;
  DateTime? timestamp;

  Message({required this.id, required this.text, required this.isUserMessage,this.timestamp});

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'],
      text: json['text'],
      isUserMessage: json['isUserMessage'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'isUserMessage': isUserMessage,
    };
  }
}
