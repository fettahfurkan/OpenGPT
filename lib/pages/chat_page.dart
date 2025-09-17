import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';

import '../models/chat_message.dart';
import '../models/conversation.dart';
import '../models/system_prompt.dart';
import '../services/openrouter_service.dart';
import '../services/database_helper.dart';
import '../services/theme_service.dart';
import '../services/voice_service.dart';
import '../theme/app_theme.dart';
import '../utils/responsive_utils.dart';
import '../utils/page_transitions.dart';
import '../utils/animation_config.dart';
import 'settings_page.dart';
import 'conversation_history_page.dart';
import 'system_prompt_settings_page.dart';

class ChatPage extends StatefulWidget {
  final String? conversationId;

  const ChatPage({super.key, this.conversationId});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _messageFocus = FocusNode();
  final List<ChatMessage> _messages = [];
  final List<Map<String, dynamic>> _conversationHistory = [];

  bool _isLoading = false;

  late AnimationController _typingController;
  late AnimationController _fabController;
  late Animation<double> _typingAnimation;
  late Animation<double> _fabAnimation;

  final ImagePicker _picker = ImagePicker();
  XFile? _selectedImage;
  Uint8List? _selectedImageBytes;

  final DatabaseHelper _dbHelper = DatabaseHelper();
  final VoiceService _voiceService = VoiceService();
  late String _conversationId;
  Conversation? _currentConversation;
  SystemPrompt? _currentSystemPrompt;
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeConversation();
    _setupMessageListener();
    _initializeVoiceService();
  }

  void _initializeAnimations() {
    _typingController = AnimationController(
      duration: AnimationConfig.extraSlowDuration,
      vsync: this,
    );

    _fabController = AnimationController(
      duration: AnimationConfig.normalDuration,
      vsync: this,
    );

    _typingAnimation = AnimationConfig.createFadeAnimation(
      controller: _typingController,
      curve: Curves.easeInOut,
    );

    _fabAnimation = AnimationConfig.createScaleAnimation(
      controller: _fabController,
      begin: 0.0,
      end: 1.0,
      curve: Curves.elasticOut,
    );

    _typingController.repeat(reverse: true);
  }

  void _setupMessageListener() {
    _messageController.addListener(() {
      final hasText = _messageController.text.trim().isNotEmpty;
      if (hasText && !_fabController.isCompleted) {
        _fabController.forward();
      } else if (!hasText && _fabController.isCompleted) {
        _fabController.reverse();
      }
    });
  }

  Future<void> _initializeConversation() async {
    try {
      if (widget.conversationId != null) {
        _conversationId = widget.conversationId!;
        _currentConversation = await _dbHelper.getConversation(_conversationId);
      } else {
        final conversations = await _dbHelper.getConversations();
        if (conversations.isNotEmpty) {
          _currentConversation = conversations.first;
          _conversationId = _currentConversation!.id;
        } else {
          final defaultConversation = Conversation.create(
            title: 'Yeni Konuşma',
          );
          await _dbHelper.insertConversation(defaultConversation);
          _currentConversation = defaultConversation;
          _conversationId = defaultConversation.id;
        }
      }

      _currentSystemPrompt = await _dbHelper.getActiveSystemPrompt();
      await _loadChatHistory();
    } catch (e) {
      debugPrint('Konuşma initialize edilirken hata: $e');
      _conversationId = 'default';
      await _loadChatHistory();
    }
  }

  Future<void> _loadChatHistory() async {
    try {
      final messages = await _dbHelper.getMessages(
        conversationId: _conversationId,
      );
      setState(() {
        _messages.clear();
        _messages.addAll(messages);

        _conversationHistory.clear();
        for (var message in messages) {
          _conversationHistory.add({
            'role': message.isUser ? 'user' : 'assistant',
            'content': message.content,
          });
        }
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom(animated: false);
      });
    } catch (e) {
      debugPrint('Chat geçmişi yüklenirken hata: $e');
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _messageFocus.dispose();
    _typingController.dispose();
    _fabController.dispose();
    _voiceService.removeListener(_onVoiceServiceChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      resizeToAvoidBottomInset: true,
      body: GestureDetector(
        onTap: () {
          // Klavyeyi kapat
          FocusScope.of(context).unfocus();
        },
        child: ResponsiveBuilder(
          mobile: (context, constraints) => _buildMobileLayout(context),
          tablet: (context, constraints) => _buildTabletLayout(context),
          desktop: (context, constraints) => _buildDesktopLayout(context),
        ),
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return Column(
      children: [
        _buildAppBar(context),
        Expanded(
          child: GestureDetector(
            onTap: () {
              // Klavyeyi kapat
              FocusScope.of(context).unfocus();
            },
            child: _buildChatArea(context),
          ),
        ),
        if (_isLoading) _buildTypingIndicator(context),
        _buildMessageInput(context),
      ],
    );
  }

  Widget _buildTabletLayout(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 300,
          decoration: BoxDecoration(
            color: Theme.of(
              context,
            ).colorScheme.surfaceVariant.withOpacity(0.3),
            border: Border(
              right: BorderSide(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
              ),
            ),
          ),
          child: _buildSidebar(context),
        ),
        Expanded(
          child: Column(
            children: [
              _buildAppBar(context),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    // Klavyeyi kapat
                    FocusScope.of(context).unfocus();
                  },
                  child: _buildChatArea(context),
                ),
              ),
              if (_isLoading) _buildTypingIndicator(context),
              _buildMessageInput(context),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 350,
          decoration: BoxDecoration(
            color: Theme.of(
              context,
            ).colorScheme.surfaceVariant.withOpacity(0.3),
            border: Border(
              right: BorderSide(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
              ),
            ),
          ),
          child: _buildSidebar(context),
        ),
        Expanded(
          child: Column(
            children: [
              _buildAppBar(context),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    // Klavyeyi kapat
                    FocusScope.of(context).unfocus();
                  },
                  child: _buildChatArea(context),
                ),
              ),
              if (_isLoading) _buildTypingIndicator(context),
              _buildMessageInput(context),
            ],
          ),
        ),
        if (ResponsiveUtils.getWidth(context) > 1200)
          Container(
            width: 300,
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.surfaceVariant.withOpacity(0.3),
              border: Border(
                left: BorderSide(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                ),
              ),
            ),
            child: _buildInfoPanel(context),
          ),
      ],
    );
  }

  Widget _buildAppBar(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: AppTheme.glassmorphism(context),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              if (ResponsiveUtils.isMobile(context))
                IconButton(
                  onPressed: _showMobileMenu,
                  icon: const Icon(Icons.menu),
                  tooltip: 'Menü',
                ),

              // Conversation info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _currentConversation?.title ?? 'AI Chat Assistant',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (_currentSystemPrompt != null)
                      Text(
                        'Prompt: ${_currentSystemPrompt!.name}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                  ],
                ),
              ),

              // Action buttons
              IconButton(
                onPressed: () => _createNewConversation(),
                icon: const Icon(Icons.add),
                tooltip: 'Yeni Sohbet',
              ),
              const ThemeToggleButton(),
              if (!ResponsiveUtils.isMobile(context)) ...[
                IconButton(
                  onPressed: _navigateToHistory,
                  icon: const Icon(Icons.history),
                  tooltip: 'Konuşma Geçmişi',
                ),
                IconButton(
                  onPressed: _navigateToSystemPrompts,
                  icon: const Icon(Icons.psychology_outlined),
                  tooltip: 'Sistem Promptları',
                ),
              ],

              PopupMenuButton<String>(
                onSelected: _handleMenuAction,
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'clear_chat',
                    child: ListTile(
                      leading: Icon(Icons.refresh),
                      title: Text('Sohbeti Temizle'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'rename_conversation',
                    child: ListTile(
                      leading: Icon(Icons.edit),
                      title: Text('Yeniden Adlandır'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  if (ResponsiveUtils.isMobile(context)) ...[
                    const PopupMenuItem(
                      value: 'history',
                      child: ListTile(
                        leading: Icon(Icons.history),
                        title: Text('Konuşma Geçmişi'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'prompts',
                      child: ListTile(
                        leading: Icon(Icons.psychology_outlined),
                        title: Text('Sistem Promptları'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                  const PopupMenuItem(
                    value: 'settings',
                    child: ListTile(
                      leading: Icon(Icons.settings),
                      title: Text('Ayarlar'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
                child: const Icon(Icons.more_vert),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSidebar(BuildContext context) {
    return Column(
      children: [
        _buildQuickActions(context),
        Expanded(child: _buildRecentConversations(context)),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hızlı Eylemler',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          _buildQuickActionButton(
            context,
            icon: Icons.add_circle_outline,
            label: 'Yeni Konuşma',
            onTap: _createNewConversation,
          ),
          const SizedBox(height: 8),
          _buildQuickActionButton(
            context,
            icon: Icons.psychology_outlined,
            label: 'Sistem Promptları',
            onTap: _navigateToSystemPrompts,
          ),
          const SizedBox(height: 8),
          _buildQuickActionButton(
            context,
            icon: Icons.settings_outlined,
            label: 'Ayarlar',
            onTap: _navigateToSettings,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.colorScheme.outline.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: theme.colorScheme.primary),
            const SizedBox(width: 12),
            Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentConversations(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Son Konuşmalar',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: FutureBuilder<List<Conversation>>(
              future: _dbHelper.getConversations(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  final conversations = snapshot.data!.take(10).toList();
                  return ListView.builder(
                    itemCount: conversations.length,
                    itemBuilder: (context, index) {
                      final conversation = conversations[index];
                      final isActive = conversation.id == _conversationId;

                      return _buildConversationTile(
                        context,
                        conversation,
                        isActive,
                      );
                    },
                  );
                }
                return const Center(child: CircularProgressIndicator());
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConversationTile(
    BuildContext context,
    Conversation conversation,
    bool isActive,
  ) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => _switchConversation(conversation.id),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isActive
                ? theme.colorScheme.primaryContainer.withOpacity(0.5)
                : null,
            borderRadius: BorderRadius.circular(12),
            border: isActive
                ? Border.all(color: theme.colorScheme.primary.withOpacity(0.3))
                : Border.all(color: theme.colorScheme.outline.withOpacity(0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                conversation.title,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                  color: isActive ? theme.colorScheme.primary : null,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.message_outlined,
                    size: 12,
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${conversation.messageCount} mesaj',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoPanel(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Konuşma Bilgileri',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),

          // Message count
          _buildInfoCard(
            context,
            icon: Icons.message_outlined,
            title: 'Mesaj Sayısı',
            value: '${_messages.length}',
          ),

          const SizedBox(height: 12),

          // System prompt
          _buildInfoCard(
            context,
            icon: Icons.psychology_outlined,
            title: 'Aktif Prompt',
            value: _currentSystemPrompt?.name ?? 'Yok',
          ),

          const SizedBox(height: 12),

          // Model info
          FutureBuilder<String>(
            future: OpenRouterService.modelName,
            builder: (context, snapshot) {
              return _buildInfoCard(
                context,
                icon: Icons.model_training_outlined,
                title: 'AI Modeli',
                value: snapshot.data ?? 'Yükleniyor...',
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
  }) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatArea(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxWidth: ResponsiveUtils.getMaxContentWidth(context),
      ),
      child: _messages.isEmpty
          ? _buildEmptyState(context)
          : _buildMessagesList(context),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    return SingleChildScrollView(
      child: Container(
        constraints: BoxConstraints(
          minHeight: MediaQuery.of(context).size.height - 
                     MediaQuery.of(context).padding.top - 
                     MediaQuery.of(context).padding.bottom - 
                     keyboardHeight - 200, // AppBar ve input alanı için alan bırak
        ),
        padding: ResponsiveUtils.getResponsivePadding(context),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(32),
              ),
              child: Icon(Icons.auto_awesome, size: 64, color: Colors.white),
            ),
            const SizedBox(height: 32),
            Text(
              'AI Asistanınızla Konuşmaya Başlayın',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Herhangi bir konu hakkında soru sorun, yardım isteyin veya sadece sohbet edin.',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            if (keyboardHeight == 0) ...[  // Klavye kapalıyken göster
              const SizedBox(height: 32),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: [
                  _buildSuggestionChip(context, '💡 Nasıl yardım edebilirim?'),
                  _buildSuggestionChip(context, '🚀 İpuçları göster'),
                  _buildSuggestionChip(context, '📝 Kod yazmana yardım et'),
                  _buildSuggestionChip(context, '🎨 Yaratıcı fikirler ver'),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionChip(BuildContext context, String text) {
    final theme = Theme.of(context);

    return ActionChip(
      onPressed: () {
        _messageController.text = text.split(' ').skip(1).join(' ');
        _messageFocus.requestFocus();
      },
      label: Text(text),
      backgroundColor: theme.colorScheme.primaryContainer.withOpacity(0.5),
      side: BorderSide(color: theme.colorScheme.primary.withOpacity(0.3)),
    );
  }

  Widget _buildMessagesList(BuildContext context) {
    return ListView.builder(
      controller: _scrollController,
      physics: const ClampingScrollPhysics(),
      padding: ResponsiveUtils.getResponsivePadding(context),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        return _buildMessageBubble(context, _messages[index], index);
      },
    );
  }

  Widget _buildMessageBubble(
    BuildContext context,
    ChatMessage message,
    int index,
  ) {
    final theme = Theme.of(context);
    final isUser = message.isUser;
    final isLastMessage = index == _messages.length - 1;

    return Container(
      margin: EdgeInsets.only(
        bottom: isLastMessage ? 24 : 16,
        left: isUser ? 64 : 0,
        right: isUser ? 0 : 64,
      ),
      child: Row(
        mainAxisAlignment: isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            _buildAvatar(context, isUser),
            const SizedBox(width: 12),
          ],

          Flexible(
            child: GestureDetector(
              onLongPress: () => _showMessageOptions(context, message),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  gradient: isUser ? AppTheme.primaryGradient : null,
                  color: isUser
                      ? null
                      : theme.colorScheme.surfaceVariant.withOpacity(0.5),
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(24),
                    topRight: const Radius.circular(24),
                    bottomLeft: Radius.circular(isUser ? 24 : 6),
                    bottomRight: Radius.circular(isUser ? 6 : 24),
                  ),
                  border: !isUser
                      ? Border.all(
                          color: theme.colorScheme.outline.withOpacity(0.2),
                        )
                      : null,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (message.imageBytes != null) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.memory(
                          message.imageBytes!,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              height: 100,
                              color: theme.colorScheme.errorContainer,
                              child: Center(
                                child: Icon(
                                  Icons.error,
                                  color: theme.colorScheme.error,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      if (message.content.isNotEmpty) const SizedBox(height: 12),
                    ],

                    if (message.content.isNotEmpty)
                      Text(
                        message.content,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: isUser
                              ? Colors.white
                              : theme.colorScheme.onSurface,
                          height: 1.4,
                        ),
                      ),

                    const SizedBox(height: 8),

                    Text(
                      _formatTime(message.timestamp),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isUser
                            ? Colors.white.withOpacity(0.7)
                            : theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          if (isUser) ...[
            const SizedBox(width: 12),
            _buildAvatar(context, isUser),
          ],
        ],
      ),
    );
  }

  Widget _buildAvatar(BuildContext context, bool isUser) {
    final theme = Theme.of(context);

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        gradient: isUser
            ? AppTheme.secondaryGradient
            : AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color:
                (isUser
                        ? theme.colorScheme.secondary
                        : theme.colorScheme.primary)
                    .withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(
        isUser ? Icons.person : Icons.auto_awesome,
        color: Colors.white,
        size: 20,
      ),
    );
  }

  Widget _buildTypingIndicator(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const SizedBox(width: 52), // Avatar space
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: theme.colorScheme.outline.withOpacity(0.2),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      theme.colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                AnimatedBuilder(
                  animation: _typingAnimation,
                  builder: (context, child) {
                    return Text(
                      'Yazıyor${'.' * ((_typingAnimation.value * 3).floor() + 1)}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInput(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: AppTheme.glassmorphism(context),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: ResponsiveUtils.getResponsivePadding(context),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_selectedImage != null) _buildImagePreview(context),

                Row(
                  children: [
                    // Image picker button
                    IconButton(
                      onPressed: _showImagePicker,
                      icon: Icon(
                        Icons.camera_alt_outlined,
                        color: theme.colorScheme.primary,
                      ),
                      tooltip: 'Fotoğraf Ekle',
                    ),

                    // Message input field
                    Expanded(
                      child: Container(
                        constraints: const BoxConstraints(
                          maxHeight: 120, // Maksimum yükseklik sınırı
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceVariant.withOpacity(
                            0.5,
                          ),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: theme.colorScheme.outline.withOpacity(0.2),
                          ),
                        ),
                        child: TextField(
                          controller: _messageController,
                          focusNode: _messageFocus,
                          maxLines: null,
                          minLines: 1,
                          textCapitalization: TextCapitalization.sentences,
                          decoration: InputDecoration(
                            hintText: _isListening ? 'Dinleniyor...' : 'Mesajınızı yazın...',
                            hintStyle: TextStyle(
                              color: theme.colorScheme.onSurface.withOpacity(0.6),
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 16,
                            ),
                            suffixIcon: _buildVoiceButtons(context),
                          ),
                          onSubmitted: (_) => _sendMessage(),
                        ),
                      ),
                    ),

                    const SizedBox(width: 8),

                    // Send button
                    ScaleTransition(
                      scale: _fabAnimation,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: AppTheme.primaryGradient,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: theme.colorScheme.primary.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: IconButton(
                          onPressed: _isLoading ? null : _sendMessage,
                          icon: Icon(
                            _isLoading
                                ? Icons.hourglass_empty
                                : Icons.send_rounded,
                            color: Colors.white,
                          ),
                          tooltip: 'Gönder',
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImagePreview(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.memory(
              _selectedImageBytes!,
              width: 60,
              height: 60,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Seçilen fotoğraf',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  _selectedImage!.name,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              setState(() {
                _selectedImage = null;
                _selectedImageBytes = null;
              });
            },
            icon: Icon(Icons.close, color: theme.colorScheme.error),
            tooltip: 'Kaldır',
          ),
        ],
      ),
    );
  }

  // Helper methods
  void _showMobileMenu() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text('Konuşma Geçmişi'),
              onTap: () {
                Navigator.pop(context);
                _navigateToHistory();
              },
            ),
            ListTile(
              leading: const Icon(Icons.psychology_outlined),
              title: const Text('Sistem Promptları'),
              onTap: () {
                Navigator.pop(context);
                _navigateToSystemPrompts();
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Ayarlar'),
              onTap: () {
                Navigator.pop(context);
                _navigateToSettings();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showImagePicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Galeriden Seç'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Kamera ile Çek'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(source: source);
      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _selectedImage = image;
          _selectedImageBytes = bytes;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fotoğraf seçilirken hata oluştu: $e')),
      );
    }
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty && _selectedImage == null) return;

    HapticFeedback.lightImpact();

    final messageContent = message.isEmpty ? 'Fotoğraf gönderildi' : message;
    final userMessage = ChatMessage.user(
      messageContent,
      imagePath: _selectedImage?.path,
      imageBytes: _selectedImageBytes,
    );

    setState(() {
      _messages.add(userMessage);
      _isLoading = true;
    });

    // Save user message
    try {
      await _dbHelper.insertMessage(
        userMessage,
        conversationId: _conversationId,
      );
    } catch (e) {
      debugPrint('Kullanıcı mesajı kaydedilirken hata: $e');
    }

    // Add to conversation history
    _conversationHistory.add({'role': 'user', 'content': messageContent});

    _messageController.clear();
    final currentImageBytes = _selectedImageBytes;
    setState(() {
      _selectedImage = null;
      _selectedImageBytes = null;
    });
    _scrollToBottom();

    try {
      // Prepare full history with system prompt
      List<Map<String, dynamic>> fullHistory = [];

      if (_currentSystemPrompt != null) {
        fullHistory.add({
          'role': 'system',
          'content': _currentSystemPrompt!.content,
        });
      }

      fullHistory.addAll(_conversationHistory);

      final response = await OpenRouterService.sendMessage(
        messageContent,
        conversationHistory: fullHistory,
        imageBytes: currentImageBytes,
      );

      final botMessage = ChatMessage.bot(response);
      setState(() {
        _messages.add(botMessage);
      });

      // Save bot response
      try {
        await _dbHelper.insertMessage(
          botMessage,
          conversationId: _conversationId,
        );
      } catch (e) {
        debugPrint('Bot mesajı kaydedilirken hata: $e');
      }

      // Add bot response to history
      _conversationHistory.add({'role': 'assistant', 'content': response});

      // Bot mesajını sesle oku
      _speakBotMessage(response);

      // Update conversation message count
      await _updateConversationMessageCount();
    } catch (e) {
      final errorMessage = ChatMessage.error(e.toString());
      setState(() {
        _messages.add(errorMessage);
      });

      // Save error message
      try {
        await _dbHelper.insertMessage(
          errorMessage,
          conversationId: _conversationId,
        );
      } catch (dbError) {
        debugPrint('Hata mesajı kaydedilirken hata: $dbError');
      }

      // Remove user message from history on error
      if (_conversationHistory.isNotEmpty &&
          _conversationHistory.last['content'] == messageContent) {
        _conversationHistory.removeLast();
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom({bool animated = true}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        if (animated) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        } else {
          _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
        }
      }
    });
  }

  Future<void> _updateConversationMessageCount() async {
    try {
      if (_currentConversation != null) {
        await _dbHelper.updateConversationMessageCount(
          _conversationId,
          _messages.length,
        );
      }
    } catch (e) {
      debugPrint('Conversation mesaj sayısı güncellenirken hata: $e');
    }
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'clear_chat':
        _clearChat();
        break;
      case 'rename_conversation':
        _showRenameDialog();
        break;
      case 'history':
        _navigateToHistory();
        break;
      case 'prompts':
        _navigateToSystemPrompts();
        break;
      case 'settings':
        _navigateToSettings();
        break;
    }
  }

  void _showMessageOptions(BuildContext context, ChatMessage message) {
    final theme = Theme.of(context);
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurface.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: Icon(
                  Icons.copy,
                  color: theme.colorScheme.primary,
                ),
                title: const Text('Mesajı Kopyala'),
                onTap: () {
                  Navigator.pop(context);
                  _copyMessage(message.content);
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _copyMessage(String content) {
    if (content.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: content));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Mesaj kopyalandı'),
          backgroundColor: Theme.of(context).colorScheme.primary,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _navigateToHistory() {
    Navigator.of(context).pushSmooth(
      const ConversationHistoryPage(),
      type: PageTransitionType.slideRight,
    );
  }

  void _navigateToSystemPrompts() {
    Navigator.of(context)
        .pushSmooth(
          const SystemPromptSettingsPage(),
          type: PageTransitionType.fadeSlide,
        )
        .then((_) => _reloadSystemPrompt());
  }

  void _navigateToSettings() {
    Navigator.of(context).pushSmooth(
      const SettingsPage(),
      type: PageTransitionType.modal,
    );
  }

  Future<void> _reloadSystemPrompt() async {
    try {
      _currentSystemPrompt = await _dbHelper.getActiveSystemPrompt();
      setState(() {});
    } catch (e) {
      debugPrint('Sistem promptu yeniden yüklenirken hata: $e');
    }
  }

  void _showRenameDialog() {
    if (_currentConversation == null) return;

    final controller = TextEditingController(text: _currentConversation!.title);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konuşmayı Yeniden Adlandır'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Yeni ad',
            border: OutlineInputBorder(),
          ),
          maxLength: 100,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('İptal'),
          ),
          FilledButton(
            onPressed: () async {
              final newTitle = controller.text.trim();
              if (newTitle.isNotEmpty &&
                  newTitle != _currentConversation!.title) {
                await _renameConversation(newTitle);
              }
              if (mounted) {
                Navigator.of(context).pop();
              }
            },
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
  }

  Future<void> _renameConversation(String newTitle) async {
    try {
      if (_currentConversation != null) {
        final updatedConversation = _currentConversation!.copyWithTitle(
          newTitle,
        );
        await _dbHelper.updateConversation(updatedConversation);
        setState(() {
          _currentConversation = updatedConversation;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Konuşma "$newTitle" olarak yeniden adlandırıldı'),
              backgroundColor: Theme.of(context).colorScheme.primary,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Yeniden adlandırma hatası: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  void _clearChat() async {
    try {
      await _dbHelper.clearMessages(conversationId: _conversationId);
      setState(() {
        _messages.clear();
        _conversationHistory.clear();
      });
      await _updateConversationMessageCount();
    } catch (e) {
      debugPrint('Chat temizlenirken hata: $e');
    }
  }

  Future<void> _createNewConversation() async {
    final controller = TextEditingController();

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Yeni Konuşma'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Konuşma adı',
            border: OutlineInputBorder(),
            hintText: 'Örn: Flutter Soruları',
          ),
          maxLength: 100,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('İptal'),
          ),
          FilledButton(
            onPressed: () {
              final title = controller.text.trim();
              Navigator.of(context).pop(title.isEmpty ? 'Yeni Konuşma' : title);
            },
            child: const Text('Oluştur'),
          ),
        ],
      ),
    );

    if (result != null) {
      try {
        final newConversation = Conversation.create(title: result);
        await _dbHelper.insertConversation(newConversation);
        _switchConversation(newConversation.id);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Konuşma oluşturulurken hata: $e'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    }
  }

  Future<void> _switchConversation(String conversationId) async {
    if (_conversationId == conversationId) return;

    _conversationId = conversationId;
    _currentConversation = await _dbHelper.getConversation(conversationId);
    await _loadChatHistory();
    setState(() {});
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Şimdi';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}dk önce';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}sa önce';
    } else {
      return '${dateTime.day}/${dateTime.month} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }

  // Ses servisi başlatma
  Future<void> _initializeVoiceService() async {
    try {
      await _voiceService.initialize();
      _voiceService.addListener(_onVoiceServiceChanged);
    } catch (e) {
      debugPrint('Ses servisi başlatılırken hata: $e');
    }
  }

  void _onVoiceServiceChanged() {
    if (mounted) {
      setState(() {
        _isListening = _voiceService.isListening;
      });
    }
  }

  // Ses butonları widget'ı
  Widget _buildVoiceButtons(BuildContext context) {
    final theme = Theme.of(context);
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // TTS durdurma butonu (sadece konuşma sırasında görünür)
        if (_voiceService.isSpeaking)
          IconButton(
            onPressed: _stopSpeaking,
            icon: Icon(
              Icons.stop,
              color: theme.colorScheme.error,
            ),
            tooltip: 'Konuşmayı Durdur',
          ),
        
        // Mikrofon butonu
        IconButton(
          onPressed: _isListening ? _stopListening : _startListening,
          icon: Icon(
            _isListening ? Icons.mic : Icons.mic_none,
            color: _isListening 
              ? theme.colorScheme.error 
              : theme.colorScheme.primary,
          ),
          tooltip: _isListening ? 'Dinlemeyi Durdur' : 'Sesle Mesaj Yaz',
        ),
      ],
    );
  }

  // Sesli mesaj yazma başlat
  Future<void> _startListening() async {
    final hasPermission = await _voiceService.checkMicrophonePermission();
    if (!hasPermission) {
      _showSnackBar('Mikrofon izni gerekli', isError: true);
      return;
    }

    try {
      await _voiceService.startListening(
        onResult: (text) {
          if (text.isNotEmpty) {
            _messageController.text = text;
            _messageController.selection = TextSelection.fromPosition(
              TextPosition(offset: text.length),
            );
          }
        },
        onPartialResult: (text) {
          if (text.isNotEmpty) {
            _messageController.text = text;
            _messageController.selection = TextSelection.fromPosition(
              TextPosition(offset: text.length),
            );
          }
        },
      );
    } catch (e) {
      _showSnackBar('Ses tanıma başlatılırken hata: $e', isError: true);
    }
  }

  // Sesli mesaj yazma durdur
  Future<void> _stopListening() async {
    try {
      await _voiceService.stopListening();
    } catch (e) {
      debugPrint('Ses tanıma durdurulurken hata: $e');
    }
  }

  // Bot mesajını sesle oku
  Future<void> _speakBotMessage(String message) async {
    try {
      await _voiceService.speak(message);
    } catch (e) {
      debugPrint('Mesaj okunurken hata: $e');
    }
  }

  // Konuşmayı durdur
  Future<void> _stopSpeaking() async {
    try {
      await _voiceService.stopSpeaking();
    } catch (e) {
      debugPrint('Konuşma durdurulurken hata: $e');
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError 
          ? Theme.of(context).colorScheme.error
          : Theme.of(context).colorScheme.primary,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

 }
