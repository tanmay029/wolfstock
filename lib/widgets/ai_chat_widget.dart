import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/ai_controller.dart';

class AIChatWidget extends StatefulWidget {
  const AIChatWidget({Key? key}) : super(key: key);

  @override
  _AIChatWidgetState createState() => _AIChatWidgetState();
}

class _AIChatWidgetState extends State<AIChatWidget> {
  final AIController _aiController = Get.find<AIController>();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  final RxList<ChatMessage> _messages = <ChatMessage>[
    ChatMessage(
      text: "Hi! I'm your AI investment advisor. Ask me about stocks, investment strategies, or market trends!",
      isUser: false,
    ),
  ].obs;

  final RxBool _isTyping = false.obs;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Obx(() => ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            itemCount: _messages.length + (_isTyping.value ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == _messages.length && _isTyping.value) {
                return _buildTypingIndicator();
              }
              return _buildMessageBubble(_messages[index]);
            },
          )),
        ),
        _buildMessageInput(),
      ],
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
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
              ),
              child: const Icon(
                Icons.smart_toy,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: message.isUser 
                    ? const Color(0xFF00D4AA)
                    : Get.isDarkMode ? const Color(0xFF2D2D2D) : Colors.grey[100],
                borderRadius: BorderRadius.circular(15),
              ),
              child: Text(
                message.text,
                style: TextStyle(
                  color: message.isUser 
                      ? Colors.white 
                      : Get.isDarkMode ? Colors.white : Colors.black,
                  fontSize: 14,
                  height: 1.4,
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
            ),
            child: const Icon(
              Icons.smart_toy,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Get.isDarkMode ? const Color(0xFF2D2D2D) : Colors.grey[100],
              borderRadius: BorderRadius.circular(15),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDot(0),
                const SizedBox(width: 4),
                _buildDot(1),
                const SizedBox(width: 4),
                _buildDot(2),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDot(int index) {
    return AnimatedBuilder(
      animation: AnimationController(
        duration: const Duration(milliseconds: 600),
        vsync: Scaffold.of(context),
      )..repeat(),
      builder: (context, child) {
        final controller = AnimationController(
          duration: const Duration(milliseconds: 600),
          vsync: Scaffold.of(context),
        )..repeat();
        
        return FadeTransition(
          opacity: Tween(begin: 0.3, end: 1.0).animate(
            CurvedAnimation(
              parent: controller,
              curve: Interval(
                index * 0.2,
                (index + 1) * 0.2,
                curve: Curves.easeInOut,
              ),
            ),
          ),
          child: Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: Colors.grey,
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Get.isDarkMode ? const Color(0xFF2D2D2D) : Colors.white,
        border: Border(
          top: BorderSide(
            color: Colors.grey.withOpacity(0.2),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Ask about investments...',
                hintStyle: const TextStyle(color: Colors.grey),
                filled: true,
                fillColor: Get.isDarkMode ? const Color(0xFF1A1A1A) : Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              maxLines: null,
              onSubmitted: (value) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF00D4AA), Color(0xFF007AFF)],
              ),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              onPressed: _sendMessage,
              icon: const Icon(Icons.send, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    // Add user message
    _messages.add(ChatMessage(text: message, isUser: true));
    _messageController.clear();
    _scrollToBottom();

    // Show typing indicator
    _isTyping.value = true;

    try {
      // Get AI response
      final response = await _aiController.getChatResponse(message);
      
      // Remove typing indicator and add AI response
      _isTyping.value = false;
      _messages.add(ChatMessage(text: response, isUser: false));
      _scrollToBottom();
    } catch (e) {
      _isTyping.value = false;
      _messages.add(ChatMessage(
        text: "Sorry, I'm having trouble responding right now. Please try again later.",
        isUser: false,
      ));
      _scrollToBottom();
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

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}

class ChatMessage {
  final String text;
  final bool isUser;

  ChatMessage({required this.text, required this.isUser});
}
