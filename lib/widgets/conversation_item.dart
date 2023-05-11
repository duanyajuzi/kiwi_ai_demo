import 'package:flutter/material.dart';
import 'package:kiwi/models/conversation.dart';
import 'package:kiwi/screens/chat_screen.dart';

class ConversationItem extends StatelessWidget {
  final Conversation conversation;

  ConversationItem({required this.conversation, required void Function() onTap, required void Function() onDelete});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(conversation: conversation, onConversationUpdated: (Conversation conversation) {  },),
          ),
        );
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundImage: AssetImage('assets/images/avatar.png'),
            ),
            SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    conversation.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    conversation.messages.isNotEmpty
                        ? conversation.messages.last.text
                        : 'Start a new conversation',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Text(
              conversation.messages.isNotEmpty
                  ? '${conversation.messages.last.timestamp?.toString() ?? ""}:${conversation.messages.last.timestamp?.toString() ?? ""}'
                  : '',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

