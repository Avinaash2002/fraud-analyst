/// FraudX Analyst - Chat Screen
/// ===============================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../config/api_config.dart';
import '../providers/app_provider.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  List<String> _suggestions = [
    'What is credit card fraud?',
    'Explain XGBoost model',
    'Why was my transaction flagged?',
    'How does fraud detection work?',
  ];

  @override
  void initState() {
    super.initState();
    _messages.add(ChatMessage(
      message: "Hello! I'm the FraudX Analyst, your AI assistant for credit card fraud detection. I can answer questions about fraud patterns, explain ML model decisions, and help you understand transaction analysis. How can I help you today?",
      isUser: false, timestamp: DateTime.now(),
    ));
    _loadSuggestions();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Check for pending question from "Ask Chatbot About This"
    final provider = context.read<AppProvider>();
    if (provider.pendingChatQuestion != null) {
      final question = provider.pendingChatQuestion!;
      provider.clearPendingChatQuestion();
      Future.microtask(() => _sendMessage(question));
    }
  }

  Future<void> _loadSuggestions() async {
    try {
      final suggestions = await ApiService.getChatSuggestions();
      if (mounted) setState(() => _suggestions = suggestions);
    } catch (_) {}
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;
    setState(() {
      _messages.add(ChatMessage(message: text, isUser: true, timestamp: DateTime.now()));
      _isLoading = true;
    });
    _controller.clear();
    _scrollToBottom();

    // Build conversation history from previous messages (last 6, excluding current)
    final prevMessages = _messages.length > 1 ? _messages.sublist(0, _messages.length - 1) : <ChatMessage>[];
    final history = prevMessages
        .reversed
        .take(6)
        .toList()
        .reversed
        .map((m) => {'role': m.isUser ? 'user' : 'assistant', 'content': m.message})
        .toList();

    final provider = context.read<AppProvider>();
    try {
      final response = await ApiService.chat(ChatRequest(
        message: text,
        deviceId: ApiConfig.deviceId,
        simulationId: provider.chatSimulationId,
        chatHistory: history.isNotEmpty ? history : null,
      ));
      if (mounted) {
        setState(() {
          _messages.add(ChatMessage(message: response.reply, isUser: false, timestamp: DateTime.now(), sources: response.sources));
          _isLoading = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add(ChatMessage(message: 'Sorry, I encountered an error. Please try again.', isUser: false, timestamp: DateTime.now()));
          _isLoading = false;
        });
      }
    }
  }

  void _askAboutLastSimulation() {
    final provider = context.read<AppProvider>();
    final pred = provider.lastPrediction;
    if (pred != null) {
      provider.clearChatContext();
      _sendMessage(
        'Explain my last simulation result (ID: ${pred.simulationId}). '
        'The prediction was ${pred.prediction} with a risk score of ${(pred.riskScore * 100).toStringAsFixed(1)}%. '
        'Why was this transaction classified this way? What features contributed most?'
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('No simulation yet. Run a simulation first!'),
        backgroundColor: Color(0xFFFF9800),
      ));
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(_scrollController.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  @override
  void dispose() { _controller.dispose(); _scrollController.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final hasSimulation = context.watch<AppProvider>().lastPrediction != null;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: Column(children: [
          // ── Header ──────────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 14), color: const Color(0xFFF5F7FA),
            child: Row(children: [
              Container(width: 36, height: 36, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6)]),
                child: const Icon(Icons.arrow_back_ios_new, size: 16, color: Color(0xFF1A1A2E))),
              const SizedBox(width: 14),
              Container(width: 40, height: 40, decoration: const BoxDecoration(color: Color(0xFF2A9D8F), shape: BoxShape.circle),
                child: const Icon(Icons.smart_toy, size: 22, color: Colors.white)),
              const SizedBox(width: 12),
              const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Fraud Analyst', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E))),
                Text('Powered by RAG AI', style: TextStyle(fontSize: 12, color: Color(0xFF2A9D8F), fontWeight: FontWeight.w500)),
              ])),
              Container(width: 36, height: 36, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6)]),
                child: const Icon(Icons.help_outline, size: 18, color: Color(0xFF6B7280))),
            ]),
          ),

          // ── Messages ──────────────────────────────────────────
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
              itemCount: _messages.length + (_isLoading ? 1 : 0),
              itemBuilder: (ctx, index) {
                if (index == _messages.length && _isLoading) return _TypingIndicator();
                return _MessageBubble(message: _messages[index]);
              },
            ),
          ),

          // ── Ask About Last Simulation Button ───────────────────
          if (hasSimulation && _messages.length <= 3)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
              child: SizedBox(width: double.infinity, height: 42,
                child: OutlinedButton.icon(
                  onPressed: _askAboutLastSimulation,
                  icon: const Icon(Icons.history, size: 18),
                  label: const Text('Ask about my last simulation', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF2A9D8F), side: const BorderSide(color: Color(0xFF2A9D8F)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                ),
              ),
            ),

          // ── Suggestions ──────────────────────────────────────
          if (_messages.length <= 2)
            Container(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Suggested questions:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF6B7280))),
                const SizedBox(height: 8),
                ..._suggestions.map((s) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: GestureDetector(
                    onTap: () => _sendMessage(s),
                    child: Row(children: [
                      Container(width: 6, height: 6, decoration: const BoxDecoration(color: Color(0xFF2A9D8F), shape: BoxShape.circle)),
                      const SizedBox(width: 10),
                      Expanded(child: Text(s, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Color(0xFF2A9D8F)))),
                    ]),
                  ),
                )),
              ]),
            ),

          // ── Input ──────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
            decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -2))]),
            child: Row(children: [
              Expanded(child: Container(
                decoration: BoxDecoration(color: const Color(0xFFF5F7FA), borderRadius: BorderRadius.circular(14)),
                child: TextField(controller: _controller, onSubmitted: _sendMessage, style: const TextStyle(fontSize: 16),
                  decoration: const InputDecoration(hintText: 'Ask about fraud detection…', hintStyle: TextStyle(fontSize: 15, color: Color(0xFF9CA3AF)), border: InputBorder.none, contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12))),
              )),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: () => _sendMessage(_controller.text),
                child: Container(width: 44, height: 44, decoration: BoxDecoration(color: const Color(0xFF2A9D8F), borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.send, size: 20, color: Colors.white)),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  const _MessageBubble({required this.message});
  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    return Padding(padding: const EdgeInsets.only(bottom: 12),
      child: Row(mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start, crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (!isUser) Container(width: 32, height: 32, margin: const EdgeInsets.only(right: 8, top: 4), decoration: const BoxDecoration(color: Color(0xFF2A9D8F), shape: BoxShape.circle), child: const Icon(Icons.smart_toy, size: 16, color: Colors.white)),
        Flexible(child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(color: isUser ? const Color(0xFF2A9D8F) : Colors.white,
            borderRadius: BorderRadius.only(topLeft: const Radius.circular(16), topRight: const Radius.circular(16), bottomLeft: Radius.circular(isUser ? 16 : 4), bottomRight: Radius.circular(isUser ? 4 : 16)),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2))]),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(message.message, style: TextStyle(fontSize: 16, height: 1.5, color: isUser ? Colors.white : const Color(0xFF374151))),
            const SizedBox(height: 4),
            Text(_formatTime(message.timestamp), style: TextStyle(fontSize: 12, color: isUser ? Colors.white.withOpacity(0.7) : const Color(0xFF9CA3AF))),
          ]),
        )),
      ]),
    );
  }
  String _formatTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

class _TypingIndicator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(padding: const EdgeInsets.only(bottom: 12),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(width: 32, height: 32, margin: const EdgeInsets.only(right: 8, top: 4), decoration: const BoxDecoration(color: Color(0xFF2A9D8F), shape: BoxShape.circle), child: const Icon(Icons.smart_toy, size: 16, color: Colors.white)),
        Container(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2))]),
          child: Row(mainAxisSize: MainAxisSize.min, children: List.generate(3, (i) => Container(width: 8, height: 8, margin: const EdgeInsets.symmetric(horizontal: 2), decoration: BoxDecoration(color: const Color(0xFF2A9D8F).withOpacity(0.4 + i * 0.2), shape: BoxShape.circle))))),
      ]),
    );
  }
}
