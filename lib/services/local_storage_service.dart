import 'package:shared_preferences/shared_preferences.dart';
import 'package:kiwi/models/conversation.dart';
import 'dart:convert';

class LocalStorageService {
  static const String _conversationsKey = 'conversations';

  static Future<List<Conversation>> getConversations() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
     List<String> conversationsJson = prefs.getStringList(_conversationsKey) ?? [];
     for (int i = 0; i < conversationsJson.length; i++) {
       print(jsonEncode(conversationsJson[i]));
       print(conversationsJson[i].toString());
       Map<String, dynamic> chatMap = json.decode(conversationsJson[i]);

       print(Conversation.fromJson(chatMap));
     }
    List<Conversation> conversations = conversationsJson.map((c) => Conversation.fromJson(jsonDecode(c))).toList();
    return conversations;
  }


  static Future<void> saveConversation(Conversation conversation) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> conversationsJson = prefs.getStringList(_conversationsKey) ?? [];

    Map<String, dynamic> json = conversation.toJson();

    conversationsJson.add(jsonEncode(json));

    await prefs.setStringList(_conversationsKey, conversationsJson);
  }

  static Future<List<Conversation>> loadConversations() async {
    return await getConversations();
  }

  static Future<void> updateConversation(Conversation conversation) async {
    List<Conversation> conversations = await getConversations();
    int index = conversations.indexWhere((c) => c.id == conversation.id);
    if (index != -1) {
      conversations[index] = conversation;
      SharedPreferences prefs = await SharedPreferences.getInstance();
      List<String> conversationsJson = conversations.map((c) => jsonEncode(c.toJson())).toList();
      await prefs.setStringList(_conversationsKey, conversationsJson);
    }
  }

  static Future<void> deleteConversation(String conversationId) async {
    List<Conversation> conversations = await getConversations();
    conversations.removeWhere((c) => c.id == conversationId);
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> conversationsJson = conversations.map((c) => c.toJson().toString()).toList();
    await prefs.setStringList(_conversationsKey, conversationsJson);
  }
}

