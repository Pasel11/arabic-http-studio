import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../settings/providers/settings_providers.dart';

/// Settings screen with all application preferences.
///
/// This screen provides access to all application settings organized
/// into sections: appearance, network, security, code editor,
/// general, developer, and about.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('الإعدادات')),
      body: ListView(
        children: [
          // Appearance
          _SectionHeader(title: 'المظهر'),
          ListTile(
            leading: const Icon(Icons.palette),
            title: const Text('وضع السمة'),
            subtitle: Text(_themeModeText(settings.themeMode)),
            trailing: DropdownButton<ThemeMode>(
              value: settings.themeMode,
              onChanged: (mode) {
                if (mode != null) {
                  ref.read(settingsProvider.notifier).setThemeMode(mode);
                }
              },
              items: const [
                DropdownMenuItem(value: ThemeMode.system, child: Text('النظام')),
                DropdownMenuItem(value: ThemeMode.light, child: Text('نهاري')),
                DropdownMenuItem(value: ThemeMode.dark, child: Text('ليلي')),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.color_lens),
            title: const Text('اللون الأساسي'),
            subtitle: Text(settings.primaryColor != null ? 'مخصص' : 'افتراضي'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (settings.primaryColor != null)
                  CircleAvatar(
                    backgroundColor: settings.primaryColor,
                    radius: 12,
                  ),
                IconButton(
                  icon: const Icon(Icons.color_picker),
                  onPressed: () => _pickColor(context, ref),
                ),
              ],
            ),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.dynamic_form),
            title: const Text('الألوان الديناميكية (Material You)'),
            subtitle: const Text('استخدام ألوان خلفية النظام'),
            value: settings.useDynamicColor,
            onChanged: (value) {
              ref.read(settingsProvider.notifier).setUseDynamicColor(value);
            },
          ),
          ListTile(
            leading: const Icon(Icons.language),
            title: const Text('اللغة'),
            subtitle: Text(settings.locale.languageCode == 'ar' ? 'العربية' : 'English'),
            trailing: DropdownButton<Locale>(
              value: settings.locale,
              onChanged: (locale) {
                if (locale != null) {
                  ref.read(settingsProvider.notifier).setLocale(locale);
                }
              },
              items: const [
                DropdownMenuItem(value: Locale('ar'), child: Text('العربية')),
                DropdownMenuItem(value: Locale('en'), child: Text('English')),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.text_fields),
            title: const Text('حجم الخط'),
            subtitle: Slider(
              value: settings.fontSize,
              min: 10,
              max: 24,
              divisions: 14,
              label: settings.fontSize.toStringAsFixed(0),
              onChanged: (value) {
                ref.read(settingsProvider.notifier).setFontSize(value);
              },
            ),
          ),

          // Network
          _SectionHeader(title: 'الشبكة'),
          ListTile(
            leading: const Icon(Icons.timer),
            title: const Text('المهلة الافتراضية (ms)'),
            subtitle: Text(settings.defaultTimeout.toString()),
            trailing: IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _editNumber(
                context,
                ref,
                'المهلة الافتراضية',
                settings.defaultTimeout,
                (value) => ref.read(settingsProvider.notifier).setDefaultTimeout(value),
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.refresh),
            title: const Text('عدد المحاولات'),
            subtitle: Text(settings.retryCount.toString()),
            trailing: Slider(
              value: settings.retryCount.toDouble(),
              min: 0,
              max: 10,
              divisions: 10,
              label: settings.retryCount.toString(),
              onChanged: (value) {
                ref.read(settingsProvider.notifier).setRetryCount(value.round());
              },
            ),
          ),
          ListTile(
            leading: const Icon(Icons.schedule),
            title: const Text('تأخير المحاولات (ms)'),
            subtitle: Text(settings.retryDelay.toString()),
            trailing: Slider(
              value: settings.retryDelay.toDouble(),
              min: 0,
              max: 5000,
              divisions: 50,
              label: settings.retryDelay.toString(),
              onChanged: (value) {
                ref.read(settingsProvider.notifier).setRetryDelay(value.round());
              },
            ),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.follow_the_signs),
            title: const Text('متابعة التحويلات'),
            value: settings.followRedirects,
            onChanged: (value) {
              ref.read(settingsProvider.notifier).setFollowRedirects(value);
            },
          ),
          ListTile(
            leading: const Icon(Icons.http),
            title: const Text('إصدار HTTP'),
            subtitle: Text(settings.httpVersion),
            trailing: DropdownButton<String>(
              value: settings.httpVersion,
              onChanged: (version) {
                if (version != null) {
                  ref.read(settingsProvider.notifier).setHttpVersion(version);
                }
              },
              items: const [
                DropdownMenuItem(value: 'HTTP/1.1', child: Text('HTTP/1.1')),
                DropdownMenuItem(value: 'HTTP/2', child: Text('HTTP/2')),
                DropdownMenuItem(value: 'HTTP/3', child: Text('HTTP/3')),
              ],
            ),
          ),

          // Security
          _SectionHeader(title: 'الأمان'),
          SwitchListTile(
            secondary: const Icon(Icons.https),
            title: const Text('التحقق من شهادات TLS'),
            value: settings.verifyTls,
            onChanged: (value) {
              ref.read(settingsProvider.notifier).setVerifyTls(value);
            },
          ),

          // Proxy
          _SectionHeader(title: 'البروكسي و DNS'),
          ListTile(
            leading: const Icon(Icons.vpn_lock),
            title: const Text('نوع البروكسي'),
            subtitle: Text(settings.proxyType ?? 'بدون'),
            trailing: DropdownButton<String?>(
              value: settings.proxyType,
              onChanged: (type) {
                ref.read(settingsProvider.notifier).setProxySettings(type: type);
              },
              items: const [
                DropdownMenuItem(value: null, child: Text('بدون')),
                DropdownMenuItem(value: 'http', child: Text('HTTP')),
                DropdownMenuItem(value: 'socks5', child: Text('SOCKS5')),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.dns),
            title: const Text('DNS مخصص'),
            subtitle: Text(settings.customDns ?? 'افتراضي'),
            trailing: IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _editDns(context, ref, settings.customDns),
            ),
          ),

          // Code Editor
          _SectionHeader(title: 'محرر الكود'),
          SwitchListTile(
            secondary: const Icon(Icons.format_align_left),
            title: const Text('إبراز الصيغة'),
            value: settings.syntaxHighlight,
            onChanged: (value) {
              ref.read(settingsProvider.notifier).setSyntaxHighlight(value);
            },
          ),
          SwitchListTile(
            secondary: const Icon(Icons.format_list_numbered),
            title: const Text('إظهار أرقام الأسطر'),
            value: settings.showLineNumbers,
            onChanged: (value) {
              ref.read(settingsProvider.notifier).setShowLineNumbers(value);
            },
          ),
          SwitchListTile(
            secondary: const Icon(Icons.wrap_text),
            title: const Text('التفاف الكلمات'),
            value: settings.wordWrap,
            onChanged: (value) {
              ref.read(settingsProvider.notifier).setWordWrap(value);
            },
          ),

          // Backup
          _SectionHeader(title: 'النسخ الاحتياطي'),
          SwitchListTile(
            secondary: const Icon(Icons.backup),
            title: const Text('النسخ الاحتياطي التلقائي'),
            value: settings.autoBackup,
            onChanged: (value) {
              ref.read(settingsProvider.notifier).setAutoBackup(value);
            },
          ),
          ListTile(
            leading: const Icon(Icons.schedule),
            title: const Text('فاصل النسخ الاحتياطي (ساعات)'),
            subtitle: Text(settings.autoBackupIntervalHours.toString()),
            trailing: Slider(
              value: settings.autoBackupIntervalHours.toDouble(),
              min: 1,
              max: 168,
              divisions: 167,
              label: settings.autoBackupIntervalHours.toString(),
              onChanged: (value) {
                ref.read(settingsProvider.notifier).setAutoBackupInterval(value.round());
              },
            ),
          ),
          ListTile(
            leading: const Icon(Icons.restore),
            title: const Text('النسخ الاحتياطي والاستعادة'),
            subtitle: const Text('إدارة النسخ الاحتياطية'),
            trailing: const Icon(Icons.chevron_left),
            onTap: () => context.push('/backup'),
          ),

          // General
          _SectionHeader(title: 'عام'),
          SwitchListTile(
            secondary: const Icon(Icons.save),
            title: const Text('الحفظ التلقائي'),
            value: settings.autoSave,
            onChanged: (value) {
              ref.read(settingsProvider.notifier).setAutoSave(value);
            },
          ),
          SwitchListTile(
            secondary: const Icon(Icons.notifications),
            title: const Text('الإشعارات'),
            value: settings.enableNotifications,
            onChanged: (value) {
              ref.read(settingsProvider.notifier).setEnableNotifications(value);
            },
          ),
          SwitchListTile(
            secondary: const Icon(Icons.vibration),
            title: const Text('الاهتزاز'),
            value: settings.hapticFeedback,
            onChanged: (value) {
              ref.read(settingsProvider.notifier).setHapticFeedback(value);
            },
          ),
          SwitchListTile(
            secondary: const Icon(Icons.screen_lock_portrait),
            title: const Text('إبقاء الشاشة قيد التشغيل'),
            value: settings.keepScreenOn,
            onChanged: (value) {
              ref.read(settingsProvider.notifier).setKeepScreenOn(value);
            },
          ),
          SwitchListTile(
            secondary: const Icon(Icons.exit_to_app),
            title: const Text('التأكيد عند الخروج'),
            value: settings.confirmOnExit,
            onChanged: (value) {
              ref.read(settingsProvider.notifier).setConfirmOnExit(value);
            },
          ),

          // Developer
          _SectionHeader(title: 'المطور'),
          SwitchListTile(
            secondary: const Icon(Icons.code),
            title: const Text('وضع المطور'),
            value: settings.developerMode,
            onChanged: (value) {
              ref.read(settingsProvider.notifier).setDeveloperMode(value);
            },
          ),
          if (settings.developerMode) ...[
            SwitchListTile(
              secondary: const Icon(Icons.bug_report),
              title: const Text('سجل مطوّل'),
              value: settings.verboseLogging,
              onChanged: (value) {
                ref.read(settingsProvider.notifier).setVerboseLogging(value);
              },
            ),
            ListTile(
              leading: const Icon(Icons.developer_mode),
              title: const Text('أدوات المطور'),
              subtitle: const Text('السجلات، الشبكة، الأداء، الذاكرة'),
              trailing: const Icon(Icons.chevron_left),
              onTap: () => context.push('/developer-tools'),
            ),
          ],

          // About
          _SectionHeader(title: 'حول التطبيق'),
          const ListTile(
            leading: Icon(Icons.info),
            title: Text('الإصدار'),
            subtitle: Text('1.0.0'),
          ),
          const ListTile(
            leading: Icon(Icons.code),
            title: Text('الترخيص'),
            subtitle: Text('MIT License'),
          ),

          // Reset
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.all(16),
            child: OutlinedButton.icon(
              onPressed: () => _confirmReset(context, ref),
              icon: const Icon(Icons.restore, color: Colors.red),
              label: const Text('إعادة تعيين الإعدادات',
                  style: TextStyle(color: Colors.red)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.red),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _themeModeText(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return 'النظام';
      case ThemeMode.light:
        return 'نهاري';
      case ThemeMode.dark:
        return 'ليلي';
    }
  }

  void _pickColor(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('اختر اللون'),
        content: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            Colors.blue,
            Colors.green,
            Colors.red,
            Colors.orange,
            Colors.purple,
            Colors.teal,
            Colors.indigo,
            Colors.pink,
          ].map((color) {
            return InkWell(
              onTap: () {
                ref.read(settingsProvider.notifier).setPrimaryColor(color);
                Navigator.pop(context);
              },
              child: CircleAvatar(backgroundColor: color, radius: 24),
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
        ],
      ),
    );
  }

  void _editNumber(
    BuildContext context,
    WidgetRef ref,
    String title,
    int current,
    ValueChanged<int> onSave,
  ) {
    final controller = TextEditingController(text: current.toString());
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          FilledButton(
            onPressed: () {
              final value = int.tryParse(controller.text);
              if (value != null) {
                onSave(value);
                Navigator.pop(context);
              }
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  void _editDns(BuildContext context, WidgetRef ref, String? current) {
    final controller = TextEditingController(text: current ?? '');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('DNS مخصص'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: '8.8.8.8'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          FilledButton(
            onPressed: () {
              final value = controller.text.isEmpty ? null : controller.text;
              ref.read(settingsProvider.notifier).setCustomDns(value);
              Navigator.pop(context);
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  void _confirmReset(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إعادة تعيين الإعدادات'),
        content: const Text('سيتم إعادة جميع الإعدادات إلى الوضع الافتراضي. هل أنت متأكد؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await ref.read(settingsProvider.notifier).resetSettings();
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('إعادة تعيين'),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}
