import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../authentication/models/auth_config.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('المصادقة'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.vpn_key, color: Theme.of(context).primaryColor),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'إدارة بيانات الاعتماد',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'احفظ بيانات الاعتماد المختلفة (Bearer Tokens, Basic Auth, API Keys) لإعادة استخدامها في الطلبات.',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Auth methods grid
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.2,
            children: [
              _AuthMethodCard(
                icon: Icons.key,
                title: 'Bearer Token',
                color: Colors.blue,
                onTap: () => _showAuthEditor(context, 'bearer'),
              ),
              _AuthMethodCard(
                icon: Icons.person,
                title: 'Basic Auth',
                color: Colors.green,
                onTap: () => _showAuthEditor(context, 'basic'),
              ),
              _AuthMethodCard(
                icon: Icons.security,
                title: 'Digest Auth',
                color: Colors.orange,
                onTap: () => _showAuthEditor(context, 'digest'),
              ),
              _AuthMethodCard(
                icon: Icons.api,
                title: 'API Key',
                color: Colors.purple,
                onTap: () => _showAuthEditor(context, 'apiKey'),
              ),
              _AuthMethodCard(
                icon: Icons.token,
                title: 'JWT',
                color: Colors.red,
                onTap: () => _showAuthEditor(context, 'jwt'),
              ),
              _AuthMethodCard(
                icon: Icons.edit,
                title: 'مخصص',
                color: Colors.teal,
                onTap: () => _showAuthEditor(context, 'custom'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showAuthEditor(BuildContext context, String authType) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('تكوين ${_getAuthTypeName(authType)}'),
        content: const Text('سيتم تحديث هذا في الطلب المحدد'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إغلاق')),
        ],
      ),
    );
  }

  String _getAuthTypeName(String type) {
    switch (type) {
      case 'bearer':
        return 'Bearer Token';
      case 'basic':
        return 'Basic Auth';
      case 'digest':
        return 'Digest Auth';
      case 'apiKey':
        return 'API Key';
      case 'jwt':
        return 'JWT';
      case 'custom':
        return 'مخصص';
      default:
        return type;
    }
  }
}

class _AuthMethodCard extends StatelessWidget {
  const _AuthMethodCard({
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
