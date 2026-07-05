import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme.dart';
import '../services/api_service.dart';
import '../widgets/glass_card.dart';

class ChatScreen extends StatefulWidget {
  final Map<String, dynamic> patientData;
  const ChatScreen({super.key, required this.patientData});
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _ctrl     = TextEditingController();
  final _scroll   = ScrollController();
  final List<Map<String, String>> _messages = [];
  bool _loading = false;

  final List<String> _suggestions = [
    'Why is my risk high?',
    'How to reduce risk?',
    'Is my BP dangerous?',
    'Safe exercises?',
    'What does cholesterol mean?',
    'Should I see a doctor?',
  ];

  @override
  void initState() {
    super.initState();
    _messages.add({
      'role': 'bot',
      'text': "Hello! I'm your CardioTwin AI assistant, powered by Groq AI. 🫀\n\nI can answer questions about cardiovascular health based on the patient data. Ask me anything!",
    });
  }

  Future<void> _send(String msg) async {
    if (msg.trim().isEmpty || _loading) return;
    _ctrl.clear();
    setState(() {
      _messages.add({'role': 'user', 'text': msg});
      _loading = true;
    });
    _scrollDown();

    try {
      final res = await ApiService.sendChatMessage(msg, widget.patientData);
      setState(() {
        _messages.add({'role': 'bot', 'text': res['reply'] ?? 'No response'});
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _messages.add({'role': 'bot', 'text': 'Error: $e'});
        _loading = false;
      });
    }
    _scrollDown();
  }

  void _scrollDown() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.bgGradient),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: AppTheme.surface2,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.textSecondary, size: 18),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(gradient: AppTheme.primaryGradient, borderRadius: BorderRadius.circular(10)),
                    child: const Center(child: Text('🫀', style: TextStyle(fontSize: 18))),
                  ),
                  const SizedBox(width: 10),
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('CardioTwin AI', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w700, fontSize: 15)),
                    Text('Powered by Groq AI', style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                  ]),
                ]),
              ).animate().fadeIn(),

              const SizedBox(height: 12),

              // Messages
              Expanded(
                child: ListView.builder(
                  controller: _scroll,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _messages.length + (_loading ? 1 : 0),
                  itemBuilder: (_, i) {
                    if (i == _messages.length) return _buildTyping();
                    final m = _messages[i];
                    return _buildMessage(m['role']!, m['text']!, i);
                  },
                ),
              ),

              // Suggestions
              if (_messages.length == 1)
                SizedBox(
                  height: 40,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _suggestions.length,
                    itemBuilder: (_, i) => GestureDetector(
                      onTap: () => _send(_suggestions[i]),
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppTheme.surface2,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppTheme.border),
                        ),
                        child: Text(_suggestions[i], style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                      ),
                    ),
                  ),
                ),

              const SizedBox(height: 8),

              // Input
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: GlassCard(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Row(children: [
                    Expanded(
                      child: TextField(
                        controller: _ctrl,
                        style: TextStyle(color: AppTheme.textPrimary, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Ask a medical question...',
                          hintStyle: TextStyle(color: AppTheme.textMuted, fontSize: 14),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onSubmitted: _send,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _send(_ctrl.text),
                      child: Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(
                          gradient: AppTheme.primaryGradient,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                      ),
                    ),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessage(String role, String text, int i) {
    final isBot = role == 'bot';
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isBot ? MainAxisAlignment.start : MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isBot) ...[
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(gradient: AppTheme.primaryGradient, borderRadius: BorderRadius.circular(10)),
              child: const Center(child: Text('🫀', style: TextStyle(fontSize: 16))),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isBot ? AppTheme.surface2 : AppTheme.purple.withOpacity(0.3),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isBot ? AppTheme.border : AppTheme.purple.withOpacity(0.4),
                ),
              ),
              child: Text(text, style: TextStyle(color: AppTheme.textPrimary, fontSize: 13, height: 1.5)),
            ),
          ),
          if (!isBot) ...[
            const SizedBox(width: 8),
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(color: AppTheme.surface2, borderRadius: BorderRadius.circular(10)),
              child: Icon(Icons.person_outline_rounded, color: AppTheme.textMuted, size: 18),
            ),
          ],
        ],
      ),
    ).animate(delay: Duration(milliseconds: i * 30)).fadeIn().slideY(begin: 0.1);
  }

  Widget _buildTyping() => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(children: [
      Container(
        width: 32, height: 32,
        decoration: BoxDecoration(gradient: AppTheme.primaryGradient, borderRadius: BorderRadius.circular(10)),
        child: const Center(child: Text('🫀', style: TextStyle(fontSize: 16))),
      ),
      const SizedBox(width: 8),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(color: AppTheme.surface2, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.border)),
        child: Row(children: [
          _dot(0), const SizedBox(width: 4),
          _dot(200), const SizedBox(width: 4),
          _dot(400),
        ]),
      ),
    ]),
  );

  Widget _dot(int delay) => Container(
    width: 7, height: 7,
    decoration: BoxDecoration(color: AppTheme.purpleLight, shape: BoxShape.circle),
  ).animate(onPlay: (c) => c.repeat())
   .fadeIn(delay: Duration(milliseconds: delay), duration: 400.ms)
   .then().fadeOut(duration: 400.ms);
}
