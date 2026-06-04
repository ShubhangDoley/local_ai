import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_gemma/flutter_gemma.dart';

import 'model_provider.dart';
import '../db/db_helper.dart';

// Set this to your development machine's IP and port so a physical phone can reach the backend.
// Example: '192.168.1.42:8000' or '10.0.0.5:8000'
const String backendHost = String.fromEnvironment(
  'BACKEND_URL',
  defaultValue: '',
);
enum ChatRole { user, assistant }

class ChatMessage {
  ChatMessage({required this.text, required this.role, DateTime? timestamp})
    : timestamp = timestamp ?? DateTime.now();

  final String text;
  final ChatRole role;
  final DateTime timestamp;

  Map<String, dynamic> toMap() {
    return {
      'text': text,
      'role': role.name,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      text: map['text'] as String,
      role: ChatRole.values.byName(map['role'] as String),
      timestamp: DateTime.parse(map['timestamp'] as String),
    );
  }
}

class ChatProvider extends ChangeNotifier {
  final List<ChatMessage> _messages = <ChatMessage>[
    ChatMessage(
      text: 'Tell me what you want to build and I will help.',
      role: ChatRole.assistant,
    ),
  ];

  String _currentInput = '';
  bool _isSending = false;
  
  ModelProvider? _modelProvider;
  dynamic _localChatSession;
  LocalModel? _lastLocalModel;

  List<ChatMessage> get messages => List<ChatMessage>.unmodifiable(_messages);
  String get currentInput => _currentInput;
  bool get isSending => _isSending;
  bool get canSend => _currentInput.trim().isNotEmpty && !_isSending;

