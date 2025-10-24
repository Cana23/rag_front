import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../model/message.dart';

const String baseUrl = 'http://192.168.0.46:8000';

class ChatProvider with ChangeNotifier {
  final Dio _dio = Dio();
  final List<Message> _messages = [];
  bool _isLoading = false;

  List<Message> get messages => _messages;
  bool get isLoading => _isLoading;

  ChatProvider() {
    _dio.options
      ..connectTimeout = const Duration(seconds: 20)
      ..receiveTimeout = const Duration(seconds: 30)
      ..headers = {'Content-Type': 'application/json'};

    _loadChatHistory();
  }

  Future<void> _loadChatHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final savedData = prefs.getString('chat_history');

    if (savedData != null) {
      final List decoded = jsonDecode(savedData);
      _messages
        ..clear()
        ..addAll(decoded.map((e) => Message.fromJson(e)).toList());
      notifyListeners();
    }
  }

  Future<void> _saveChatHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final data = jsonEncode(_messages.map((m) => m.toJson()).toList());
    await prefs.setString('chat_history', data);
  }

  Future<void> resetChat() async {
    _messages.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('chat_history');
    notifyListeners();
  }

  void addUserMessage(String text) {
    _messages.add(Message(text: text, sender: Sender.user));
    _saveChatHistory();
    notifyListeners();
  }

  void addAssistantMessage(String text) {
    _messages.add(Message(text: text, sender: Sender.assistant));
    _saveChatHistory();
    notifyListeners();
  }

  void updateLastAssistantMessage(String newText) {
    for (int i = _messages.length - 1; i >= 0; i--) {
      if (_messages[i].sender == Sender.assistant) {
        _messages[i] = Message(text: newText, sender: Sender.assistant);
        _saveChatHistory();
        notifyListeners();
        return;
      }
    }
    addAssistantMessage(newText);
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    addUserMessage(text);
    addAssistantMessage('Preparando respuesta...');
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _dio.post(
        '$baseUrl/chat',
        data: jsonEncode({
          "message": text,
          "history": [],
        }),
      );

      String answer = '';
      final data = response.data;

      if (data == null) {
        answer = 'Respuesta vacía del servidor.';
      } else if (data is Map && data['answer'] != null) {
        answer = data['answer'].toString();
      } else {
        answer = 'Formato de respuesta inesperado.';
      }

      updateLastAssistantMessage(answer);
    } on DioException catch (e) {
      updateLastAssistantMessage(
        'Error de conexión: ${e.response?.statusCode ?? 'sin código'}',
      );
    } catch (e) {
      updateLastAssistantMessage('Error inesperado: $e');
    } finally {
      _isLoading = false;
      _saveChatHistory();
      notifyListeners();
    }
  }
}
