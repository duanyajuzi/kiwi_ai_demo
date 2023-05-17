class Message {
  final int chatIndex;
  final String text;
  final bool isUserMessage;
  DateTime? timestamp;

  Message({required this.chatIndex, required this.text, required this.isUserMessage,this.timestamp});

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      chatIndex: json['chatIndex'],
      text: json['text'],
      isUserMessage: json['isUserMessage'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'chatIndex': chatIndex,
      'text': text,
      'isUserMessage': isUserMessage,
    };
  }
}
