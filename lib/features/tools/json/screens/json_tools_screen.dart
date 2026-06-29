import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/json_tools_service.dart';

/// Comprehensive JSON tools screen.
///
/// Provides:
/// - Formatter
/// - Validator
/// - Compare
/// - Tree viewer
/// - Search
/// - Statistics
class JsonToolsScreen extends StatefulWidget {
  const JsonToolsScreen({super.key});

  @override
  State<JsonToolsScreen> createState() => _JsonToolsScreenState();
}

class _JsonToolsScreenState extends State<JsonToolsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _inputController = TextEditingController();
  final _input2Controller = TextEditingController();
  final _searchController = TextEditingController();
  String _output = '';
  JsonValidationResult? _validationResult;
  JsonComparison? _comparisonResult;
  List<JsonSearchResult>? _searchResults;
  JsonStatistics? _statistics;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _inputController.text = '{"name":"John","age":30,"city":"New York"}';
  }

  @override
  void dispose() {
    _tabController.dispose();
    _inputController.dispose();
    _input2Controller.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('أدوات JSON'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'تنسيق'),
            Tab(text: 'تحقق'),
            Tab(text: 'مقارنة'),
            Tab(text: 'شجرة'),
            Tab(text: 'بحث'),
            Tab(text: 'إحصائيات'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildFormatterTab(),
          _buildValidatorTab(),
          _buildCompareTab(),
          _buildTreeTab(),
          _buildSearchTab(),
          _buildStatisticsTab(),
        ],
      ),
    );
  }

  Widget _buildFormatterTab() {
    return Column(
      children: [
        Expanded(
          child: TextField(
            controller: _inputController,
            maxLines: null,
            expands: true,
            decoration: const InputDecoration(
              hintText: 'أدخل JSON هنا...',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.all(12),
            ),
            style: const TextStyle(fontFamily: 'JetBrains Mono', fontSize: 13),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              FilledButton.icon(
                onPressed: _format,
                icon: const Icon(Icons.format_align_left),
                label: const Text('تنسيق'),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: _minify,
                icon: const Icon(Icons.compress),
                label: const Text('تصغير'),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: _copyOutput,
                icon: const Icon(Icons.copy),
                label: const Text('نسخ'),
              ),
            ],
          ),
        ),
        Expanded(
          child: Container(
            margin: const EdgeInsets.all(8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(8),
            ),
            child: SingleChildScrollView(
              child: SelectableText(
                _output.isEmpty ? 'النتيجة ستظهر هنا' : _output,
                style: const TextStyle(fontFamily: 'JetBrains Mono', fontSize: 13),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildValidatorTab() {
    return Column(
      children: [
        Expanded(
          child: TextField(
            controller: _inputController,
            maxLines: null,
            expands: true,
            decoration: const InputDecoration(
              hintText: 'أدخل JSON للتحقق...',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.all(12),
            ),
            style: const TextStyle(fontFamily: 'JetBrains Mono', fontSize: 13),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8),
          child: FilledButton.icon(
            onPressed: _validate,
            icon: const Icon(Icons.check_circle),
            label: const Text('تحقق'),
          ),
        ),
        if (_validationResult != null)
          Container(
            margin: const EdgeInsets.all(8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _validationResult!.isValid
                  ? Colors.green.withOpacity(0.1)
                  : Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  _validationResult!.isValid ? Icons.check : Icons.error,
                  color: _validationResult!.isValid ? Colors.green : Colors.red,
                  size: 32,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    _validationResult!.isValid
                        ? 'JSON صالح ✓'
                        : 'JSON غير صالح: ${_validationResult!.error}',
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildCompareTab() {
    return Column(
      children: [
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _inputController,
                  maxLines: null,
                  expands: true,
                  decoration: const InputDecoration(
                    hintText: 'JSON الأول',
                    border: OutlineInputBorder(),
                  ),
                  style: const TextStyle(fontFamily: 'JetBrains Mono', fontSize: 12),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _input2Controller,
                  maxLines: null,
                  expands: true,
                  decoration: const InputDecoration(
                    hintText: 'JSON الثاني',
                    border: OutlineInputBorder(),
                  ),
                  style: const TextStyle(fontFamily: 'JetBrains Mono', fontSize: 12),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8),
          child: FilledButton.icon(
            onPressed: _compare,
            icon: const Icon(Icons.compare_arrows),
            label: const Text('مقارنة'),
          ),
        ),
        if (_comparisonResult != null)
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _comparisonResult!.areEqual
                    ? Colors.green.withOpacity(0.1)
                    : Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: _comparisonResult!.error != null
                  ? Text('خطأ: ${_comparisonResult!.error}')
                  : _comparisonResult!.areEqual
                      ? const Center(child: Text('الملفان متطابقان ✓'))
                      : ListView.builder(
                          itemCount: _comparisonResult!.differences.length,
                          itemBuilder: (context, index) {
                            final diff = _comparisonResult!.differences[index];
                            return ListTile(
                              leading: Icon(
                                diff.type == JsonDifferenceType.added
                                    ? Icons.add
                                    : diff.type == JsonDifferenceType.removed
                                        ? Icons.remove
                                        : Icons.edit,
                                color: diff.type == JsonDifferenceType.added
                                    ? Colors.green
                                    : diff.type == JsonDifferenceType.removed
                                        ? Colors.red
                                        : Colors.orange,
                              ),
                              title: Text(diff.path),
                              subtitle: Text(
                                '${diff.value1 ?? 'null'} → ${diff.value2 ?? 'null'}',
                              ),
                            );
                          },
                        ),
            ),
          ),
      ],
    );
  }

  Widget _buildTreeTab() {
    return Column(
      children: [
        Expanded(
          child: TextField(
            controller: _inputController,
            maxLines: 5,
            decoration: const InputDecoration(
              hintText: 'أدخل JSON...',
              border: OutlineInputBorder(),
            ),
            style: const TextStyle(fontFamily: 'JetBrains Mono', fontSize: 13),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8),
          child: FilledButton.icon(
            onPressed: () {
              setState(() {});
            },
            icon: const Icon(Icons.account_tree),
            label: const Text('عرض الشجرة'),
          ),
        ),
        Expanded(
          flex: 2,
          child: _inputController.text.isNotEmpty
              ? _buildTreeView()
              : const Center(child: Text('أدخل JSON أولاً')),
        ),
      ],
    );
  }

  Widget _buildTreeView() {
    final result = JsonToolsService.instance.validate(_inputController.text);
    if (!result.isValid) {
      return const Center(child: Text('JSON غير صالح'));
    }
    final root = JsonToolsService.instance.buildTree(_inputController.text);
    return SingleChildScrollView(
      child: _buildTreeNode(root),
    );
  }

  Widget _buildTreeNode(JsonTreeNode node) {
    return ExpansionTile(
      key: ValueKey(node.key),
      title: Text(
        '${node.key}: ${node.value ?? ''}',
        style: TextStyle(
          color: _getValueColor(node.type),
          fontWeight: FontWeight.w500,
        ),
      ),
      children: node.children.map((child) => _buildTreeNode(child)).toList(),
    );
  }

  Color _getValueColor(JsonValueType type) {
    switch (type) {
      case JsonValueType.string:
        return Colors.green;
      case JsonValueType.number:
        return Colors.blue;
      case JsonValueType.boolean:
        return Colors.purple;
      case JsonValueType.nullValue:
        return Colors.grey;
      default:
        return Colors.black;
    }
  }

  Widget _buildSearchTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    hintText: 'ابحث في JSON...',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: _search,
                child: const Text('بحث'),
              ),
            ],
          ),
        ),
        Expanded(
          child: TextField(
            controller: _inputController,
            maxLines: null,
            expands: true,
            decoration: const InputDecoration(
              hintText: 'أدخل JSON...',
              border: OutlineInputBorder(),
            ),
            style: const TextStyle(fontFamily: 'JetBrains Mono', fontSize: 13),
          ),
        ),
        if (_searchResults != null)
          Container(
            height: 200,
            margin: const EdgeInsets.all(8),
            child: _searchResults!.isEmpty
                ? const Center(child: Text('لا توجد نتائج'))
                : ListView.builder(
                    itemCount: _searchResults!.length,
                    itemBuilder: (context, index) {
                      final result = _searchResults![index];
                      return ListTile(
                        leading: const Icon(Icons.find_in_page),
                        title: Text(result.path),
                        subtitle: Text(result.value),
                      );
                    },
                  ),
          ),
      ],
    );
  }

  Widget _buildStatisticsTab() {
    return Column(
      children: [
        Expanded(
          child: TextField(
            controller: _inputController,
            maxLines: null,
            expands: true,
            decoration: const InputDecoration(
              hintText: 'أدخل JSON...',
              border: OutlineInputBorder(),
            ),
            style: const TextStyle(fontFamily: 'JetBrains Mono', fontSize: 13),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8),
          child: FilledButton.icon(
            onPressed: _calculateStats,
            icon: const Icon(Icons.bar_chart),
            label: const Text('احسب الإحصائيات'),
          ),
        ),
        if (_statistics != null)
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(8),
              children: [
                _StatTile(label: 'إجمالي المفاتيح', value: '${_statistics!.totalKeys}'),
                _StatTile(label: 'إجمالي القيم', value: '${_statistics!.totalValues}'),
                _StatTile(label: 'الكائنات', value: '${_statistics!.objects}'),
                _StatTile(label: 'الصفائف', value: '${_statistics!.arrays}'),
                _StatTile(label: 'النصوص', value: '${_statistics!.strings}'),
                _StatTile(label: 'الأرقام', value: '${_statistics!.numbers}'),
                _StatTile(label: 'المنطقية', value: '${_statistics!.booleans}'),
                _StatTile(label: 'Null', value: '${_statistics!.nulls}'),
                _StatTile(label: 'أقصى عمق', value: '${_statistics!.maxDepth}'),
                _StatTile(label: 'الحجم', value: '${_statistics!.size} حرف'),
              ],
            ),
          ),
      ],
    );
  }

  void _format() {
    setState(() {
      _output = JsonToolsService.instance.format(_inputController.text);
    });
  }

  void _minify() {
    setState(() {
      _output = JsonToolsService.instance.minify(_inputController.text);
    });
  }

  void _validate() {
    setState(() {
      _validationResult = JsonToolsService.instance.validate(_inputController.text);
    });
  }

  void _compare() {
    setState(() {
      _comparisonResult = JsonToolsService.instance.compare(
        _inputController.text,
        _input2Controller.text,
      );
    });
  }

  void _search() {
    setState(() {
      _searchResults = JsonToolsService.instance.search(
        _inputController.text,
        _searchController.text,
      );
    });
  }

  void _calculateStats() {
    setState(() {
      _statistics = JsonToolsService.instance.getStatistics(_inputController.text);
    });
  }

  Future<void> _copyOutput() async {
    if (_output.isNotEmpty) {
      await Clipboard.setData(ClipboardData(text: _output));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم النسخ')),
        );
      }
    }
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(label),
        trailing: Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
    );
  }
}
