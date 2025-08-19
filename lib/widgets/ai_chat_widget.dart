import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:wolfstock/models/chat_message.dart';
import '../controllers/ai_controller.dart';

class AIChatWidget extends StatefulWidget {
  const AIChatWidget({Key? key}) : super(key: key);

  @override
  _AIChatWidgetState createState() => _AIChatWidgetState();
}

class _AIChatWidgetState extends State<AIChatWidget>
    with SingleTickerProviderStateMixin {
  final AIController _aiController = Get.find<AIController>();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Listen to changes in the AI controller's chat messages
    ever(_aiController.chatMessages, (_) => _scrollToBottom());
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildQuickActions(),
        Expanded(child: _buildChatMessages()),
        _buildMessageInput(),
      ],
    );
  }

  /// Quick action buttons for common queries
  Widget _buildQuickActions() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildQuickActionChip(
              '📊 Market Trends',
              () => _aiController.sendQuickQuestion(
                'What are the current market trends?',
              ),
            ),
            _buildQuickActionChip(
              '🔍 Analyze AAPL',
              () => _aiController.sendQuickQuestion(
                'Analyze AAPL stock for investment',
              ),
            ),
            _buildQuickActionChip(
              '💰 SIP Plans',
              () => _aiController.sendQuickQuestion(
                'Best SIP recommendations for beginners',
              ),
            ),
            _buildQuickActionChip(
              '📈 Portfolio Review',
              () => _aiController.sendQuickQuestion('Review my portfolio'),
            ),
            _buildQuickActionChip(
              '🎓 Learn Investing',
              () =>
                  _aiController.sendQuickQuestion('Explain investment basics'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionChip(String label, VoidCallback onPressed) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ActionChip(
        label: Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
        onPressed: () {
          HapticFeedback.lightImpact();
          onPressed();
        },
        backgroundColor: const Color(0xFF00D4AA).withOpacity(0.1),
        side: BorderSide(color: const Color(0xFF00D4AA).withOpacity(0.3)),
        labelStyle: TextStyle(color: const Color(0xFF00D4AA)),
      ),
    );
  }

  /// Build chat messages using the AI controller's message list
  Widget _buildChatMessages() {
    return Obx(() {
      final messages = _aiController.chatMessages;
      final isTyping = _aiController.isTyping.value;

      return ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: messages.length + (isTyping ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == messages.length && isTyping) {
            return _buildTypingIndicator();
          }
          return _buildMessageBubble(messages[index]);
        },
      );
    });
  }

  Widget _buildMessageBubble(ChatMessage message) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: message.isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isUser) ...[
            Container(
              width: 35,
              height: 35,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF00D4AA), Color(0xFF007AFF)],
                ),
                borderRadius: BorderRadius.circular(17.5),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00D4AA).withOpacity(0.3),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: const Icon(
                Icons.psychology, // Brain icon for AI
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
          ],
          Flexible(
            child: GestureDetector(
              onLongPress: () => _showMessageOptions(message),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: message.isUser
                      ? const LinearGradient(
                          colors: [Color(0xFF00D4AA), Color(0xFF007AFF)],
                        )
                      : null,
                  color: message.isUser
                      ? null
                      : Get.isDarkMode
                      ? const Color(0xFF2D2D2D)
                      : Colors.grey[100],
                  borderRadius: BorderRadius.circular(18).copyWith(
                    bottomRight: message.isUser
                        ? const Radius.circular(4)
                        : null,
                    bottomLeft: message.isUser
                        ? null
                        : const Radius.circular(4),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!message.isUser) ...[
                      Row(
                        children: [
                          Icon(
                            Icons.psychology,
                            size: 14,
                            color: const Color(0xFF00D4AA),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'WolfStock AI • Powered by Gemini',
                            style: TextStyle(
                              fontSize: 11,
                              color: const Color(0xFF00D4AA),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                    ],
                    Text(
                      message.text,
                      style: TextStyle(
                        color: message.isUser
                            ? Colors.white
                            : Get.isDarkMode
                            ? Colors.white
                            : Colors.black87,
                        fontSize: 15,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatTime(message.timestamp),
                      style: TextStyle(
                        fontSize: 10,
                        color: message.isUser ? Colors.white70 : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (message.isUser) ...[
            const SizedBox(width: 10),
            CircleAvatar(
              radius: 17.5,
              backgroundColor: const Color(0xFF00D4AA).withOpacity(0.1),
              child: const Icon(
                Icons.person,
                color: Color(0xFF00D4AA),
                size: 20,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 35,
            height: 35,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF00D4AA), Color(0xFF007AFF)],
              ),
              borderRadius: BorderRadius.circular(17.5),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00D4AA).withOpacity(0.3),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: const Icon(Icons.psychology, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Get.isDarkMode
                  ? const Color(0xFF2D2D2D)
                  : Colors.grey[100],
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.psychology,
                      size: 14,
                      color: const Color(0xFF00D4AA),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'WolfStock AI is thinking...',
                      style: TextStyle(
                        fontSize: 11,
                        color: const Color(0xFF00D4AA),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _TypingDots(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Get.isDarkMode ? const Color(0xFF2D2D2D) : Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey.withOpacity(0.2), width: 1),
        ),
      ),
      child: Row(
        children: [
          // Clear chat button
          // IconButton(
          //   onPressed: () {
          //     HapticFeedback.lightImpact();
          //     _showClearChatDialog();
          //   },
          //   icon: Icon(Icons.refresh, color: Colors.grey[600], size: 20),
          //   tooltip: 'Clear Chat',
          // ),
          // const SizedBox(width: 8),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Get.isDarkMode
                    ? const Color(0xFF1A1A1A)
                    : Colors.grey[100],
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: Colors.grey.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  hintText: 'Ask about stocks, market trends, SIP plans...',
                  hintStyle: TextStyle(color: Colors.grey[600], fontSize: 14),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                maxLines: null,
                maxLength: 500, // Limit message length
                buildCounter:
                    (
                      context, {
                      required currentLength,
                      required isFocused,
                      maxLength,
                    }) {
                      return currentLength > 400
                          ? Text(
                              '${maxLength! - currentLength} chars left',
                              style: TextStyle(
                                fontSize: 10,
                                color: currentLength > 450
                                    ? Colors.red
                                    : Colors.grey,
                              ),
                            )
                          : null;
                    },
                onSubmitted: (value) => _sendMessage(),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Obx(
            () => Container(
              decoration: BoxDecoration(
                gradient: _messageController.text.trim().isNotEmpty
                    ? const LinearGradient(
                        colors: [Color(0xFF00D4AA), Color(0xFF007AFF)],
                      )
                    : null,
                color: _messageController.text.trim().isEmpty
                    ? Colors.grey
                    : null,
                shape: BoxShape.circle,
                boxShadow: _messageController.text.trim().isNotEmpty
                    ? [
                        BoxShadow(
                          color: const Color(0xFF00D4AA).withOpacity(0.3),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ]
                    : null,
              ),
              child: IconButton(
                onPressed: _aiController.isChatLoading.value
                    ? null
                    : _sendMessage,
                icon: _aiController.isChatLoading.value
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : const Icon(Icons.send, color: Colors.white, size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty || _aiController.isChatLoading.value) return;

    HapticFeedback.lightImpact();
    _messageController.clear();

    try {
      // The AI controller handles adding messages to its chat list
      await _aiController.getChatResponse(message);
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to send message. Please try again.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showClearChatDialog() {
    Get.dialog(
      AlertDialog(
        backgroundColor: Get.isDarkMode
            ? const Color(0xFF2D2D2D)
            : Colors.white,
        title: const Text('Clear Chat'),
        content: const Text('Are you sure you want to clear the chat history?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel', style: TextStyle(color: Colors.white)),
          ),
          ElevatedButton(
            onPressed: () {
              _aiController.clearChat();
              Get.back();
              HapticFeedback.mediumImpact();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00D4AA),
            ),
            child: const Text('Clear', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showMessageOptions(ChatMessage message) {
    if (message.isUser) return;

    HapticFeedback.lightImpact();
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Get.isDarkMode ? const Color(0xFF2D2D2D) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.copy),
              title: const Text('Copy Message'),
              onTap: () {
                Clipboard.setData(ClipboardData(text: message.text));
                Get.back();
                Get.snackbar('Copied', 'Message copied to clipboard');
              },
            ),
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('Share'),
              onTap: () {
                // Implement share functionality
                Get.back();
                Get.snackbar('Share', 'Share functionality coming soon');
              },
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}

/// Animated typing dots widget
class _TypingDots extends StatefulWidget {
  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<Animation<double>> _dotOpacities;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat();

    _dotOpacities = List.generate(3, (i) {
      return Tween<double>(begin: 0.3, end: 1.0).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(i * 0.2, 0.6 + i * 0.2, curve: Curves.easeInOut),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        return AnimatedBuilder(
          animation: _controller,
          builder: (_, __) => Opacity(
            opacity: _dotOpacities[i].value,
            child: Container(
              width: 6,
              height: 6,
              margin: EdgeInsets.only(left: i == 0 ? 0 : 4),
              decoration: BoxDecoration(
                color: const Color(0xFF00D4AA),
                shape: BoxShape.circle,
              ),
            ),
          ),
        );
      }),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
