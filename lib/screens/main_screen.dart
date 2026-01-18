import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/checkin_model.dart';
import '../models/meshgram_enums.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/local_storage_service.dart';
import '../services/transport/transport_router.dart';
import '../theme/app_theme.dart';
import '../widgets/big_button.dart';
import '../widgets/screen_transitions.dart';
import '../widgets/status_card.dart';
import 'error_screen.dart';
import 'notifications_screen.dart';
import 'settings_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  String? _selectedStatus;
  UserModel? _user;
  CheckinModel? _lastCheckin;
  bool _isLoading = false;
  TransportType? _transport;
  int _meshNodeCount = 0;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadTransportStatus();
  }

  Future<void> _loadTransportStatus() async {
    final router = Provider.of<TransportRouter>(context, listen: false);
    final t = await router.selectTransport();
    final count = await router.nearbyMeshNodeCount;
    if (mounted) setState(() {
      _transport = t;
      _meshNodeCount = count;
    });
  }

  Future<void> _loadUserData() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final userId = authService.currentUser?.uid;
    
    if (userId == null) return;

    try {
      final firestoreService = Provider.of<FirestoreService>(context, listen: false);
      
      // Завантажити профіль користувача
      final user = await authService.getUserProfile();
      
      // Завантажити останній чекін
      final lastCheckin = await firestoreService.getLastCheckin(userId);
      
      if (mounted) {
        setState(() {
          _user = user;
          _lastCheckin = lastCheckin;
        });
      }
    } catch (e) {
      print('❌ Load user data error: $e');
    }
  }

  Future<void> _sendCheckin() async {
    if (_selectedStatus == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Оберіть статус'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    final authService = Provider.of<AuthService>(context, listen: false);
    final userId = authService.currentUser?.uid;
    final user = _user;
    
    if (userId == null || user == null) {
      // Показати помилку
      Navigator.of(context).push(
        ScreenTransitions.slideFromRight(
          ErrorScreen(
            type: ErrorType.noContacts,
            onBack: () {},
          ),
        ),
      );
      return;
    }

    if (user.contactIds.isEmpty) {
      // Немає контактів
      Navigator.of(context).push(
        ScreenTransitions.slideFromRight(
          ErrorScreen(
            type: ErrorType.noContacts,
            onBack: () => Navigator.of(context).pop(),
          ),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final transportRouter = Provider.of<TransportRouter>(context, listen: false);
      final localStorage = Provider.of<LocalStorageService>(context, listen: false);

      // Створити чекін
      final checkin = CheckinModel(
        id: 'checkin_${DateTime.now().millisecondsSinceEpoch}',
        userId: userId,
        status: _selectedStatus!,
        timestamp: DateTime.now(),
        recipientIds: user.contactIds,
      );

      // Зберегти локально (offline-first)
      await localStorage.savePendingCheckin(checkin);

      // Відправити через обраний транспорт (Firebase / MeshGram / тільки черга)
      try {
        final sent = await transportRouter.sendCheckin(checkin);
        if (sent == TransportType.FIREBASE) {
          await localStorage.markCheckinAsSynced(checkin.id);
          print('✅ Checkin synced (Firebase)');
        } else if (sent == TransportType.MESHGRAM) {
          print('📡 Checkin sent via MeshGram');
        } else {
          print('⚠️ Checkin saved offline, will sync later');
        }
      } catch (e) {
        print('⚠️ Checkin saved offline, will sync later: $e');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Відправлено: ${checkin.statusText}'),
            backgroundColor: AppTheme.successGreen,
            duration: const Duration(seconds: 2),
          ),
        );
        setState(() {
          _lastCheckin = checkin;
          _selectedStatus = null;
        });
        _loadTransportStatus();
      }
    } catch (e) {
      print('❌ Send checkin error: $e');
      if (mounted) {
        Navigator.of(context).push(
          ScreenTransitions.slideFromRight(
            ErrorScreen(
              type: ErrorType.serverError,
              onRetry: _sendCheckin,
              onBack: () => Navigator.of(context).pop(),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundGray,
      appBar: AppBar(
        backgroundColor: AppTheme.cardWhite,
        elevation: 0,
        title: Text(
          'Я ОК',
          style: AppTheme.h1,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              Navigator.of(context).push(
                ScreenTransitions.slideFromRight(
                  const NotificationsScreen(notifications: []),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.people_outline),
            onPressed: () {
              // Навігація до Family Screen (потрібно створити)
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Family Screen - в розробці')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              Navigator.of(context).push(
                ScreenTransitions.slideFromRight(
                  const SettingsScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Індикатор Firebase (якщо не налаштовано)
                  _buildFirebaseWarning(),
                  const SizedBox(height: 8),
                  // Індикатор транспорту (MeshGram)
                  _buildTransportIndicator(),
                  const SizedBox(height: 16),
                  // Status Cards
                  StatusCard(
                    status: 'ok',
                    isSelected: _selectedStatus == 'ok',
                    onTap: () => setState(() => _selectedStatus = 'ok'),
                  ),
                  const SizedBox(height: 12),
                  StatusCard(
                    status: 'busy',
                    isSelected: _selectedStatus == 'busy',
                    onTap: () => setState(() => _selectedStatus = 'busy'),
                  ),
                  const SizedBox(height: 12),
                  StatusCard(
                    status: 'later',
                    isSelected: _selectedStatus == 'later',
                    onTap: () => setState(() => _selectedStatus = 'later'),
                  ),
                  const SizedBox(height: 12),
                  StatusCard(
                    status: 'hug',
                    isSelected: _selectedStatus == 'hug',
                    onTap: () => setState(() => _selectedStatus = 'hug'),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Big Button
                  BigButton(
                    text: 'Відправити',
                    onPressed: _sendCheckin,
                    gradient: AppTheme.successGradient,
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Last Checkin Indicator
                  if (_lastCheckin != null)
                    Center(
                      child: Text(
                        '🕐 Останній раз: ${_formatTime(_lastCheckin!.timestamp)}',
                        style: AppTheme.caption.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildFirebaseWarning() {
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);
    if (firestoreService.isAvailable) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange, width: 1),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Colors.orange, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Офлайн режим: Firebase не налаштовано. Дані зберігаються локально.',
              style: AppTheme.caption.copyWith(color: Colors.orange.shade700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransportIndicator() {
    final t = _transport;
    if (t == null) return const SizedBox.shrink();
    String line1 = '';
    String line2 = '';
    switch (t) {
      case TransportType.FIREBASE:
        line1 = '🌐 Інтернет: Підключено';
        if (_meshNodeCount > 0) line2 = '📡 Mesh: $_meshNodeCount вузлів поблизу';
        break;
      case TransportType.MESHGRAM:
        line1 = '📡 Mesh: $_meshNodeCount вузлів поблизу';
        break;
      case TransportType.LOCAL_QUEUE:
      case TransportType.HYBRID:
        line1 = 'Офлайн';
        break;
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(line1, style: AppTheme.caption.copyWith(color: AppTheme.textSecondary)),
        if (line2.isNotEmpty) Text(line2, style: AppTheme.caption.copyWith(color: AppTheme.textSecondary)),
      ],
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return 'Щойно';
        }
        return '${difference.inMinutes} хв тому';
      }
      return 'Сьогодні, ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Вчора, ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} дн тому';
    } else {
      return '${time.day}.${time.month}.${time.year}';
    }
  }
}
