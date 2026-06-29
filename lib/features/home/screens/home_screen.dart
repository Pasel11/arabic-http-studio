import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../providers/home_providers.dart';
import '../../request/models/http_request.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recentRequests = ref.watch(recentRequestsProvider);
    final stats = ref.watch(appStatsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('استوديو HTTP العربي'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _showSearch(context),
            tooltip: 'بحث',
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.push('/settings'),
            tooltip: 'الإعدادات',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Stats card
          _buildStatsCard(context, stats),
          const SizedBox(height: 24),

          // Quick actions
          Text(
            'إجراءات سريعة',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          _buildQuickActions(context),
          const SizedBox(height: 24),

          // Recent requests
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'الطلبات الأخيرة',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              TextButton(
                onPressed: () => context.push('/history'),
                child: const Text('عرض الكل'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (recentRequests.isEmpty)
            _buildEmptyState(context)
          else
            Column(
              children: recentRequests
                  .map((r) => _RequestListItem(request: r))
                  .toList(),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/request'),
        icon: const Icon(Icons.add),
        label: const Text('طلب جديد'),
      ),
    );
  }

  Widget _buildStatsCard(BuildContext context, AppStats stats) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'إحصائيات',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _StatItem(
                    icon: Icons.http,
                    label: 'الطلبات',
                    value: stats.totalRequests.toString(),
                    color: AppTheme.postColor,
                  ),
                ),
                Expanded(
                  child: _StatItem(
                    icon: Icons.history,
                    label: 'المحفوظات',
                    value: stats.totalHistory.toString(),
                    color: AppTheme.getColor,
                  ),
                ),
                Expanded(
                  child: _StatItem(
                    icon: Icons.star,
                    label: 'المفضلة',
                    value: stats.totalFavorites.toString(),
                    color: AppTheme.warningColor,
                  ),
                ),
                Expanded(
                  child: _StatItem(
                    icon: Icons.folder,
                    label: 'المجموعات',
                    value: stats.totalCollections.toString(),
                    color: AppTheme.optionsColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    final actions = [
      _QuickAction(
        icon: Icons.http,
        label: 'طلب HTTP',
        color: AppTheme.postColor,
        onTap: () => GoRouter.of(context).push('/request'),
      ),
      _QuickAction(
        icon: Icons.wifi_tethering,
        label: 'WebSocket',
        color: AppTheme.patchColor,
        onTap: () => GoRouter.of(context).push('/websocket'),
      ),
      _QuickAction(
        icon: Icons.collections_bookmark,
        label: 'المجموعات',
        color: AppTheme.optionsColor,
        onTap: () => GoRouter.of(context).push('/collections-full'),
      ),
      _QuickAction(
        icon: Icons.code,
        label: 'المتغيرات',
        color: AppTheme.getColor,
        onTap: () => GoRouter.of(context).push('/variables'),
      ),
      _QuickAction(
        icon: Icons.eco,
        label: 'البيئة',
        color: AppTheme.successColor,
        onTap: () => GoRouter.of(context).push('/environment'),
      ),
      _QuickAction(
        icon: Icons.vpn_key,
        label: 'المصادقة',
        color: AppTheme.warningColor,
        onTap: () => GoRouter.of(context).push('/authentication'),
      ),
      _QuickAction(
        icon: Icons.history,
        label: 'المحفوظات',
        color: AppTheme.headColor,
        onTap: () => GoRouter.of(context).push('/history-full'),
      ),
      _QuickAction(
        icon: Icons.star,
        label: 'المفضلة',
        color: AppTheme.deleteColor,
        onTap: () => GoRouter.of(context).push('/favorites-full'),
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 0.85,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
      ),
      itemCount: actions.length,
      itemBuilder: (context, index) => actions[index],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(
              Icons.inbox,
              size: 64,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'لا توجد طلبات بعد',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'أنشئ أول طلب للبدء',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSearch(BuildContext context) {
    showSearch(
      context: context,
      delegate: _HomeSearchDelegate(),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
        ),
      ],
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _RequestListItem extends StatelessWidget {
  const _RequestListItem({required this.request});

  final HttpRequestModel request;

  @override
  Widget build(BuildContext context) {
    final methodColor = AppTheme.getMethodColor(request.method);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: methodColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            request.method,
            style: TextStyle(
              color: methodColor,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
        title: Text(
          request.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          request.url,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        trailing: const Icon(Icons.chevron_left),
        onTap: () {
          GoRouter.of(context).push('/request/${request.id}');
        },
      ),
    );
  }
}

class _HomeSearchDelegate extends SearchDelegate {
  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () => query = '',
      ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchResults(context);
  }

  Widget _buildSearchResults(BuildContext context) {
    if (query.isEmpty) {
      return const Center(child: Text('ابحث عن الطلبات'));
    }

    return Consumer(
      builder: (context, ref, _) {
        final results = ref.watch(searchRequestsProvider(query));
        if (results.isEmpty) {
          return const Center(child: Text('لا توجد نتائج'));
        }
        return ListView.builder(
          itemCount: results.length,
          itemBuilder: (context, index) {
            final request = results[index];
            final methodColor = AppTheme.getMethodColor(request.method);
            return ListTile(
              leading: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: methodColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  request.method,
                  style: TextStyle(
                    color: methodColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              title: Text(request.name),
              subtitle: Text(request.url),
              onTap: () {
                close(context, null);
                GoRouter.of(context).push('/request/${request.id}');
              },
            );
          },
        );
      },
    );
  }
}
