import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/encoding_crypto_service.dart';

/// Encoding and Crypto tools screen.
///
/// Provides:
/// - Base64 encode/decode
/// - URL encode/decode
/// - Unicode encode/decode
/// - Hex encode/decode
/// - MD5, SHA1, SHA256, SHA512 hashes
/// - HMAC
class EncodingCryptoToolsScreen extends StatefulWidget {
  const EncodingCryptoToolsScreen({super.key});

  @override
  State<EncodingCryptoToolsScreen> createState() =>
      _EncodingCryptoToolsScreenState();
}

class _EncodingCryptoToolsScreenState extends State<EncodingCryptoToolsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _inputController = TextEditingController();
  final _keyController = TextEditingController();
  String _output = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _inputController.dispose();
    _keyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('أدوات الترميز والتشفير'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Base64'),
            Tab(text: 'URL'),
            Tab(text: 'Unicode'),
            Tab(text: 'Hex'),
            Tab(text: 'Hash'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildBase64Tab(),
          _buildUrlTab(),
          _buildUnicodeTab(),
          _buildHexTab(),
          _buildHashTab(),
        ],
      ),
    );
  }

  Widget _buildBase64Tab() {
    return _buildToolTab(
      title: 'Base64',
      actions: [
        _ActionButton(
          label: 'ترميز',
          icon: Icons.lock,
          onPressed: () => _setOutput(
            EncodingCryptoService.instance.base64Encode(_inputController.text),
          ),
        ),
        _ActionButton(
          label: 'فك الترميز',
          icon: Icons.lock_open,
          onPressed: () => _setOutput(
            EncodingCryptoService.instance.base64Decode(_inputController.text),
          ),
        ),
      ],
    );
  }

  Widget _buildUrlTab() {
    return _buildToolTab(
      title: 'URL Encode/Decode',
      actions: [
        _ActionButton(
          label: 'ترميز',
          icon: Icons.link,
          onPressed: () => _setOutput(
            EncodingCryptoService.instance.urlEncode(_inputController.text),
          ),
        ),
        _ActionButton(
          label: 'فك الترميز',
          icon: Icons.link_off,
          onPressed: () => _setOutput(
            EncodingCryptoService.instance.urlDecode(_inputController.text),
          ),
        ),
      ],
    );
  }

  Widget _buildUnicodeTab() {
    return _buildToolTab(
      title: 'Unicode',
      actions: [
        _ActionButton(
          label: 'ترميز',
          icon: Icons.translate,
          onPressed: () => _setOutput(
            EncodingCryptoService.instance.unicodeEncode(_inputController.text),
          ),
        ),
        _ActionButton(
          label: 'فك الترميز',
          icon: Icons.translate_outlined,
          onPressed: () => _setOutput(
            EncodingCryptoService.instance.unicodeDecode(_inputController.text),
          ),
        ),
      ],
    );
  }

  Widget _buildHexTab() {
    return _buildToolTab(
      title: 'Hex',
      actions: [
        _ActionButton(
          label: 'ترميز',
          icon: Icons.hexadecimal,
          onPressed: () => _setOutput(
            EncodingCryptoService.instance.hexEncode(_inputController.text),
          ),
        ),
        _ActionButton(
          label: 'فك الترميز',
          icon: Icons.hexadecimal_outlined,
          onPressed: () => _setOutput(
            EncodingCryptoService.instance.hexDecode(_inputController.text),
          ),
        ),
      ],
    );
  }

  Widget _buildHashTab() {
    return _buildToolTab(
      title: 'Hash',
      showKey: true,
      actions: [
        _ActionButton(
          label: 'MD5',
          icon: Icons.fingerprint,
          onPressed: () => _setOutput(
            EncodingCryptoService.instance.md5Hash(_inputController.text),
          ),
        ),
        _ActionButton(
          label: 'SHA-1',
          icon: Icons.fingerprint,
          onPressed: () => _setOutput(
            EncodingCryptoService.instance.sha1Hash(_inputController.text),
          ),
        ),
        _ActionButton(
          label: 'SHA-256',
          icon: Icons.fingerprint,
          onPressed: () => _setOutput(
            EncodingCryptoService.instance.sha256Hash(_inputController.text),
          ),
        ),
        _ActionButton(
          label: 'SHA-512',
          icon: Icons.fingerprint,
          onPressed: () => _setOutput(
            EncodingCryptoService.instance.sha512Hash(_inputController.text),
          ),
        ),
        _ActionButton(
          label: 'HMAC-SHA256',
          icon: Icons.security,
          onPressed: () => _setOutput(
            EncodingCryptoService.instance.hmacSha256(
              _keyController.text,
              _inputController.text,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildToolTab({
    required String title,
    required List<_ActionButton> actions,
    bool showKey = false,
  }) {
    return Column(
      children: [
        Expanded(
          flex: 2,
          child: TextField(
            controller: _inputController,
            maxLines: null,
            expands: true,
            decoration: const InputDecoration(
              hintText: 'أدخل النص هنا...',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.all(12),
            ),
          ),
        ),
        if (showKey) ...[
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: TextField(
              controller: _keyController,
              decoration: const InputDecoration(
                labelText: 'المفتاح (لـ HMAC)',
                border: OutlineInputBorder(),
              ),
            ),
          ),
        ],
        Padding(
          padding: const EdgeInsets.all(8),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: actions.map((action) {
              return FilledButton.icon(
                onPressed: action.onPressed,
                icon: Icon(action.icon),
                label: Text(action.label),
              );
            }).toList(),
          ),
        ),
        Expanded(
          flex: 3,
          child: Container(
            margin: const EdgeInsets.all(8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('النتيجة:',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    IconButton(
                      icon: const Icon(Icons.copy, size: 20),
                      onPressed: _copyOutput,
                    ),
                  ],
                ),
                const Divider(),
                Expanded(
                  child: SingleChildScrollView(
                    child: SelectableText(
                      _output.isEmpty ? 'النتيجة ستظهر هنا' : _output,
                      style: const TextStyle(fontFamily: 'JetBrains Mono', fontSize: 13),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _setOutput(String value) {
    setState(() => _output = value);
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

class _ActionButton {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;
}
