import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_utils.dart';
import '../models/favorite_item.dart';
import '../repositories/favorites_repository.dart';

class FavoritesScreen extends ConsumerStatefulWidget {
  const FavoritesScreen({super.key});

  @override
  ConsumerState<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends ConsumerState<FavoritesScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final favorites = ref.watch(favoritesRepositoryProvider).getAll();

    var filtered = favorites;
    if (_searchQuery.isNotEmpty) {
      filtered = favorites
          .where((f) =>
              f.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              f.url.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('المفضلة'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'ابحث في المفضلة...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => setState(() => _searchQuery = ''),
                      )
                    : null,
                border: const OutlineInputBorder(),
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),
          Expanded(
            child: filtered.isEmpty
                ? _buildEmptyState(context)
                : ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final favorite = filtered[index];
                      return _FavoriteItemTile(favorite: favorite);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.star_border, size: 64, color: Theme.of(context).colorScheme.outline),
          const SizedBox(height: 16),
          const Text('لا توجد مفضلة'),
          const SizedBox(height: 8),
          const Text('أضف الطلبات المفضلة للوصول السريع'),
        ],
      ),
    );
  }
}

class _FavoriteItemTile extends ConsumerWidget {
  const _FavoriteItemTile({required this.favorite});

  final FavoriteItem favorite;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final methodColor = AppTheme.getMethodColor(favorite.method);

    return Dismissible(
      key: Key(favorite.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 16),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) async {
        await ref.read(favoritesRepositoryProvider).remove(favorite.id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم الحذف من المفضلة')),
          );
        }
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: ListTile(
          leading: Container(
            width: 60,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: methodColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              favorite.method,
              style: TextStyle(
                color: methodColor,
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          title: Text(
            favorite.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            favorite.url,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(
                  favorite.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                  color: favorite.isPinned ? Colors.amber : null,
                ),
                onPressed: () {
                  ref.read(favoritesRepositoryProvider).togglePin(favorite.id);
                },
              ),
              const Icon(Icons.chevron_left),
            ],
          ),
          onTap: () {
            GoRouter.of(context).push('/request/${favorite.requestId}');
          },
        ),
      ),
    );
  }
}
