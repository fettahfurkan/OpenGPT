import 'package:flutter/material.dart';
import '../models/system_prompt.dart';
import '../services/database_helper.dart';
import '../theme/app_theme.dart';
import '../utils/responsive_utils.dart';
import '../services/theme_service.dart';

class SystemPromptSettingsPage extends StatefulWidget {
  const SystemPromptSettingsPage({super.key});

  @override
  State<SystemPromptSettingsPage> createState() =>
      _SystemPromptSettingsPageState();
}

class _SystemPromptSettingsPageState extends State<SystemPromptSettingsPage>
    with TickerProviderStateMixin {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final TextEditingController _searchTextController = TextEditingController();

  List<SystemPrompt> _systemPrompts = [];
  List<SystemPrompt> _filteredPrompts = [];
  bool _isLoading = true;
  bool _isSearching = false;
  SystemPrompt? _activePrompt;

  late AnimationController _fadeController;
  late AnimationController _searchAnimController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _searchAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadSystemPrompts();
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
          _filteredPrompts = _systemPrompts;
        } else {
          _filteredPrompts = _systemPrompts
              .where(
                (prompt) =>
                    prompt.name.toLowerCase().contains(query) ||
                    prompt.content.toLowerCase().contains(query),
              )
              .toList();
        }
      });
    });
  }

  Future<void> _loadSystemPrompts() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final prompts = await _dbHelper.getSystemPrompts();
      final activePrompt = await _dbHelper.getActiveSystemPrompt();

      setState(() {
        _systemPrompts = prompts;
        _filteredPrompts = prompts;
        _activePrompt = activePrompt;
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
            content: Text('Sistem promptları yüklenirken hata oluştu: $e'),
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
            child: _buildPromptsList(context),
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
              child: _buildPromptsList(context),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return Row(
      children: [
        // Sidebar
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

        // Main content
        Expanded(
          child: Column(
            children: [
              _buildAppBar(context),
              _buildSearchBar(context),
              Expanded(
                child: SingleChildScrollView(
                  child: _buildPromptsList(context),
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
                      'Sistem Promptları',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (_activePrompt != null)
                      Text(
                        'Aktif: ${_activePrompt!.name}',
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

              IconButton(
                onPressed: _loadSystemPrompts,
                icon: const Icon(Icons.refresh),
                tooltip: 'Yenile',
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
                  hintText: 'Prompt ismi veya içeriğinde ara...',
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
                      _filteredPrompts = _systemPrompts;
                    } else {
                      _filteredPrompts = _systemPrompts
                          .where(
                            (prompt) =>
                                prompt.name.toLowerCase().contains(
                                  query.toLowerCase(),
                                ) ||
                                prompt.content.toLowerCase().contains(
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
            label: 'Yeni Prompt',
            onTap: _createNewSystemPrompt,
          ),

          const SizedBox(height: 16),

          _buildSidebarButton(
            context,
            icon: Icons.refresh,
            label: 'Yenile',
            onTap: _loadSystemPrompts,
          ),

          const SizedBox(height: 32),

          // Active prompt info
          if (_activePrompt != null) ...[
            Container(
              padding: const EdgeInsets.all(20),
              decoration: AppTheme.glassmorphism(context),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.star,
                        color: theme.colorScheme.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Aktif Prompt',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _activePrompt!.name,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _activePrompt!.content,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],

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
                const SizedBox(height: 8),
                _buildStatItem(
                  context,
                  'Toplam Prompt',
                  '${_systemPrompts.length}',
                ),
                const SizedBox(height: 8),
                _buildStatItem(
                  context,
                  'Özel Prompt',
                  '${_systemPrompts.where((p) => !p.isDefault).length}',
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

  Widget _buildPromptsList(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingWidget(context);
    }

    if (_filteredPrompts.isEmpty) {
      return _buildEmptyState(context);
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: RefreshIndicator(
        onRefresh: _loadSystemPrompts,
        child: ResponsiveGrid(
          children: _filteredPrompts.map((prompt) {
            final index = _filteredPrompts.indexOf(prompt);
            return AnimatedContainer(
              duration: Duration(milliseconds: 200 + (index * 50)),
              curve: Curves.easeOutCubic,
              child: _buildPromptCard(context, prompt),
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
            'Sistem promptları yükleniyor...',
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
                isSearching ? Icons.search_off : Icons.psychology_outlined,
                size: 64,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              isSearching
                  ? 'Arama sonucu bulunamadı'
                  : 'Henüz sistem promptu yok',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              isSearching
                  ? 'Farklı anahtar kelimeler deneyin'
                  : 'İlk sistem promptunuzu oluşturmak için + butonuna basın',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            if (!isSearching) ...[
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: _createNewSystemPrompt,
                icon: const Icon(Icons.add),
                label: const Text('Yeni Prompt Oluştur'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPromptCard(BuildContext context, SystemPrompt systemPrompt) {
    final theme = Theme.of(context);
    final isActive = _activePrompt?.id == systemPrompt.id;

    return Card(
      elevation: 0,
      color: Colors.transparent,
      child: Container(
        decoration: isActive
            ? BoxDecoration(
                gradient: AppTheme.primaryGradient.scale(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: theme.colorScheme.primary, width: 2),
              )
            : AppTheme.glassmorphism(context),
        child: InkWell(
          onTap: () => _viewSystemPrompt(systemPrompt),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Text(
                            systemPrompt.name,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: isActive
                                  ? theme.colorScheme.primary
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (systemPrompt.isDefault)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.accentOrange.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Varsayılan',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: AppTheme.accentOrange,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          if (isActive) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary.withOpacity(
                                  0.2,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Aktif',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
                      onSelected: (value) =>
                          _handlePromptAction(value, systemPrompt),
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'view',
                          child: ListTile(
                            leading: Icon(Icons.visibility),
                            title: Text('Görüntüle'),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                        if (!isActive)
                          const PopupMenuItem(
                            value: 'activate',
                            child: ListTile(
                              leading: Icon(Icons.star),
                              title: Text('Aktif Yap'),
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        const PopupMenuItem(
                          value: 'edit',
                          child: ListTile(
                            leading: Icon(Icons.edit),
                            title: Text('Düzenle'),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                        if (!systemPrompt.isDefault)
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
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Footer
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 14,
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _formatTime(systemPrompt.createdAt),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (!isActive)
                      SizedBox(
                        height: 28,
                        child: OutlinedButton(
                          onPressed: () => _setActiveSystemPrompt(systemPrompt),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            'Aktif Yap',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      )
                    else
                      Container(
                        height: 28,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.check_circle,
                              size: 14,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Aktif',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ],
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
      onPressed: _createNewSystemPrompt,
      icon: const Icon(Icons.add),
      label: Text(ResponsiveUtils.isMobile(context) ? 'Yeni' : 'Yeni Prompt'),
      tooltip: 'Yeni Sistem Promptu Oluştur',
    );
  }

  // Action handlers
  void _handlePromptAction(String action, SystemPrompt systemPrompt) {
    switch (action) {
      case 'view':
        _viewSystemPrompt(systemPrompt);
        break;
      case 'activate':
        _setActiveSystemPrompt(systemPrompt);
        break;
      case 'edit':
        _editSystemPrompt(systemPrompt);
        break;
      case 'delete':
        _showDeleteConfirmation(systemPrompt);
        break;
    }
  }

  void _viewSystemPrompt(SystemPrompt systemPrompt) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.psychology,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(systemPrompt.name)),
          ],
        ),
        content: SingleChildScrollView(
          child: Text(
            systemPrompt.content,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.5),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Kapat'),
          ),
          if (!systemPrompt.isActive)
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop();
                _setActiveSystemPrompt(systemPrompt);
              },
              child: const Text('Aktif Yap'),
            ),
        ],
      ),
    );
  }

  void _editSystemPrompt(SystemPrompt systemPrompt) {
    final nameController = TextEditingController(text: systemPrompt.name);
    final contentController = TextEditingController(text: systemPrompt.content);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sistem Promptunu Düzenle'),
        content: SizedBox(
          width: double.maxFinite,
          height: MediaQuery.of(context).size.height * 0.6,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'İsim',
                    border: OutlineInputBorder(),
                  ),
                  maxLength: 100,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: contentController,
                  decoration: const InputDecoration(
                    labelText: 'İçerik',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                  maxLines: 8,
                  maxLength: 2000,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('İptal'),
          ),
          FilledButton(
            onPressed: () async {
              await _updateSystemPrompt(
                systemPrompt,
                nameController.text.trim(),
                contentController.text.trim(),
              );
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

  void _showDeleteConfirmation(SystemPrompt systemPrompt) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sistem Promptunu Sil'),
        content: Text(
          '\"${systemPrompt.name}\" sistem promptunu silmek istediğinizden emin misiniz? Bu işlem geri alınamaz.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('İptal'),
          ),
          FilledButton(
            onPressed: () async {
              await _deleteSystemPrompt(systemPrompt);
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

  Future<void> _createNewSystemPrompt() async {
    final nameController = TextEditingController();
    final contentController = TextEditingController();

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Yeni Sistem Promptu'),
        content: SizedBox(
          width: double.maxFinite,
          height: MediaQuery.of(context).size.height * 0.6,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'İsim',
                    border: OutlineInputBorder(),
                    hintText: 'Örn: Kod Asistanı',
                  ),
                  maxLength: 100,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: contentController,
                  decoration: const InputDecoration(
                    labelText: 'İçerik',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                    hintText:
                        'Sistemin nasıl davranması gerektiğini açıklayın...',
                  ),
                  maxLines: 8,
                  maxLength: 2000,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('İptal'),
          ),
          FilledButton(
            onPressed: () {
              final name = nameController.text.trim();
              final content = contentController.text.trim();
              if (name.isNotEmpty && content.isNotEmpty) {
                Navigator.of(context).pop({'name': name, 'content': content});
              }
            },
            child: const Text('Oluştur'),
          ),
        ],
      ),
    );

    if (result != null) {
      try {
        final newPrompt = SystemPrompt.create(
          name: result['name']!,
          content: result['content']!,
        );
        await _dbHelper.insertSystemPrompt(newPrompt);
        await _loadSystemPrompts();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('\"${result['name']}\" sistem promptu oluşturuldu'),
              backgroundColor: Theme.of(context).colorScheme.primary,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Sistem promptu oluşturulurken hata: $e'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    }
  }

  Future<void> _updateSystemPrompt(
    SystemPrompt systemPrompt,
    String newName,
    String newContent,
  ) async {
    if (newName.isEmpty || newContent.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('İsim ve içerik boş olamaz'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    try {
      final updatedPrompt = systemPrompt
          .copyWithName(newName)
          .copyWithContent(newContent);
      await _dbHelper.updateSystemPrompt(updatedPrompt);
      await _loadSystemPrompts();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('\"$newName\" sistem promptu güncellendi'),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Güncelleme hatası: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _setActiveSystemPrompt(SystemPrompt systemPrompt) async {
    try {
      await _dbHelper.setActiveSystemPrompt(systemPrompt.id);
      await _loadSystemPrompts();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '\"${systemPrompt.name}\" aktif sistem promptu olarak ayarlandı',
            ),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Aktif sistem promptu ayarlanırken hata: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _deleteSystemPrompt(SystemPrompt systemPrompt) async {
    try {
      await _dbHelper.deleteSystemPrompt(systemPrompt.id);
      await _loadSystemPrompts();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('\"${systemPrompt.name}\" sistem promptu silindi'),
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

  String _formatTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
