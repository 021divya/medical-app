import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:ai_medical_app/services/api_service.dart'; // adjust path if needed

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});
  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  String get botUrl => ApiService.aiBotUrl;
  static const String userId = "user_001";

  final Color primary     = const Color(0xFF9C89E8);
  final Color lightPurple = const Color(0xFFF3EFFF);
  final Color darkPurple  = const Color(0xFF5E4DB2);
  final Color accentGreen = const Color(0xFF43AA8B);

  final TextEditingController _controller  = TextEditingController();
  final ScrollController       _scrollCtrl = ScrollController();

  final List<Map<String, dynamic>> _messages = [];
  bool   _isLoading      = false;
  bool   _inputDisabled  = false;

  String _uiStage        = 'SYMPTOMS';
  int    _filterStep     = 0;
  String _lastSpecialist = '';

  String _fLocation = '';
  String _fDistance = '';
  String _fFees     = '';

  @override
  void initState() {
    super.initState();
    _addBot(
      "👋 Hello! I'm your AI Medical Assistant.\n\n"
      "What discomfort are you facing?\nPlease tell me so that I can help you! 😊",
    );
  }

  void _addBot(String text,
      {String msgType = 'text', List<Map<String, dynamic>>? doctors}) {
    setState(() {
      _messages.add({
        'role':    'bot',
        'text':    text,
        'msgType': msgType,
        'doctors': doctors,
      });
    });
    _scrollToBottom();
  }

  void _addUser(String text) {
    setState(() => _messages.add({'role': 'user', 'text': text}));
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send(String text) async {
    if (text.trim().isEmpty || _inputDisabled) return;
    _controller.clear();
    _addUser(text);
    setState(() => _isLoading = true);

    try {
      if (_uiStage == 'FILTERS') {
        await _handleFilterStep(text);
      } else {
        await _callSymptoms(text);
      }
    } catch (e) {
      _addBot("❌ Cannot connect to MediBot.\n\nMake sure it's running on port 8002!");
    }

    setState(() => _isLoading = false);
  }

  Future<void> _callSymptoms(String input) async {
    final res = await http.post(
      Uri.parse('$botUrl/symptoms'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'symptoms': input, 'user_id': userId}),
    ).timeout(const Duration(seconds: 15));

    if (res.statusCode != 200) {
      _addBot("❌ Server error (${res.statusCode}). Please try again.");
      return;
    }
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    _handleServerResponse(data);
  }

  void _handleServerResponse(Map<String, dynamic> data) {
    final type = data['type'] as String? ?? '';

    switch (type) {
      case 'Emergency':
        _addBot(data['message'] ?? '🚨 Please go to the nearest hospital!',
            msgType: 'emergency');
        _resetLocalState();
        break;

      case 'Follow-Up Question':
        _uiStage = 'FOLLOWUP';
        _addBot(data['question'] ?? 'Can you tell me more?', msgType: 'yes_no');
        break;

      case 'Specialist Choice':
        _lastSpecialist = data['specialist'] ?? 'Specialist';
        _uiStage        = 'CHOICE';
        _addBot(
          "✅ Based on your symptoms, you should consult:\n\n"
          "🩺  $_lastSpecialist\n\n"
          "What would you like to do next?",
          msgType: 'choice',
        );
        break;

      case 'Ask Want Doctors':
        _lastSpecialist = data['specialist'] ?? _lastSpecialist;
        _uiStage        = 'AFTER_SPEC';
        _addBot(
          "🩺 You should consult a $_lastSpecialist.\n\n"
          "Would you also like a list of nearby $_lastSpecialist doctors?",
          msgType: 'yes_no',
        );
        break;

      case 'Ask Filters':
        _uiStage    = 'FILTERS';
        _filterStep = (data['filter_step'] as int?) ?? 0;
        _addFilterPrompt(_filterStep);
        break;

      case 'Fetch Doctors':
        _lastSpecialist = data['specialist'] as String? ?? _lastSpecialist;
        final filters = Map<String, dynamic>.from(
            data['filters'] as Map<String, dynamic>? ?? {});
        filters['specialist'] = _lastSpecialist;
        _fetchDoctors(filters);
        break;

      case 'Goodbye':
        _addBot(data['message'] ?? '🌿 Get well soon! 💙');
        _addBot("Feel free to describe new symptoms anytime. 😊",
            msgType: 'restart');
        _resetLocalState();
        break;

      default:
        _addBot(data['message'] ?? 'Please describe your symptoms.');
    }
  }

  Future<void> _handleFilterStep(String input) async {
    switch (_filterStep) {
      case 0:
        _fLocation  = input.trim();
        _filterStep = 1;
        _addFilterPrompt(1);
        break;
      case 1:
        _fDistance  = input.trim();
        _filterStep = 2;
        _addFilterPrompt(2);
        break;
      case 2:
        _fFees      = input.trim();
        _filterStep = 3;
        _addFilterPrompt(3);
        break;
      case 3:
        final maxDist = double.tryParse(_fDistance) ?? 10.0;
        final maxFees = int.tryParse(_fFees)        ?? 5000;
        final minRat  = double.tryParse(input.trim()) ?? 0.0;
        await _fetchDoctors({
          'location':        _fLocation,
          'max_distance_km': maxDist,
          'max_fees':        maxFees,
          'min_rating':      minRat,
          'specialist':      _lastSpecialist,
        });
        break;
    }
  }

  void _addFilterPrompt(int step) {
    switch (step) {
      case 0:
        _addBot(
          "Please enter your filters for doctor recommendations:\n\n"
          "📍 Location\n(e.g., Dwarka, Rohini, Shahdara, Krishna Nagar)",
        );
        break;
      case 1:
        _addBot("📏 Maximum Distance in km  (0 – 5)\n(e.g., 4.6 or 5.0)");
        break;
      case 2:
        _addBot("💰 Maximum Fees\n(Enter amount in ₹, e.g., 1000 or 2000)");
        break;
      case 3:
        _addBot("⭐ Minimum Rating  (0 – 5)\n(e.g., 4 or 0 for all)");
        break;
    }
  }

  Future<void> _fetchDoctors(Map<String, dynamic> filters) async {
    _addBot("🔍 Finding the best doctors for you...");

    final String specialistToSend = _lastSpecialist.isNotEmpty
        ? _lastSpecialist
        : (filters['specialist'] as String? ?? '');

    final savedFilters = Map<String, dynamic>.from(filters);
    savedFilters['specialist'] = specialistToSend;

    _resetLocalState();

    final res = await http.post(
      Uri.parse('$botUrl/recommend'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'specialist':      specialistToSend,
        'location_text':   filters['location']        ?? '',
        'max_distance_km': filters['max_distance_km'] ?? 10.0,
        'max_fees':        filters['max_fees']         ?? 5000,
        'min_rating':      filters['min_rating']       ?? 0.0,
        'user_id':         userId,
      }),
    ).timeout(const Duration(seconds: 15));

    if (res.statusCode != 200) {
      _addBot("❌ Could not fetch doctors. Please try again!");
      return;
    }

    final data    = jsonDecode(res.body) as Map<String, dynamic>;
    final doctors = List<Map<String, dynamic>>.from(data['doctors'] ?? []);

    if (doctors.isEmpty) {
      _addBot(
        "😔 No doctors found near **${savedFilters['location']}** with your filters.\n\n"
        "Would you like to adjust the filters and try again?",
        msgType: 'retry',
      );
      _lastSpecialist = specialistToSend;
    } else {
      _addBot(
        "✅ Found ${doctors.length} doctor${doctors.length > 1 ? 's' : ''} for you:",
        msgType: 'doctors',
        doctors: doctors,
      );
      Future.delayed(const Duration(milliseconds: 700), () {
        _addBot(
          "🌿 We hope you get well soon! Take care of yourself. 💙\n\n"
          "Feel free to describe new symptoms anytime. 😊",
          msgType: 'restart',
        );
      });
    }
  }

  void _retryFilters() {
    _uiStage    = 'FILTERS';
    _filterStep = 0;
    _fLocation = _fDistance = _fFees = '';
    _addFilterPrompt(0);
  }

  void _resetLocalState() {
    _uiStage        = 'SYMPTOMS';
    _filterStep     = 0;
    _fLocation = _fDistance = _fFees = '';
    _lastSpecialist = '';
  }

  Future<void> _resetChat() async {
    try {
      await http.post(
        Uri.parse('$botUrl/reset'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': userId}),
      );
    } catch (_) {}

    setState(() {
      _messages.clear();
      _inputDisabled = false;
    });
    _resetLocalState();

    _addBot(
      "👋 Hello! I'm your AI Medical Assistant.\n\n"
      "What discomfort are you facing?\nPlease tell me so that I can help you! 😊",
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightPurple,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          Expanded(child: _buildMessageList()),
          _buildInputBar(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: primary,
      foregroundColor: Colors.white,
      elevation: 0,
      title: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: Colors.white24,
            child: const Icon(Icons.smart_toy, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 10),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("MediBot",
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              Text("AI Symptom Checker",
                  style: TextStyle(fontSize: 11, color: Colors.white70)),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _resetChat,
            tooltip: "New Chat"),
      ],
    );
  }

  Widget _buildMessageList() {
    return ListView.builder(
      controller: _scrollCtrl,
      padding: const EdgeInsets.all(16),
      itemCount: _messages.length + (_isLoading ? 1 : 0),
      itemBuilder: (_, i) {
        if (_isLoading && i == _messages.length) return _typingIndicator();
        final msg = _messages[i];
        return msg['role'] == 'user'
            ? _userBubble(msg['text'])
            : _botBubble(msg);
      },
    );
  }

  Widget _userBubble(String text) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14, left: 60),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: primary,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(18), topRight: Radius.circular(18),
            bottomLeft: Radius.circular(18), bottomRight: Radius.circular(4),
          ),
          boxShadow: [BoxShadow(color: primary.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3))],
        ),
        child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 14)),
      ),
    );
  }

  Widget _botBubble(Map<String, dynamic> msg) {
    final msgType = msg['msgType'] as String? ?? 'text';
    final text    = msg['text']    as String? ?? '';

    Color   bubbleColor  = Colors.white;
    Color   textColor    = Colors.black87;
    Border? bubbleBorder;

    if (msgType == 'emergency') {
      bubbleColor  = Colors.red.shade50;
      textColor    = Colors.red.shade800;
      bubbleBorder = Border.all(color: Colors.red.shade200);
    }

    // ── FIX: removed margin right:40 from here — it was eating into card width
    //         and causing the 35px overflow. Cards now get full Expanded width.
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),   // ← was: right: 40
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Avatar: 14 radius = 28px wide, + 8px gap = 36px total offset
            CircleAvatar(
              radius: 14,
              backgroundColor: primary,
              child: const Icon(Icons.smart_toy, color: Colors.white, size: 14),
            ),
            const SizedBox(width: 8),

            // ── FIX: Expanded makes this column take EXACTLY the remaining width
            //         so nothing can overflow the screen.
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Main speech bubble — capped at 85% of screen width
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.85,
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: bubbleColor, border: bubbleBorder,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(4), topRight: Radius.circular(18),
                          bottomLeft: Radius.circular(18), bottomRight: Radius.circular(18),
                        ),
                        boxShadow: [BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        )],
                      ),
                      child: Text(text,
                          style: TextStyle(fontSize: 14, height: 1.5, color: textColor)),
                    ),
                  ),

                  if (msgType == 'choice') ...[
                    const SizedBox(height: 8),
                    _quickReply("1️⃣  Just tell me the specialist", "1"),
                    const SizedBox(height: 6),
                    _quickReply("2️⃣  Give me a list of doctors", "2"),
                  ],

                  if (msgType == 'yes_no') ...[
                    const SizedBox(height: 8),
                    Row(children: [
                      _quickReply("✅  Yes", "yes"),
                      const SizedBox(width: 8),
                      _quickReply("❌  No", "no"),
                    ]),
                  ],

                  if (msgType == 'retry') ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _actionButton(
                          "🔄  Try different filters",
                          Colors.orange,
                          _retryFilters,
                        ),
                        _actionButton(
                          "🏠  End chat",
                          Colors.grey,
                          () {
                            _addBot(
                              "🌿 Get well soon! Take care of yourself. 💙\n\n"
                              "Feel free to come back anytime. 😊",
                              msgType: 'restart',
                            );
                            _resetLocalState();
                          },
                        ),
                      ],
                    ),
                  ],

                  // ── FIX: doctor cards are now full-width inside Expanded,
                  //         no stray right margin pushing them off-screen.
                  if (msgType == 'doctors' && msg['doctors'] != null)
                    ...List<Map<String, dynamic>>.from(msg['doctors'] as List)
                        .map(_doctorCard)
                        .toList(),

                  if (msgType == 'restart') ...[
                    const SizedBox(height: 10),
                    GestureDetector(
                      onTap: _resetChat,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: accentGreen.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: accentGreen.withOpacity(0.5)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.refresh, color: accentGreen, size: 16),
                            const SizedBox(width: 6),
                            Text("Start a new query",
                                style: TextStyle(
                                    color: accentGreen,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // ── FIX: a small right padding so cards don't touch screen edge
            const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }

  Widget _quickReply(String label, String value) {
    return GestureDetector(
      onTap: () => _send(value),
      child: Container(
        margin: const EdgeInsets.only(top: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: primary.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: primary.withOpacity(0.4)),
        ),
        child: Text(label,
            style: TextStyle(
                color: darkPurple, fontWeight: FontWeight.w600, fontSize: 13)),
      ),
    );
  }

  Widget _actionButton(String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.4)),
        ),
        child: Text(label,
            style: TextStyle(
                color: color, fontWeight: FontWeight.w600, fontSize: 12)),
      ),
    );
  }

  Widget _doctorCard(Map<String, dynamic> d) {
    final name       = d['doctor_name']             as String? ?? 'Doctor';
    final area       = d['area']                    as String? ?? '';
    final specialist = d['specialist']              as String? ?? '';
    final rating     = d['rating']?.toString()      ?? '';
    final fees       = d['fees']?.toString()        ?? '';
    final distance   = d['distance_km']?.toString() ?? '';
    final timing     = d['availability_text']       as String? ?? '';
    final contact    = d['contact']?.toString()     ?? '';

    return Container(
      // ── FIX: no horizontal margin — card fills the full Expanded width.
      //         Use only vertical margin so cards stack with spacing.
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: primary.withOpacity(0.15)),
        boxShadow: [BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 8,
          offset: const Offset(0, 3),
        )],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Doctor header row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: primary.withOpacity(0.12),
                child: Text(
                  name[0].toUpperCase(),
                  style: TextStyle(
                      color: primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 16),
                ),
              ),
              const SizedBox(width: 12),
              // ── FIX: Expanded here prevents the name/badge from pushing
              //         the rating badge off-screen on narrow phones.
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14)),
                    if (specialist.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(specialist,
                            style: TextStyle(
                                color: primary,
                                fontSize: 11,
                                fontWeight: FontWeight.w600)),
                      ),
                    ],
                    if (area.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(area,
                          style: const TextStyle(
                              color: Colors.grey, fontSize: 12)),
                    ],
                  ],
                ),
              ),
              // Rating badge — stays right-aligned, never overflows
              if (rating.isNotEmpty) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star, size: 13, color: Colors.amber),
                      const SizedBox(width: 2),
                      Text(rating,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ],
          ),

          const SizedBox(height: 10),

          // Info tags — Wrap handles long timing strings gracefully
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              if (distance.isNotEmpty) _tag(Icons.location_on, '$distance km'),
              if (fees.isNotEmpty)     _tag(Icons.account_balance_wallet, '₹$fees'),
              if (timing.isNotEmpty)   _tag(Icons.access_time, timing),
              if (contact.isNotEmpty)  _tag(Icons.phone, contact),
            ],
          ),
        ],
      ),
    );
  }

  Widget _tag(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: lightPurple,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: primary),
          const SizedBox(width: 4),
          // ── FIX: Flexible + overflow:ellipsis so long text (e.g. long timing
          //         strings) wraps inside the tag instead of overflowing.
          Flexible(
            child: Text(
              text,
              style: TextStyle(fontSize: 11, color: darkPurple),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _typingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12, left: 36),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          )],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _dot(0),
            const SizedBox(width: 5),
            _dot(200),
            const SizedBox(width: 5),
            _dot(400),
          ],
        ),
      ),
    );
  }

  Widget _dot(int delayMs) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.3, end: 1.0),
      duration: Duration(milliseconds: 600 + delayMs),
      curve: Curves.easeInOut,
      builder: (_, v, __) => Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: primary.withOpacity(v),
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  Widget _buildInputBar() {
    String hint = 'Describe your symptoms...';
    if (_uiStage == 'FILTERS') {
      switch (_filterStep) {
        case 0: hint = 'Enter your location (area name)...'; break;
        case 1: hint = 'Max distance in km (e.g. 5)...';    break;
        case 2: hint = 'Max fees in ₹ (e.g. 1000)...';      break;
        case 3: hint = 'Min rating (0-5, e.g. 4)...';       break;
      }
    }

    final isNumeric = _uiStage == 'FILTERS' && _filterStep >= 1;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(
          color: Colors.black.withOpacity(0.06),
          blurRadius: 10,
          offset: const Offset(0, -3),
        )],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              enabled: !_inputDisabled,
              keyboardType:
                  isNumeric ? TextInputType.number : TextInputType.text,
              decoration: InputDecoration(
                hintText: hint,
                hintStyle:
                    TextStyle(color: Colors.grey.shade400, fontSize: 14),
                filled: true,
                fillColor:
                    _inputDisabled ? Colors.grey.shade100 : lightPurple,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 18, vertical: 12),
              ),
              onSubmitted: _send,
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () => _send(_controller.text),
            child: CircleAvatar(
              radius: 24,
              backgroundColor: _inputDisabled ? Colors.grey : primary,
              child: const Icon(Icons.send, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}