import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
// import 'meshgram_poc_screen.dart';  // Тимчасово вимкнено

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  // URL документації
  // ЗАМІНІТЬ на ваш GitHub Pages URL після публікації
  // Приклад: https://yourusername.github.io/yaok-legal/privacy.html
  static const String privacyUrl = 'https://yourusername.github.io/yaok-legal/privacy.html';
  static const String termsUrl = 'https://yourusername.github.io/yaok-legal/terms.html';
  static const String supportUrl = 'https://yourusername.github.io/yaok-legal/support.html';

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      debugPrint('Не вдалося відкрити URL: $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Налаштування'),
        backgroundColor: const Color(0xFF0057B7),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Налаштування додатку
          _buildSection(
            title: 'Налаштування',
            children: [
              _buildSettingTile(
                icon: Icons.notifications_outlined,
                title: 'Нагадувати мені',
                subtitle: 'Кожен день о 09:00',
                onTap: () {
                  // TODO: Відкрити діалог вибору часу
                },
              ),
              _buildSettingTile(
                icon: Icons.warning_outlined,
                title: 'Попередити близьких через',
                subtitle: '3 дні без зв\'язку',
                onTap: () {
                  // TODO: Відкрити діалог вибору періоду
                },
              ),
              _buildSwitchTile(
                icon: Icons.volume_off_outlined,
                title: 'Тихий режим',
                subtitle: 'Без звукових сповіщень вночі',
                value: true,
                onChanged: (value) {
                  // TODO: Зберегти налаштування
                },
              ),
              _buildSwitchTile(
                icon: Icons.cloud_off_outlined,
                title: 'Оффлайн режим',
                subtitle: 'Відправка при появі мережі',
                value: true,
                onChanged: (value) {
                  // TODO: Зберегти налаштування
                },
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Правові документи
          _buildSection(
            title: 'Правові документи',
            children: [
              _buildSettingTile(
                icon: Icons.privacy_tip_outlined,
                title: 'Політика конфіденційності',
                subtitle: 'Як ми збираємо та захищаємо ваші дані',
                onTap: () => _openUrl(privacyUrl),
              ),
              _buildSettingTile(
                icon: Icons.description_outlined,
                title: 'Умови використання',
                subtitle: 'Правила користування додатком',
                onTap: () => _openUrl(termsUrl),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Розробка / Тестування (тимчасово вимкнено)
          // _buildSection(
          //   title: 'Розробка',
          //   children: [
          //     _buildSettingTile(
          //       icon: Icons.wifi_tethering,
          //       title: 'MeshGram PoC',
          //       subtitle: 'Тестування Wi-Fi Direct (для розробників)',
          //       onTap: () {
          //         Navigator.of(context).push(
          //           MaterialPageRoute(
          //             builder: (context) => const MeshGramPoCScreen(),
          //           ),
          //         );
          //       },
          //     ),
          //   ],
          // ),
          // const SizedBox(height: 24),

          // Підтримка
          _buildSection(
            title: 'Підтримка',
            children: [
              _buildSettingTile(
                icon: Icons.help_outline,
                title: 'Допомога та підтримка',
                subtitle: 'FAQ та контакти',
                onTap: () => _openUrl(supportUrl),
              ),
              _buildSettingTile(
                icon: Icons.email_outlined,
                title: 'Написати нам',
                subtitle: 'support@poruch.app',
                onTap: () => _openUrl('mailto:support@poruch.app'),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Підтримати проєкт
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0057B7), Color(0xFFFFD700)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const Text(
                  'Підтримати проєкт',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Я ОК — безкоштовний для військових та їхніх родин',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    // TODO: Відкрити сторінку донату на ЗСУ
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF0057B7),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Задонатити на ЗСУ ❤️',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Інформація про додаток
          Center(
            child: Column(
              children: [
                const Text(
                  'Версія 1.0.0',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  '© 2026 Poruch',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Зроблено в Україні 🇺🇦',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 8),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF0057B7)),
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle) : null,
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF0057B7)),
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle) : null,
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: const Color(0xFF34C759),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}
