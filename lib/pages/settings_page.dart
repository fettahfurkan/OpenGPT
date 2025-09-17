import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/database_helper.dart';
import '../services/openrouter_service.dart';
import '../services/theme_service.dart';
import '../services/voice_service.dart';
import '../models/voice_settings.dart';
import '../theme/app_theme.dart';
import '../utils/responsive_utils.dart';
import '../utils/animation_config.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage>
    with TickerProviderStateMixin {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final VoiceService _voiceService = VoiceService();

  List<Map<String, dynamic>> _apiKeys = [];
  List<Map<String, dynamic>> _models = [];
  bool _isLoading = true;
  VoiceSettings _voiceSettings = const VoiceSettings();

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadData();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: AnimationConfig.slowDuration,
      vsync: this,
    );

    _slideController = AnimationController(
      duration: AnimationConfig.extraSlowDuration,
      vsync: this,
    );

    _fadeAnimation = AnimationConfig.createFadeAnimation(
      controller: _fadeController,
      curve: Curves.easeOut,
    );

    _slideAnimation = AnimationConfig.createSlideAnimation(
      controller: _slideController,
      begin: const Offset(0, 0.3),
      curve: AnimationConfig.defaultCurve,
    );
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final apiKeys = await _dbHelper.getApiKeys();
      final models = await _dbHelper.getModels();
      
      // Ses servisi başlat
      await _voiceService.initialize();
      
      // Ses ayarlarını yükle
      _voiceSettings = _voiceService.voiceSettings;

      setState(() {
        _apiKeys = apiKeys;
        _models = models;
        _isLoading = false;
      });

      _fadeController.forward();
      _slideController.forward();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showMessage('Veriler yüklenirken hata: $e', isError: true);
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
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
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return Column(
      children: [
        _buildAppBar(context),
        Expanded(child: _buildContent(context)),
      ],
    );
  }

  Widget _buildTabletLayout(BuildContext context) {
    return Column(
      children: [
        _buildAppBar(context),
        Expanded(
          child: Container(
            constraints: BoxConstraints(
              maxWidth: ResponsiveUtils.getMaxContentWidth(context),
            ),
            child: _buildContent(context),
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
              Expanded(child: _buildContent(context)),
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
                child: Text(
                  'Ayarlar',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              const ThemeToggleButton(),

              IconButton(
                onPressed: _loadData,
                icon: const Icon(Icons.refresh),
                tooltip: 'Yenile',
              ),
            ],
          ),
        ),
      ),
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
            'Ayar Kategorileri',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 24),

          _buildSidebarItem(
            context,
            icon: Icons.key,
            title: 'API Anahtarları',
            subtitle: '${_apiKeys.length} anahtar',
            onTap: () {},
          ),

          const SizedBox(height: 12),

          _buildSidebarItem(
            context,
            icon: Icons.model_training,
            title: 'AI Modelleri',
            subtitle: '${_models.length} model',
            onTap: () {},
          ),

          const SizedBox(height: 12),

          _buildSidebarItem(
            context,
            icon: Icons.security,
            title: 'Güvenlik',
            subtitle: 'Şifre ayarları',
            onTap: () {},
          ),

          const SizedBox(height: 32),

          // App info
          Container(
            padding: const EdgeInsets.all(20),
            decoration: AppTheme.glassmorphism(context),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: theme.colorScheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Uygulama Bilgisi',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'AI Chat Assistant',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Sürüm 1.0.0',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.colorScheme.outline.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withOpacity(0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 20, color: theme.colorScheme.primary),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingWidget(context);
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: SafeScrollView(
          child: Column(
            children: [
              _buildPasswordSection(context),
              SizedBox(
                height: ResponsiveUtils.getResponsiveValue(
                  context,
                  mobile: 24,
                  tablet: 32,
                  desktop: 40,
                ),
              ),
              _buildVoiceSettingsSection(context),
              SizedBox(
                height: ResponsiveUtils.getResponsiveValue(
                  context,
                  mobile: 24,
                  tablet: 32,
                  desktop: 40,
                ),
              ),
              _buildApiKeysSection(context),
              SizedBox(
                height: ResponsiveUtils.getResponsiveValue(
                  context,
                  mobile: 24,
                  tablet: 32,
                  desktop: 40,
                ),
              ),
              _buildModelsSection(context),
              const SizedBox(height: 40),
            ],
          ),
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
            'Ayarlar yükleniyor...',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordSection(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: AppTheme.glassmorphism(context),
      child: Card(
        elevation: 0,
        color: Colors.transparent,
        child: Padding(
          padding: ResponsiveUtils.getResponsivePadding(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: AppTheme.accentGradient,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.security,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Giriş Şifresi',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Uygulamaya giriş için kullanılan şifre',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _showChangePasswordDialog,
                  icon: const Icon(Icons.lock_outline),
                  label: const Text('Şifre Değiştir'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.accentOrange,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(
                      vertical: ResponsiveUtils.getResponsiveValue(
                        context,
                        mobile: 16,
                        tablet: 18,
                        desktop: 20,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildApiKeysSection(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: AppTheme.glassmorphism(context),
      child: Card(
        elevation: 0,
        color: Colors.transparent,
        child: Padding(
          padding: ResponsiveUtils.getResponsivePadding(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.key, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'API Anahtarları',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_apiKeys.length} anahtar tanımlı',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _showAddApiKeyDialog,
                    icon: const Icon(Icons.add_circle_outline),
                    iconSize: 28,
                    tooltip: 'API Anahtarı Ekle',
                  ),
                ],
              ),

              const SizedBox(height: 24),

              if (_apiKeys.isEmpty)
                Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.key_off,
                        size: 48,
                        color: theme.colorScheme.onSurface.withOpacity(0.4),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Henüz API anahtarı eklenmemiş',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed: _showAddApiKeyDialog,
                        icon: const Icon(Icons.add),
                        label: const Text('İlk Anahtarı Ekle'),
                      ),
                    ],
                  ),
                )
              else
                Column(
                  children: _apiKeys
                      .map((apiKey) => _buildApiKeyTile(context, apiKey))
                      .toList(),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildApiKeyTile(BuildContext context, Map<String, dynamic> apiKey) {
    final theme = Theme.of(context);
    final isActive = apiKey['isActive'] == 1;
    final keyValue = apiKey['keyValue'] as String;
    final maskedKey = keyValue.length > 10
        ? '${keyValue.substring(0, 10)}...${keyValue.substring(keyValue.length - 4)}'
        : keyValue;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: isActive ? AppTheme.primaryGradient.scale(0.1) : null,
        color: isActive
            ? null
            : theme.colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive
              ? theme.colorScheme.primary
              : theme.colorScheme.outline.withOpacity(0.2),
          width: isActive ? 2 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isActive
                        ? theme.colorScheme.primary.withOpacity(0.2)
                        : theme.colorScheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    isActive ? Icons.star : Icons.key_outlined,
                    color: isActive
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurface.withOpacity(0.6),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            apiKey['keyName'],
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: isActive
                                  ? theme.colorScheme.primary
                                  : null,
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
                      const SizedBox(height: 4),
                      Text(
                        maskedKey,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontFamily: 'monospace',
                          color: theme.colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) => _handleApiKeyAction(value, apiKey),
                  itemBuilder: (context) => [
                    if (!isActive)
                      const PopupMenuItem(
                        value: 'activate',
                        child: ListTile(
                          leading: Icon(Icons.check_circle),
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
                    const PopupMenuItem(
                      value: 'delete',
                      child: ListTile(
                        leading: Icon(Icons.delete, color: Colors.red),
                        title: Text('Sil', style: TextStyle(color: Colors.red)),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            if (!isActive) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _setActiveApiKey(apiKey['id']),
                      child: const Text('Aktif Yap'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildModelsSection(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: AppTheme.glassmorphism(context),
      child: Card(
        elevation: 0,
        color: Colors.transparent,
        child: Padding(
          padding: ResponsiveUtils.getResponsivePadding(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: AppTheme.secondaryGradient,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.model_training,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'AI Modelleri',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_models.length} model tanımlı',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.secondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _showAddModelDialog,
                    icon: const Icon(Icons.add_circle_outline),
                    iconSize: 28,
                    tooltip: 'Model Ekle',
                  ),
                ],
              ),

              const SizedBox(height: 24),

              if (_models.isEmpty)
                Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.model_training_outlined,
                        size: 48,
                        color: theme.colorScheme.onSurface.withOpacity(0.4),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Henüz model eklenmemiş',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed: _showAddModelDialog,
                        icon: const Icon(Icons.add),
                        label: const Text('İlk Modeli Ekle'),
                      ),
                    ],
                  ),
                )
              else
                Column(
                  children: _models
                      .map((model) => _buildModelTile(context, model))
                      .toList(),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModelTile(BuildContext context, Map<String, dynamic> model) {
    final theme = Theme.of(context);
    final isActive = model['isActive'] == 1;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: isActive ? AppTheme.secondaryGradient.scale(0.1) : null,
        color: isActive
            ? null
            : theme.colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive
              ? theme.colorScheme.secondary
              : theme.colorScheme.outline.withOpacity(0.2),
          width: isActive ? 2 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isActive
                        ? theme.colorScheme.secondary.withOpacity(0.2)
                        : theme.colorScheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    isActive ? Icons.stars : Icons.model_training_outlined,
                    color: isActive
                        ? theme.colorScheme.secondary
                        : theme.colorScheme.onSurface.withOpacity(0.6),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              model['name'],
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: isActive
                                    ? theme.colorScheme.secondary
                                    : null,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isActive) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.secondary.withOpacity(
                                  0.2,
                                ),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'Aktif',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.secondary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        model['apiModel'],
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontFamily: 'monospace',
                          color: theme.colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) => _handleModelAction(value, model),
                  itemBuilder: (context) => [
                    if (!isActive)
                      const PopupMenuItem(
                        value: 'activate',
                        child: ListTile(
                          leading: Icon(Icons.check_circle),
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
                    const PopupMenuItem(
                      value: 'delete',
                      child: ListTile(
                        leading: Icon(Icons.delete, color: Colors.red),
                        title: Text('Sil', style: TextStyle(color: Colors.red)),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            if (!isActive) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _setActiveModel(model['id']),
                      child: const Text('Aktif Yap'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Message handling
  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError
            ? Theme.of(context).colorScheme.error
            : Theme.of(context).colorScheme.primary,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // Action handlers
  void _handleApiKeyAction(String action, Map<String, dynamic> apiKey) {
    switch (action) {
      case 'activate':
        _setActiveApiKey(apiKey['id']);
        break;
      case 'edit':
        _showEditApiKeyDialog(apiKey);
        break;
      case 'delete':
        _deleteApiKey(apiKey['id'], apiKey['keyName']);
        break;
    }
  }

  void _handleModelAction(String action, Map<String, dynamic> model) {
    switch (action) {
      case 'activate':
        _setActiveModel(model['id']);
        break;
      case 'edit':
        _showEditModelDialog(model);
        break;
      case 'delete':
        _deleteModel(model['id'], model['name']);
        break;
    }
  }

  // API Key methods
  void _showAddApiKeyDialog() {
    final nameController = TextEditingController();
    final keyController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('API Anahtarı Ekle'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Anahtar Adı',
                  hintText: 'Örn: Ana API Key',
                  border: OutlineInputBorder(),
                ),
                maxLength: 50,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: keyController,
                decoration: const InputDecoration(
                  labelText: 'API Anahtarı',
                  hintText: 'sk-or-v1-...',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
                maxLength: 200,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('İptal'),
          ),
          FilledButton(
            onPressed: () =>
                _addApiKey(nameController.text, keyController.text),
            child: const Text('Ekle'),
          ),
        ],
      ),
    );
  }

  void _showEditApiKeyDialog(Map<String, dynamic> apiKey) {
    final nameController = TextEditingController(text: apiKey['keyName']);
    final keyController = TextEditingController(text: apiKey['keyValue']);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('API Anahtarı Düzenle'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Anahtar Adı',
                  border: OutlineInputBorder(),
                ),
                maxLength: 50,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: keyController,
                decoration: const InputDecoration(
                  labelText: 'API Anahtarı',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
                maxLength: 200,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('İptal'),
          ),
          FilledButton(
            onPressed: () => _updateApiKey(
              apiKey['id'],
              nameController.text,
              keyController.text,
            ),
            child: const Text('Güncelle'),
          ),
        ],
      ),
    );
  }

  Future<void> _addApiKey(String name, String key) async {
    if (name.trim().isEmpty || key.trim().isEmpty) {
      _showMessage('Lütfen tüm alanları doldurun.', isError: true);
      return;
    }

    try {
      await _dbHelper.insertApiKey(name.trim(), key.trim());
      Navigator.of(context).pop();
      _showMessage('API anahtarı başarıyla eklendi.');
      _loadData();
    } catch (e) {
      _showMessage('API anahtarı eklenirken hata: $e', isError: true);
    }
  }

  Future<void> _updateApiKey(int id, String name, String key) async {
    if (name.trim().isEmpty || key.trim().isEmpty) {
      _showMessage('Lütfen tüm alanları doldurun.', isError: true);
      return;
    }

    try {
      await _dbHelper.updateApiKey(id, name.trim(), key.trim());
      Navigator.of(context).pop();
      _showMessage('API anahtarı başarıyla güncellendi.');
      OpenRouterService.clearCache();
      _loadData();
    } catch (e) {
      _showMessage('API anahtarı güncellenirken hata: $e', isError: true);
    }
  }

  Future<void> _setActiveApiKey(int id) async {
    try {
      await _dbHelper.setActiveApiKey(id);
      _showMessage('API anahtarı aktif edildi.');
      OpenRouterService.clearCache();
      _loadData();
    } catch (e) {
      _showMessage('API anahtarı aktif edilirken hata: $e', isError: true);
    }
  }

  Future<void> _deleteApiKey(int id, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('API Anahtarını Sil'),
        content: Text(
          '"$name" API anahtarını silmek istediğinizden emin misiniz?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('İptal'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Sil'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _dbHelper.deleteApiKey(id);
        _showMessage('API anahtarı başarıyla silindi.');
        OpenRouterService.clearCache();
        _loadData();
      } catch (e) {
        _showMessage('API anahtarı silinirken hata: $e', isError: true);
      }
    }
  }

  // Model methods
  void _showAddModelDialog() {
    final nameController = TextEditingController();
    final apiModelController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Model Ekle'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Model Adı',
                  hintText: 'Örn: GPT-4 Turbo',
                  border: OutlineInputBorder(),
                ),
                maxLength: 50,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: apiModelController,
                decoration: const InputDecoration(
                  labelText: 'API Model ID',
                  hintText: 'Örn: openai/gpt-4-turbo',
                  border: OutlineInputBorder(),
                ),
                maxLength: 100,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('İptal'),
          ),
          FilledButton(
            onPressed: () =>
                _addModel(nameController.text, apiModelController.text),
            child: const Text('Ekle'),
          ),
        ],
      ),
    );
  }

  void _showEditModelDialog(Map<String, dynamic> model) {
    final nameController = TextEditingController(text: model['name']);
    final apiModelController = TextEditingController(text: model['apiModel']);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Model Düzenle'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Model Adı',
                  border: OutlineInputBorder(),
                ),
                maxLength: 50,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: apiModelController,
                decoration: const InputDecoration(
                  labelText: 'API Model ID',
                  border: OutlineInputBorder(),
                ),
                maxLength: 100,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('İptal'),
          ),
          FilledButton(
            onPressed: () => _updateModel(
              model['id'],
              nameController.text,
              apiModelController.text,
            ),
            child: const Text('Güncelle'),
          ),
        ],
      ),
    );
  }

  Future<void> _addModel(String name, String apiModel) async {
    if (name.trim().isEmpty || apiModel.trim().isEmpty) {
      _showMessage('Lütfen tüm alanları doldurun.', isError: true);
      return;
    }

    try {
      await _dbHelper.insertModel(name.trim(), apiModel.trim());
      Navigator.of(context).pop();
      _showMessage('Model başarıyla eklendi.');
      OpenRouterService.clearCache();
      _loadData();
    } catch (e) {
      _showMessage('Model eklenirken hata: $e', isError: true);
    }
  }

  Future<void> _updateModel(int id, String name, String apiModel) async {
    if (name.trim().isEmpty || apiModel.trim().isEmpty) {
      _showMessage('Lütfen tüm alanları doldurun.', isError: true);
      return;
    }

    try {
      await _dbHelper.updateModel(id, name.trim(), apiModel.trim());
      Navigator.of(context).pop();
      _showMessage('Model başarıyla güncellendi.');
      OpenRouterService.clearCache();
      _loadData();
    } catch (e) {
      _showMessage('Model güncellenirken hata: $e', isError: true);
    }
  }

  Future<void> _setActiveModel(int id) async {
    try {
      await _dbHelper.setActiveModel(id);
      _showMessage('Model aktif edildi.');
      OpenRouterService.clearCache();
      _loadData();
    } catch (e) {
      _showMessage('Model aktif edilirken hata: $e', isError: true);
    }
  }

  Future<void> _deleteModel(int id, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Modeli Sil'),
        content: Text('"$name" modelini silmek istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('İptal'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Sil'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _dbHelper.deleteModel(id);
        _showMessage('Model başarıyla silindi.');
        OpenRouterService.clearCache();
        _loadData();
      } catch (e) {
        _showMessage('Model silinirken hata: $e', isError: true);
      }
    }
  }

  // Password methods
  void _showChangePasswordDialog() {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool obscureCurrentPassword = true;
    bool obscureNewPassword = true;
    bool obscureConfirmPassword = true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Şifre Değiştir'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: currentPasswordController,
                  obscureText: obscureCurrentPassword,
                  decoration: InputDecoration(
                    labelText: 'Mevcut Şifre',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscureCurrentPassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          obscureCurrentPassword = !obscureCurrentPassword;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: newPasswordController,
                  obscureText: obscureNewPassword,
                  decoration: InputDecoration(
                    labelText: 'Yeni Şifre',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscureNewPassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          obscureNewPassword = !obscureNewPassword;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: confirmPasswordController,
                  obscureText: obscureConfirmPassword,
                  decoration: InputDecoration(
                    labelText: 'Yeni Şifre Tekrar',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscureConfirmPassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          obscureConfirmPassword = !obscureConfirmPassword;
                        });
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('İptal'),
            ),
            FilledButton(
              onPressed: () => _changePassword(
                context,
                currentPasswordController.text,
                newPasswordController.text,
                confirmPasswordController.text,
              ),
              child: const Text('Değiştir'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _changePassword(
    BuildContext context,
    String currentPassword,
    String newPassword,
    String confirmPassword,
  ) async {
    if (currentPassword.isEmpty ||
        newPassword.isEmpty ||
        confirmPassword.isEmpty) {
      _showMessage('Tüm alanları doldurun.', isError: true);
      return;
    }

    if (newPassword != confirmPassword) {
      _showMessage('Yeni şifreler eşleşmiyor.', isError: true);
      return;
    }

    if (newPassword.length < 3) {
      _showMessage('Yeni şifre en az 3 karakter olmalıdır.', isError: true);
      return;
    }

    try {
      final isCurrentPasswordCorrect = await _dbHelper.verifyPassword(
        currentPassword,
      );
      if (!isCurrentPasswordCorrect) {
        _showMessage('Mevcut şifre yanlış.', isError: true);
        return;
      }

      await _dbHelper.updatePassword(newPassword);

      Navigator.of(context).pop();
      _showMessage('Şifre başarıyla değiştirildi.');
    } catch (e) {
      _showMessage('Şifre değiştirilirken hata: $e', isError: true);
    }
  }

  Widget _buildVoiceSettingsSection(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: AppTheme.glassmorphism(context),
      child: Card(
        elevation: 0,
        color: Colors.transparent,
        child: Padding(
          padding: ResponsiveUtils.getResponsivePadding(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: AppTheme.accentGradient,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.record_voice_over,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ses Ayarları',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Sesli mesaj yazma ve okuma ayarları',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // TTS Açık/Kapalı
              _buildVoiceToggle(
                context,
                title: 'Mesajları Sesle Oku',
                subtitle: 'Gelen mesajları sesli olarak okur',
                value: _voiceSettings.isTtsEnabled,
                onChanged: (value) {
                  _updateVoiceSettings(_voiceSettings.copyWith(isTtsEnabled: value));
                },
                icon: Icons.volume_up,
              ),
              
              const SizedBox(height: 16),
              
              // Speech to Text Açık/Kapalı
              _buildVoiceToggle(
                context,
                title: 'Sesle Mesaj Yaz',
                subtitle: 'Mikrofon ile sesli mesaj yazabilirsiniz',
                value: _voiceSettings.isSpeechToTextEnabled,
                onChanged: (value) {
                  _updateVoiceSettings(_voiceSettings.copyWith(isSpeechToTextEnabled: value));
                },
                icon: Icons.mic,
              ),
              
              const SizedBox(height: 24),
              
              // Ses Cinsiyeti
              _buildVoiceGenderSelector(context),
              
              const SizedBox(height: 24),
              
              // Konuşma Hızı
              _buildVoiceSpeedSlider(context),
              
              const SizedBox(height: 24),
              
              // Ses Tonu
              _buildVoicePitchSlider(context),
              
              const SizedBox(height: 24),
              
              // Test Butonu
              _buildVoiceTestButton(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVoiceToggle(
    BuildContext context, {
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
    required IconData icon,
  }) {
    final theme = Theme.of(context);
    
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: value ? theme.colorScheme.primary : theme.colorScheme.onSurface.withOpacity(0.6),
        ),
        title: Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
        trailing: Switch(
          value: value,
          onChanged: onChanged,
          activeColor: theme.colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildVoiceGenderSelector(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ses Cinsiyeti',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildGenderOption(
                context,
                title: 'Kadın Ses',
                value: 'female',
                isSelected: _voiceSettings.voiceGender == 'female',
                icon: Icons.woman,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildGenderOption(
                context,
                title: 'Erkek Ses',
                value: 'male',
                isSelected: _voiceSettings.voiceGender == 'male',
                icon: Icons.man,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGenderOption(
    BuildContext context, {
    required String title,
    required String value,
    required bool isSelected,
    required IconData icon,
  }) {
    final theme = Theme.of(context);
    
    return GestureDetector(
      onTap: () {
        _updateVoiceSettings(_voiceSettings.copyWith(voiceGender: value));
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected 
            ? theme.colorScheme.primary.withOpacity(0.1)
            : theme.colorScheme.surfaceVariant.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected 
              ? theme.colorScheme.primary
              : theme.colorScheme.outline.withOpacity(0.2),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected 
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurface.withOpacity(0.6),
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isSelected 
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurface,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVoiceSpeedSlider(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Konuşma Hızı',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '${(_voiceSettings.speechRate * 100).round()}%',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: theme.colorScheme.primary,
            inactiveTrackColor: theme.colorScheme.outline.withOpacity(0.3),
            thumbColor: theme.colorScheme.primary,
            overlayColor: theme.colorScheme.primary.withOpacity(0.2),
          ),
          child: Slider(
            value: _voiceSettings.speechRate,
            min: 0.1,
            max: 1.0,
            divisions: 18,
            onChanged: (value) {
              _updateVoiceSettings(_voiceSettings.copyWith(speechRate: value));
            },
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Yavaş',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            Text(
              'Hızlı',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildVoicePitchSlider(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Ses Tonu',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '${(_voiceSettings.pitch * 100).round()}%',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: theme.colorScheme.primary,
            inactiveTrackColor: theme.colorScheme.outline.withOpacity(0.3),
            thumbColor: theme.colorScheme.primary,
            overlayColor: theme.colorScheme.primary.withOpacity(0.2),
          ),
          child: Slider(
            value: _voiceSettings.pitch,
            min: 0.5,
            max: 2.0,
            divisions: 15,
            onChanged: (value) {
              _updateVoiceSettings(_voiceSettings.copyWith(pitch: value));
            },
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Alçak',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            Text(
              'Yüksek',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildVoiceTestButton(BuildContext context) {
    final theme = Theme.of(context);
    
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _voiceSettings.isTtsEnabled ? () => _testVoice(context) : null,
        icon: const Icon(Icons.play_arrow),
        label: const Text('Ses Testi'),
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Future<void> _updateVoiceSettings(VoiceSettings newSettings) async {
    setState(() {
      _voiceSettings = newSettings;
    });
    
    await _voiceService.updateVoiceSettings(newSettings);
  }

  Future<void> _testVoice(BuildContext context) async {
    const testText = 'Merhaba! Bu bir ses testi mesajıdır. Ses ayarlarınız bu şekilde çalışmaktadır.';
    
    try {
      await _voiceService.speak(testText);
      _showMessage('Ses testi başlatıldı.');
    } catch (e) {
      _showMessage('Ses testi başlatılırken hata: $e', isError: true);
    }
  }
}
