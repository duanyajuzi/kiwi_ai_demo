import 'dart:convert';
import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/conversation.dart';

class LocalStorageService {
  static SharedPreferences? _preferences;
  static const String _keyConversations = 'conversations';

  static final StreamController<List<Conversation>> _conversationsStreamController =
  StreamController<List<Conversation>>.broadcast();

  static Future<void> init() async {
    _preferences = await SharedPreferences.getInstance();
  }

  static List<Conversation> getConversations() {
    final conversationsJson = _preferences!.getStringList(_keyConversations) ?? [];
    return conversationsJson.map((json) => Conversation.fromJson(jsonDecode(json))).toList();
  }

  static Conversation getConversation(String conversationId) {
    final conversationsJson = _preferences!.getStringList(_keyConversations) ?? [];
    return conversationsJson.map((json) => Conversation.fromJson(jsonDecode(json))).toList().firstWhere((c) => c.id == conversationId);
  }

  static Future<void> saveConversation(Conversation conversation) async {
    if (!containsConversation(conversation.id)) {
      final conversations = getConversations()..add(conversation);
      await _saveConversations(conversations);
      _conversationsStreamController.add(conversations);
    }
  }

  static Future<void> updateConversation(Conversation conversation) async {
    if (containsConversation(conversation.id)) {
      final conversations = getConversations().map((c) => c.id == conversation.id ? conversation : c).toList();
      await _saveConversations(conversations);
      _conversationsStreamController.add(conversations);
    }
  }

  static Future<void> deleteConversation(String conversationId) async {
    final conversations = getConversations()..removeWhere((c) => c.id == conversationId);
    await _saveConversations(conversations);
    _conversationsStreamController.add(conversations);
  }

  static bool containsConversation(String conversationId) {
    return getConversations().any((c) => c.id == conversationId);
  }

  static Future<void> _saveConversations(List<Conversation> conversations) async {
    final conversationsJson = conversations.map((c) => jsonEncode(c.toJson())).toList();
    await _preferences!.setStringList(_keyConversations, conversationsJson);
  }

  static Stream<List<Conversation>> get conversationsStream => _conversationsStreamController.stream;

  static void dispose() {
    _conversationsStreamController.close();
  }
}
