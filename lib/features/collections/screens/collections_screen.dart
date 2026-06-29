import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/collection_item.dart';
import '../repositories/collections_repository.dart';

class CollectionsScreen extends ConsumerStatefulWidget {
  const CollectionsScreen({super.key});

  @override
  ConsumerState<CollectionsScreen> createState() => _CollectionsScreenState();
}

class _CollectionsScreenState extends ConsumerState<CollectionsScreen> {
  String? _currentFolderId;
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final collections = ref.watch(collectionsRepositoryProvider);
    final items = _currentFolderId == null
        ? collections.getRoot()
        : collections.getByParent(_currentFolderId);

    var filtered = items;
    if (_searchQuery.isNotEmpty) {
      filtered = collections.search(_searchQuery);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_getTitle()),
        leading: _currentFolderId != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  final current = collections.getById(_currentFolderId!);
                  setState(() {
                    _currentFolderId = current?.parentId;
                  });
                },
              )
            : null,
        actions: [
          IconButton(
            icon: const Icon(Icons.create_new_folder),
            tooltip: 'مجلد جديد',
            onPressed: () => _createCollection(context, isFolder: true),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'مجموعة جديدة',
            onPressed: () => _createCollection(context, isFolder: false),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'ابحث في المجموعات...',
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
                      final item = filtered[index];
                      return _CollectionItemTile(
                        item: item,
                        onTap: () {
                          if (item.isFolder) {
                            setState(() => _currentFolderId = item.id);
                          } else {
                            // Open collection requests
                            _showCollectionRequests(context, item);
                          }
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  String _getTitle() {
    if (_currentFolderId == null) return 'المجموعات';
    final collections = ref.read(collectionsRepositoryProvider);
    final folder = collections.getById(_currentFolderId!);
    return folder?.name ?? 'المجموعات';
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.folder_open, size: 64, color: Theme.of(context).colorScheme.outline),
          const SizedBox(height: 16),
          const Text('لا توجد مجموعات'),
          const SizedBox(height: 8),
          const Text('أنشئ مجموعة لتنظيم طلباتك'),
        ],
      ),
    );
  }

  void _createCollection(BuildContext context, {required bool isFolder}) {
    final nameController = TextEditingController();
    final descController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isFolder ? 'مجلد جديد' : 'مجموعة جديدة'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'الاسم'),
              autofocus: true,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: descController,
              decoration: const InputDecoration(labelText: 'الوصف'),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          FilledButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty) {
                final collection = CollectionItem(
                  id: DateTime.now().microsecondsSinceEpoch.toString(),
                  name: nameController.text,
                  description: descController.text,
                  parentId: _currentFolderId,
                  isFolder: isFolder,
                );
                await ref.read(collectionsRepositoryProvider).save(collection);
                if (mounted) Navigator.pop(context);
                setState(() {});
              }
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  void _showCollectionRequests(BuildContext context, CollectionItem collection) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) {
          return Column(
            children: [
              AppBar(
                title: Text(collection.name),
                leading: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              Expanded(
                child: collection.requestIds.isEmpty
                    ? const Center(child: Text('لا توجد طلبات في هذه المجموعة'))
                    : ListView.builder(
                        controller: scrollController,
                        itemCount: collection.requestIds.length,
                        itemBuilder: (context, index) {
                          final requestId = collection.requestIds[index];
                          return ListTile(
                            leading: const Icon(Icons.http),
                            title: Text('طلب $requestId'),
                            onTap: () {
                              Navigator.pop(context);
                              GoRouter.of(context).push('/request/$requestId');
                            },
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CollectionItemTile extends ConsumerWidget {
  const _CollectionItemTile({
    required this.item,
    required this.onTap,
  });

  final CollectionItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ListTile(
        leading: Icon(item.isFolder ? Icons.folder : Icons.collections_bookmark),
        title: Text(item.name),
        subtitle: item.description != null ? Text(item.description!) : null,
        trailing: PopupMenuButton<String>(
          onSelected: (action) {
            switch (action) {
              case 'delete':
                ref.read(collectionsRepositoryProvider).delete(item.id);
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'delete', child: Text('حذف')),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}