  ChatProvider() {
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    try {
      final List<Map<String, dynamic>> maps = await DbHelper.getInstance.getAllMessages();
      if (maps.isNotEmpty) {
        _messages.clear();
        _messages.addAll(maps.map((m) => ChatMessage.fromMap(m)).toList());
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading messages from SQLite: $e');
    }
  }

  Future<void> clearChatHistory() async {
    try {
      await DbHelper.getInstance.clearAllMessages();
      _messages.clear();
      _messages.add(
        ChatMessage(
          text: 'Tell me what you want to build and I will help.',
          role: ChatRole.assistant,
        ),
      );
      notifyListeners();
    } catch (e) {
      debugPrint('Error clearing chat history: $e');
    }
  }

  void updateModelProvider(ModelProvider modelProvider) {
    _modelProvider = modelProvider;
  }

  void updateInput(String value) {
    _currentInput = value;
    notifyListeners();
  }

  Future<void> sendUserMessage(String text) async {
    final String sanitizedText = text.trim();
    if (sanitizedText.isEmpty || _isSending) {
      return;
    }

    final userMessage = ChatMessage(text: sanitizedText, role: ChatRole.user);
    _messages.add(userMessage);
    _currentInput = '';
    _isSending = true;
    notifyListeners();

    // Save user message to database immediately
    try {
      await DbHelper.getInstance.insertMessage(userMessage.toMap());
    } catch (e) {
      debugPrint('Failed to save user message: $e');
    }

    // Check if Local AI is active and configured
    if (_modelProvider != null && _modelProvider!.isLocalMode) {
      final activeModel = _modelProvider!.activeModel;
      if (activeModel == null) {
        final errorMsg = ChatMessage(
          text: 'No local model downloaded/selected. Please download and select a model first.',
          role: ChatRole.assistant,
        );
        _messages.add(errorMsg);
        _isSending = false;
        notifyListeners();
        
        try {
          await DbHelper.getInstance.insertMessage(errorMsg.toMap());
        } catch (_) {}
        return;
      }

      try {
        // Reset session if the selected model changed
        if (_lastLocalModel?.id != activeModel.id) {
          if (_localChatSession != null) {
            try {
              await _localChatSession.close();
            } catch (_) {}
            _localChatSession = null;
          }
          _lastLocalModel = activeModel;
        }

        // Initialize active model session
        if (_localChatSession == null) {
          final inferenceModel = await FlutterGemma.getActiveModel(
            maxTokens: 2048,
          );
          _localChatSession = await inferenceModel.createChat(
            temperature: 0.7,
          );
        }

        // Add the user message
        final userMsg = Message.text(text: sanitizedText, isUser: true);
        await _localChatSession.addQueryChunk(userMsg);

        // Get the streaming response from local model
        final responseStream = _localChatSession.generateChatResponseAsync();

        // Create a placeholder message in chat list
        final ChatMessage assistantMessagePlaceholder = ChatMessage(
          text: '',
          role: ChatRole.assistant,
        );
        _messages.add(assistantMessagePlaceholder);
        final int assistantMsgIndex = _messages.length - 1;

        final StringBuffer buffer = StringBuffer();

        await for (final response in responseStream) {
          String chunk = '';
          try {
            final dynamic r = response;
            if (r is String) {
              chunk = r;
            } else {
              try {
                chunk = r.text;
              } catch (_) {
                try {
                  chunk = r.token;
                } catch (_) {
                  chunk = r.toString();
                }
              }
            }
          } catch (_) {}

          if (chunk.isNotEmpty) {
            buffer.write(chunk);
            _messages[assistantMsgIndex] = ChatMessage(
              text: buffer.toString(),
              role: ChatRole.assistant,
              timestamp: assistantMessagePlaceholder.timestamp,
            );
            notifyListeners();
          }
        }

        // Save complete local model response to database
        final finalAssistantMsg = ChatMessage(
          text: buffer.toString(),
          role: ChatRole.assistant,
          timestamp: assistantMessagePlaceholder.timestamp,
        );
        try {
          await DbHelper.getInstance.insertMessage(finalAssistantMsg.toMap());
        } catch (_) {}

      } catch (e) {
        final errorMsg = ChatMessage(
          text: 'On-device AI failed: ${e.toString()}',
          role: ChatRole.assistant,
        );
        _messages.add(errorMsg);
        try {
          await DbHelper.getInstance.insertMessage(errorMsg.toMap());
        } catch (_) {}
      } finally {
        _isSending = false;
        notifyListeners();
      }
      return;
    }

    // Backend AI Flow
    try {
      final String assistantReply = await sendMessageToBackend(sanitizedText);
      final replyMsg = ChatMessage(text: assistantReply, role: ChatRole.assistant);
      _messages.add(replyMsg);
      
      // Save backend response to database
      try {
        await DbHelper.getInstance.insertMessage(replyMsg.toMap());
      } catch (_) {}
    } catch (e) {
      String errorText = 'I could not reach the backend AI: ${e.toString()}';
      if (e is TimeoutException) {
        errorText = 'Failed to connect: AI response timed out after 60 seconds. Please check if the backend server is running.';
      } else if (e.toString().contains('SocketException') || e.toString().contains('Connection refused') || e.toString().contains('Connection failed')) {
        errorText = 'Failed to connect: Please make sure your server at $backendHost is running and accessible.';
      }

      final errorMsg = ChatMessage(
        text: errorText,
        role: ChatRole.assistant,
      );
      _messages.add(errorMsg);
      try {
        await DbHelper.getInstance.insertMessage(errorMsg.toMap());
      } catch (_) {}
    } finally {
      _isSending = false;
      notifyListeners();
    }
  }

  Future<String> sendMessageToBackend(String userInput) async {
    String urlStr = backendHost;
    if (!urlStr.startsWith('http://') && !urlStr.startsWith('https://')) {
      urlStr = 'http://$urlStr';
    }
    // Remove trailing slash if present
    if (urlStr.endsWith('/')) {
      urlStr = urlStr.substring(0, urlStr.length - 1);
    }
    
    final response = await http.post(
      Uri.parse('$urlStr/chat'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'prompt': userInput}),
    ).timeout(
      const Duration(seconds: 60),
      onTimeout: () {
        throw TimeoutException('AI response timed out after 60 seconds.');
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Backend returned status ${response.statusCode}');
    }

    final data = jsonDecode(response.body);

    if (data == null || data['response'] == null) {
      throw Exception('Invalid response from backend');
    }

    return data['response'];
  }

  @override
  void dispose() {
    if (_localChatSession != null) {
      try {
        _localChatSession.close();
      } catch (_) {}
    }
    super.dispose();
  }
}
