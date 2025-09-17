import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/conversation.dart';
import '../services/database_helper.dart';
import '../theme/app_theme.dart';
import '../utils/responsive_utils.dart';
import '../services/theme_service.dart';
import '../utils/page_transitions.dart';
import 'chat_page.dart';

class ConversationHistoryPage extends StatefulWidget {
  const ConversationHistoryPage({super.key});

  @override
  State<ConversationHistoryPage> createState() =>
      _ConversationHistoryPageState();
}

class _ConversationHistoryPageState extends State<ConversationHistoryPage>
    with TickerProviderStateMixin {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final TextEditingController _searchTextController = TextEditingController();

  List<Conversation> _conversations = [];
  List<Conversation> _filteredConversations = [];
  bool _isLoading = true;
  bool _isSearching = false;

  late AnimationController _fadeController;
  late AnimationController _searchAnimController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _searchAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadConversations();
    _setupSearchListener();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _searchAnimController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeOut));

    _searchAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _searchAnimController, curve: Curves.easeInOut),
    );
  }

  void _setupSearchListener() {
    _searchTextController.addListener(() {
      final query = _searchTextController.text.toLowerCase();
      setState(() {
        if (query.isEmpty) {
          _filteredConversations = _conversations;
        } else {
          _filteredConversations = _conversations
              .where((conv) => conv.title.toLowerCase().contains(query))
              .toList();
        }
      });
    });
  }

  Future<void> _loadConversations() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final conversations = await _dbHelper.getConversations();

      setState(() {
        _conversations = conversations;
        _filteredConversations = conversations;
        _isLoading = false;
      });

      _fadeController.forward();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Konuşmalar yüklenirken hata oluştu: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _searchTextController.dispose();
    _fadeController.dispose();
    _searchAnimController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: ResponsiveBuilder(
        mobile: (context, constraints) => _buildMobileLayout(context),
        tablet: (context, constraints) => _buildTabletLayout(context),
        desktop: (context, constraints) => _buildDesktopLayout(context),
      ),
      floatingActionButton: _buildFloatingActionButton(context),
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return Column(
      children: [
        _buildAppBar(context),
        _buildSearchBar(context),
        Expanded(
          child: SingleChildScrollView(
            child: _buildConversationsList(context),
          ),
        ),
      ],
    );
  }

  Widget _buildTabletLayout(BuildContext context) {
    return Column(
      children: [
        _buildAppBar(context),
        _buildSearchBar(context),
        Expanded(
          child: SingleChildScrollView(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: ResponsiveUtils.getMaxContentWidth(context),
              ),
              child: _buildConversationsList(context),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return Row(
      children: [
        // Sidebar with actions
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

        // Main content
        Expanded(
          child: Column(
            children: [
              _buildAppBar(context),
              _buildSearchBar(context),
              Expanded(
                child: SingleChildScrollView(
                  child: Container(
                    constraints: BoxConstraints(
                      maxWidth: ResponsiveUtils.getMaxContentWidth(context),
                    ),
                    child: _buildConversationsList(context),
                  ),
                ),
              ),
            ],
          ),
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
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back),
                tooltip: 'Geri',
              ),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Konuşma Geçmişi',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${_conversations.length} konuşma',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),

              const ThemeToggleButton(),

              IconButton(
                onPressed: () {
                  setState(() {
                    _isSearching = !_isSearching;
                  });
                  if (_isSearching) {
                    _searchAnimController.forward();
                  } else {
                    _searchAnimController.reverse();
                    _searchTextController.clear();
                  }
                },
                icon: Icon(_isSearching ? Icons.close : Icons.search),
                tooltip: _isSearching ? 'Aramayı Kapat' : 'Ara',
              ),

              PopupMenuButton<String>(
                onSelected: _handleMenuAction,
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'refresh',
                    child: ListTile(
                      leading: Icon(Icons.refresh),
                      title: Text('Yenile'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete_all',
                    child: ListTile(
                      leading: Icon(Icons.delete_forever, color: Colors.red),
                      title: Text(
                        'Tümünü Sil',
                        style: TextStyle(color: Colors.red),
                      ),
                      contentPadding: EdgeInsets.zero,
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

  Widget _buildSearchBar(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedBuilder(
      animation: _searchAnimation,
      builder: (context, child) {
        return SizeTransition(
          sizeFactor: _searchAnimation,
          child: Container(
            padding: ResponsiveUtils.getResponsivePadding(context),
            child: Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: theme.colorScheme.outline.withOpacity(0.2),
                ),
              ),
              child: TextField(
                controller: _searchTextController,
                decoration: InputDecoration(
                  hintText: 'Konuşmalarda ara...',
                  prefixIcon: Icon(
                    Icons.search,
                    color: theme.colorScheme.primary,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
                onChanged: (query) {
                  setState(() {
                    if (query.isEmpty) {
                      _filteredConversations = _conversations;
                    } else {
                      _filteredConversations = _conversations
                          .where(
                            (conv) => conv.title.toLowerCase().contains(
                              query.toLowerCase(),
                            ),
                          )
                          .toList();
                    }
                  });
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSidebar(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hızlı Eylemler',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 24),

          _buildSidebarButton(
            context,
            icon: Icons.add_circle_outline,
            label: 'Yeni Konuşma',
            onTap: _createNewConversation,
          ),

          const SizedBox(height: 16),

          _buildSidebarButton(
            context,
            icon: Icons.refresh,
            label: 'Yenile',
            onTap: _loadConversations,
          ),

          const SizedBox(height: 32),

          // Statistics
          Container(
            padding: const EdgeInsets.all(20),
            decoration: AppTheme.glassmorphism(context),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'İstatistikler',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                _buildStatItem(
                  context,
                  'Toplam Konuşma',
                  '${_conversations.length}',
                ),
                const SizedBox(height: 8),
                _buildStatItem(
                  context,
                  'Toplam Mesaj',
                  '${_conversations.fold(0, (sum, conv) => sum + conv.messageCount)}',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarButton(
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

  Widget _buildStatItem(BuildContext context, String label, String value) {
    final theme = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildConversationsList(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingWidget(context);
    }

    if (_filteredConversations.isEmpty) {
      return _buildEmptyState(context);
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: RefreshIndicator(
        onRefresh: _loadConversations,
        child: ResponsiveGrid(
          children: _filteredConversations.map((conversation) {
            final index = _filteredConversations.indexOf(conversation);
            return AnimatedContainer(
              duration: Duration(milliseconds: 200 + (index * 50)),
              curve: Curves.easeOutCubic,
              child: _buildConversationCard(context, conversation),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildLoadingWidget(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: theme.colorScheme.primary),
          const SizedBox(height: 24),
          Text(
            'Konuşmalar yükleniyor...',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    final isSearching = _searchTextController.text.isNotEmpty;

    return Center(
      child: Container(
        padding: ResponsiveUtils.getResponsivePadding(context),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                gradient: isSearching
                    ? AppTheme.secondaryGradient
                    : AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(32),
              ),
              child: Icon(
                isSearching ? Icons.search_off : Icons.chat_bubble_outline,
                size: 64,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              isSearching ? 'Arama sonucu bulunamadı' : 'Henüz konuşma yok',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              isSearching
                  ? 'Farklı anahtar kelimeler deneyin'
                  : 'İlk konuşmanızı başlatmak için + butonuna basın',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            if (!isSearching) ...[
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: _createNewConversation,
                icon: const Icon(Icons.add),
                label: const Text('Yeni Konuşma Başlat'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildConversationCard(
    BuildContext context,
    Conversation conversation,
  ) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      color: Colors.transparent,
      child: Container(
        decoration: AppTheme.glassmorphism(context),
        child: InkWell(
          onTap: () => _openConversation(conversation),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with title and menu
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        conversation.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    PopupMenuButton<String>(
                      onSelected: (value) =>
                          _handleConversationAction(value, conversation),
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'open',
                          child: ListTile(
                            leading: Icon(Icons.open_in_new),
                            title: Text('Aç'),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'rename',
                          child: ListTile(
                            leading: Icon(Icons.edit),
                            title: Text('Yeniden Adlandır'),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: ListTile(
                            leading: Icon(Icons.delete, color: Colors.red),
                            title: Text(
                              'Sil',
                              style: TextStyle(color: Colors.red),
                            ),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ],
                      child: Icon(
                        Icons.more_vert,
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Stats
                Row(
                  children: [
                    Icon(
                      Icons.message_outlined,
                      size: 16,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${conversation.messageCount} mesaj',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.access_time,
                      size: 16,
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatTime(conversation.updatedAt),
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
      ),
    );
  }

  Widget _buildFloatingActionButton(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: _createNewConversation,
      icon: const Icon(Icons.add),
      label: Text(ResponsiveUtils.isMobile(context) ? 'Yeni' : 'Yeni Konuşma'),
      tooltip: 'Yeni Konuşma Başlat',
    );
  }

  // Action handlers
  void _handleMenuAction(String action) {
    switch (action) {
      case 'refresh':
        _loadConversations();
        break;
      case 'delete_all':
        _showDeleteAllConfirmation();
        break;
    }
  }

  void _handleConversationAction(String action, Conversation conversation) {
    switch (action) {
      case 'open':
        _openConversation(conversation);
        break;
      case 'rename':
        _showRenameDialog(conversation);
        break;
      case 'delete':
        _showDeleteConfirmation(conversation);
        break;
    }
  }

  void _showRenameDialog(Conversation conversation) {
    final controller = TextEditingController(text: conversation.title);

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
              if (newTitle.isNotEmpty && newTitle != conversation.title) {
                await _renameConversation(conversation, newTitle);
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

  void _showDeleteConfirmation(Conversation conversation) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konuşmayı Sil'),
        content: Text(
          '\"${conversation.title}\" konuşmasını silmek istediğinizden emin misiniz? Bu işlem geri alınamaz.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('İptal'),
          ),
          FilledButton(
            onPressed: () async {
              await _deleteConversation(conversation);
              if (mounted) {
                Navigator.of(context).pop();
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
  }

  void _showDeleteAllConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tüm Konuşmaları Sil'),
        content: const Text(
          'Tüm konuşmaları silmek istediğinizden emin misiniz? Bu işlem geri alınamaz.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('İptal'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _deleteAllConversations();
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Tümünü Sil'),
          ),
        ],
      ),
    );
  }

  Future<void> _renameConversation(
    Conversation conversation,
    String newTitle,
  ) async {
    try {
      final updatedConversation = conversation.copyWithTitle(newTitle);
      await _dbHelper.updateConversation(updatedConversation);
      await _loadConversations();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Konuşma "$newTitle" olarak yeniden adlandırıldı'),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
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

  Future<void> _deleteConversation(Conversation conversation) async {
    try {
      await _dbHelper.deleteConversation(conversation.id);
      await _loadConversations();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('\"${conversation.title}\" konuşması silindi'),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Silme hatası: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _deleteAllConversations() async {
    try {
      for (final conversation in _conversations) {
        await _dbHelper.deleteConversation(conversation.id);
      }
      await _loadConversations();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Tüm konuşmalar silindi'),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Silme hatası: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
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

        if (mounted) {
          Navigator.of(context).pushReplacementSmooth(
            ChatPage(conversationId: newConversation.id),
            type: PageTransitionType.slideLeft,
          );
        }
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

  void _openConversation(Conversation conversation) {
    Navigator.of(context).pushReplacementSmooth(
      ChatPage(conversationId: conversation.id),
      type: PageTransitionType.slideLeft,
    );
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
    } else if (difference.inDays < 7) {
      return '${difference.inDays}g önce';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }
}
