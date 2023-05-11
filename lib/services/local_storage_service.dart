import 'package:shared_preferences/shared_preferences.dart';
import 'package:kiwi/models/conversation.dart';
import 'dart:convert';

class LocalStorageService {
  static const String _conversationsKey = 'conversations';

  static Future<List<Conversation>> getConversations() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    // List<String>? conversationsJson = prefs.getStringList(_conversationsKey);
    //
    // if (conversationsJson == null) {
    //   return [];
    // }
    //
    // List<Conversation> conversations = conversationsJson.map((conversationJson) {
    //   Map<String, dynamic> json = jsonDecode(conversationJson);
    //   return Conversation.fromJson(json);
    // }).toList();
    final conversations = prefs.getStringList(_conversationsKey);
    if (conversations == null) {
      return [];
    } else {
      return conversations.map((json) => Conversation.fromJson(jsonDecode(json))).toList();
    }
    // return conversations;
  }

  static Future<void> saveConversation(Conversation conversation) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> conversationsJson = prefs.getStringList(_conversationsKey) ?? [];

    Map<String, dynamic> json = conversation.toJson();
    String conversationJson = json.toString();

    conversationsJson.add(conversationJson);

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
      List<String> conversationsJson = conversations.map((c) => c.toJson().toString()).toList();
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

