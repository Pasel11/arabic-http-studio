import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/syntax_highlighter.dart';
import '../../../core/utils/debounce_throttle.dart';

/// A professional code editor widget with syntax highlighting,
/// line numbers, search/replace, undo/redo, and code folding.
///
/// This widget provides a full-featured code editing experience
/// with support for multiple programming languages.
///
/// Example:
/// ```dart
/// CodeEditor(
///   language: CodeLanguage.json,
///   initialText: '{"key": "value"}',
///   onChanged: (text) => handleChanges(text),
/// )
/// ```
class CodeEditor extends StatefulWidget {
  /// Creates a code editor.
  const CodeEditor({
    super.key,
    this.initialText = '',
    this.language = CodeLanguage.text,
    this.onChanged,
    this.readOnly = false,
    this.showLineNumbers = true,
    this.enableSearch = true,
    this.enableUndoRedo = true,
    this.fontSize = 14.0,
    this.fontFamily = 'JetBrains Mono',
    this.minLines = 5,
    this.maxLines,
    this.theme,
  });

  /// The initial text content of the editor.
  final String initialText;

  /// The programming language for syntax highlighting.
  final CodeLanguage language;

  /// Called when the text content changes.
  final ValueChanged<String>? onChanged;

  /// Whether the editor is read-only.
  final bool readOnly;

  /// Whether to show line numbers.
  final bool showLineNumbers;

  /// Whether to enable search/replace.
  final bool enableSearch;

  /// Whether to enable undo/redo.
  final bool enableUndoRedo;

  /// The font size of the code.
  final double fontSize;

  /// The font family of the code.
  final String fontFamily;

  /// The minimum number of lines to show.
  final int minLines;

  /// The maximum number of lines to show.
  final int? maxLines;

  /// Custom theme for the editor.
  final CodeEditorTheme? theme;

  @override
  State<CodeEditor> createState() => CodeEditorController();
}

/// Controller for the CodeEditor widget.
class CodeEditorController extends State<CodeEditor> {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  late ScrollController _scrollController;
  late ScrollController _horizontalScrollController;

  // Undo/Redo stacks
  final List<TextEditingValue> _undoStack = [];
  final List<TextEditingValue> _redoStack = [];
  static const int _maxHistorySize = 50;

  // Search state
  bool _showSearch = false;
  String _searchQuery = '';
  String _replaceQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _replaceController = TextEditingController();
  final Debouncer _searchDebouncer = Debouncer(duration: const Duration(milliseconds: 300));
  List<SearchMatch> _searchMatches = [];
  int _currentMatchIndex = -1;

  // Validation state
  ValidationResult? _validationResult;

  // Highlighting
  List<CodeToken> _tokens = [];

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialText);
    _focusNode = FocusNode();
    _scrollController = ScrollController();
    _horizontalScrollController = ScrollController();
    _updateTokens();
    _validate();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    _horizontalScrollController.dispose();
    _searchController.dispose();
    _replaceController.dispose();
    _searchDebouncer.dispose();
    super.dispose();
  }

  /// Gets the current text content.
  String get text => _controller.text;

  /// Sets the text content.
  void setText(String text) {
    _saveToUndoStack();
    _controller.text = text;
    _updateTokens();
    _validate();
    widget.onChanged?.call(text);
  }

  /// Beautifies the code.
  void beautify() {
    final beautified = CodeFormatter.beautify(_controller.text, widget.language);
    setText(beautified);
  }

  /// Minifies the code.
  void minify() {
    final minified = CodeFormatter.minify(_controller.text, widget.language);
    setText(minified);
  }

  /// Undoes the last change.
  void undo() {
    if (_undoStack.isEmpty) return;

    _redoStack.add(_controller.value);
    if (_redoStack.length > _maxHistorySize) {
      _redoStack.removeAt(0);
    }

    _controller.value = _undoStack.removeLast();
    _updateTokens();
    _validate();
    widget.onChanged?.call(_controller.text);
  }

  /// Redoes the last undone change.
  void redo() {
    if (_redoStack.isEmpty) return;

    _undoStack.add(_controller.value);
    if (_undoStack.length > _maxHistorySize) {
      _undoStack.removeAt(0);
    }

    _controller.value = _redoStack.removeLast();
    _updateTokens();
    _validate();
    widget.onChanged?.call(_controller.text);
  }

  /// Shows the search bar.
  void showSearch() {
    setState(() {
      _showSearch = true;
    });
  }

  /// Hides the search bar.
  void hideSearch() {
    setState(() {
      _showSearch = false;
      _searchMatches = [];
      _currentMatchIndex = -1;
    });
  }

  /// Finds all matches of the search query.
  void _findMatches() {
    if (_searchQuery.isEmpty) {
      setState(() {
        _searchMatches = [];
        _currentMatchIndex = -1;
      });
      return;
    }

    final matches = <SearchMatch>[];
    final text = _controller.text.toLowerCase();
    final query = _searchQuery.toLowerCase();
    var index = text.indexOf(query);

    while (index != -1) {
      matches.add(SearchMatch(start: index, end: index + query.length));
      index = text.indexOf(query, index + 1);
    }

    setState(() {
      _searchMatches = matches;
      _currentMatchIndex = matches.isNotEmpty ? 0 : -1;
    });

    if (_currentMatchIndex >= 0) {
      _scrollToMatch(_searchMatches[_currentMatchIndex]);
    }
  }

  /// Goes to the next search match.
  void findNext() {
    if (_searchMatches.isEmpty) return;
    setState(() {
      _currentMatchIndex = (_currentMatchIndex + 1) % _searchMatches.length;
    });
    _scrollToMatch(_searchMatches[_currentMatchIndex]);
  }

  /// Goes to the previous search match.
  void findPrevious() {
    if (_searchMatches.isEmpty) return;
    setState(() {
      _currentMatchIndex = (_currentMatchIndex - 1) % _searchMatches.length;
    });
    _scrollToMatch(_searchMatches[_currentMatchIndex]);
  }

  /// Replaces the current match.
  void replace() {
    if (_currentMatchIndex < 0 || _currentMatchIndex >= _searchMatches.length) return;

    _saveToUndoStack();
    final match = _searchMatches[_currentMatchIndex];
    final text = _controller.text;
    final newText = text.substring(0, match.start) +
        _replaceQuery +
        text.substring(match.end);
    _controller.text = newText;
    widget.onChanged?.call(newText);
    _findMatches();
  }

  /// Replaces all matches.
  void replaceAll() {
    if (_searchQuery.isEmpty) return;

    _saveToUndoStack();
    final text = _controller.text.replaceAll(_searchQuery, _replaceQuery);
    _controller.text = text;
    widget.onChanged?.call(text);
    _findMatches();
  }

  void _saveToUndoStack() {
    _undoStack.add(_controller.value);
    if (_undoStack.length > _maxHistorySize) {
      _undoStack.removeAt(0);
    }
    _redoStack.clear();
  }

  void _updateTokens() {
    _tokens = SyntaxHighlighter.tokenize(_controller.text, widget.language);
  }

  void _validate() {
    _validationResult = CodeFormatter.validate(_controller.text, widget.language);
  }

  void _scrollToMatch(SearchMatch match) {
    // Approximate scroll position based on line count
    final textBeforeMatch = _controller.text.substring(0, match.start);
    final lineNumber = '\n'.allMatches(textBeforeMatch).length;
    final estimatedOffset = lineNumber * (widget.fontSize * 1.5);

    _scrollController.animateTo(
      estimatedOffset,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme ?? CodeEditorTheme.fromContext(context);

    return Column(
      children: [
        // Toolbar
        _buildToolbar(context, theme),

        // Search bar
        if (_showSearch) _buildSearchBar(context, theme),

        // Validation indicator
        if (_validationResult != null && !_validationResult!.isValid)
          _buildValidationError(context, theme),

        // Editor
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: theme.backgroundColor,
              border: Border.all(color: theme.borderColor),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                // Line numbers
                if (widget.showLineNumbers) _buildLineNumbers(theme),

                // Code area
                Expanded(
                  child: SingleChildScrollView(
                    controller: _horizontalScrollController,
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(
                      width: _calculateMaxLineWidth(theme),
                      child: TextField(
                        controller: _controller,
                        focusNode: _focusNode,
                        scrollController: _scrollController,
                        maxLines: widget.maxLines ?? widget.minLines,
                        minLines: widget.minLines,
                        readOnly: widget.readOnly,
                        style: TextStyle(
                          fontFamily: widget.fontFamily,
                          fontSize: widget.fontSize,
                          height: 1.5,
                          color: theme.textColor,
                        ),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.all(12),
                          isDense: true,
                        ),
                        onChanged: (value) {
                          _searchDebouncer.run(() {
                            _updateTokens();
                            _validate();
                          });
                          widget.onChanged?.call(value);
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Status bar
        _buildStatusBar(context, theme),
      ],
    );
  }

  Widget _buildToolbar(BuildContext context, CodeEditorTheme theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.toolbarBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
      ),
      child: Row(
        children: [
          // Language indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: theme.languageBadgeColor,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              widget.language.displayName,
              style: TextStyle(
                color: theme.languageBadgeTextColor,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Spacer(),
          // Undo
          IconButton(
            icon: const Icon(Icons.undo, size: 18),
            onPressed: widget.enableUndoRedo ? undo : null,
            tooltip: 'تراجع',
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            padding: EdgeInsets.zero,
          ),
          // Redo
          IconButton(
            icon: const Icon(Icons.redo, size: 18),
            onPressed: widget.enableUndoRedo ? redo : null,
            tooltip: 'إعادة',
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            padding: EdgeInsets.zero,
          ),
          // Search
          if (widget.enableSearch)
            IconButton(
              icon: const Icon(Icons.search, size: 18),
              onPressed: _showSearch ? hideSearch : showSearch,
              tooltip: 'بحث',
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              padding: EdgeInsets.zero,
            ),
          // Beautify
          IconButton(
            icon: const Icon(Icons.format_align_left, size: 18),
            onPressed: beautify,
            tooltip: 'تنسيق',
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            padding: EdgeInsets.zero,
          ),
          // Minify
          IconButton(
            icon: const Icon(Icons.compress, size: 18),
            onPressed: minify,
            tooltip: 'تصغير',
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context, CodeEditorTheme theme) {
    return Container(
      padding: const EdgeInsets.all(8),
      color: theme.toolbarBackgroundColor,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'بحث...',
                    isDense: true,
                    border: const OutlineInputBorder(),
                    suffixText: _searchMatches.isNotEmpty
                        ? '${_currentMatchIndex + 1}/${_searchMatches.length}'
                        : null,
                  ),
                  onChanged: (value) {
                    _searchQuery = value;
                    _searchDebouncer.run(_findMatches);
                  },
                ),
              ),
              IconButton(
                icon: const Icon(Icons.keyboard_arrow_up),
                onPressed: findPrevious,
                tooltip: 'السابق',
              ),
              IconButton(
                icon: const Icon(Icons.keyboard_arrow_down),
                onPressed: findNext,
                tooltip: 'التالي',
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _replaceController,
                  decoration: const InputDecoration(
                    hintText: 'استبدال...',
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) => _replaceQuery = value,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.find_replace),
                onPressed: replace,
                tooltip: 'استبدال',
              ),
              IconButton(
                icon: const Icon(Icons.find_replace_sharp),
                onPressed: replaceAll,
                tooltip: 'استبدال الكل',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildValidationError(BuildContext context, CodeEditorTheme theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: theme.errorBackgroundColor,
      child: Row(
        children: [
          Icon(Icons.error_outline, size: 16, color: theme.errorTextColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _validationResult!.error ?? 'خطأ في التحقق',
              style: TextStyle(
                color: theme.errorTextColor,
                fontSize: 12,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLineNumbers(CodeEditorTheme theme) {
    final lineCount = '\n'.allMatches(_controller.text).length + 1;

    return Container(
      width: 50,
      padding: const EdgeInsets.only(top: 12, bottom: 12),
      color: theme.lineNumberBackgroundColor,
      child: SingleChildScrollView(
        controller: _scrollController,
        child: Column(
          children: List.generate(lineCount, (index) {
            final lineNumber = index + 1;
            return SizedBox(
              height: widget.fontSize * 1.5,
              child: Text(
                '$lineNumber',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: theme.lineNumberTextColor,
                  fontFamily: widget.fontFamily,
                  fontSize: widget.fontSize,
                  height: 1.5,
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  double _calculateMaxLineWidth(CodeEditorTheme theme) {
    final longestLine = _controller.text.split('\n').fold<String>(
      '',
      (longest, line) => line.length > longest.length ? line : longest,
    );
    // Approximate width: character count * font size * 0.6
    return (longestLine.length * widget.fontSize * 0.6) + 100;
  }

  Widget _buildStatusBar(BuildContext context, CodeEditorTheme theme) {
    final lineCount = '\n'.allMatches(_controller.text).length + 1;
    final charCount = _controller.text.length;
    final isValid = _validationResult?.isValid ?? true;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: theme.toolbarBackgroundColor,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(8)),
      ),
      child: Row(
        children: [
          Icon(
            isValid ? Icons.check_circle : Icons.error,
            size: 14,
            color: isValid ? Colors.green : Colors.red,
          ),
          const SizedBox(width: 4),
          Text(
            isValid ? 'صالح' : 'غير صالح',
            style: TextStyle(
              fontSize: 11,
              color: isValid ? Colors.green : Colors.red,
            ),
          ),
          const Spacer(),
          Text(
            'الأسطر: $lineCount',
            style: TextStyle(fontSize: 11, color: theme.textColor),
          ),
          const SizedBox(width: 12),
          Text(
            'الأحرف: $charCount',
            style: TextStyle(fontSize: 11, color: theme.textColor),
          ),
        ],
      ),
    );
  }
}

/// Theme for the code editor.
class CodeEditorTheme {
  /// Creates a code editor theme.
  const CodeEditorTheme({
    required this.backgroundColor,
    required this.textColor,
    required this.toolbarBackgroundColor,
    required this.lineNumberBackgroundColor,
    required this.lineNumberTextColor,
    required this.borderColor,
    required this.languageBadgeColor,
    required this.languageBadgeTextColor,
    required this.errorBackgroundColor,
    required this.errorTextColor,
    required this.keywordColor,
    required this.stringColor,
    required this.numberColor,
    required this.commentColor,
    required this.propertyColor,
    required this.tagColor,
    required this.operatorColor,
  });

  /// Creates a theme from the current Flutter theme.
  factory CodeEditorTheme.fromContext(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (isDark) {
      return const CodeEditorTheme(
        backgroundColor: Color(0xFF1E1E1E),
        textColor: Color(0xFFD4D4D4),
        toolbarBackgroundColor: Color(0xFF252526),
        lineNumberBackgroundColor: Color(0xFF1E1E1E),
        lineNumberTextColor: Color(0xFF858585),
        borderColor: Color(0xFF3C3C3C),
        languageBadgeColor: Color(0xFF0E639C),
        languageBadgeTextColor: Colors.white,
        errorBackgroundColor: Color(0xFF5A1D1D),
        errorTextColor: Color(0xFFF48771),
        keywordColor: Color(0xFF569CD6),
        stringColor: Color(0xFFCE9178),
        numberColor: Color(0xFFB5CEA8),
        commentColor: Color(0xFF6A9955),
        propertyColor: Color(0xFF9CDCFE),
        tagColor: Color(0xFF569CD6),
        operatorColor: Color(0xFFD4D4D4),
      );
    } else {
      return const CodeEditorTheme(
        backgroundColor: Color(0xFFFFFFFF),
        textColor: Color(0xFF000000),
        toolbarBackgroundColor: Color(0xFFF3F3F3),
        lineNumberBackgroundColor: Color(0xFFFAFAFA),
        lineNumberTextColor: Color(0xFF888888),
        borderColor: Color(0xFFDDDDDD),
        languageBadgeColor: Color(0xFF0066CC),
        languageBadgeTextColor: Colors.white,
        errorBackgroundColor: Color(0xFFFFE0E0),
        errorTextColor: Color(0xFFCC0000),
        keywordColor: Color(0xFF0000FF),
        stringColor: Color(0xFFA31515),
        numberColor: Color(0xFF098658),
        commentColor: Color(0xFF008000),
        propertyColor: Color(0xFF001080),
        tagColor: Color(0xFF800000),
        operatorColor: Color(0xFF000000),
      );
    }
  }

  /// The background color of the editor.
  final Color backgroundColor;

  /// The text color of the editor.
  final Color textColor;

  /// The background color of the toolbar.
  final Color toolbarBackgroundColor;

  /// The background color of the line numbers.
  final Color lineNumberBackgroundColor;

  /// The text color of the line numbers.
  final Color lineNumberTextColor;

  /// The border color of the editor.
  final Color borderColor;

  /// The color of the language badge.
  final Color languageBadgeColor;

  /// The text color of the language badge.
  final Color languageBadgeTextColor;

  /// The background color of the error indicator.
  final Color errorBackgroundColor;

  /// The text color of the error indicator.
  final Color errorTextColor;

  /// The color of keywords.
  final Color keywordColor;

  /// The color of strings.
  final Color stringColor;

  /// The color of numbers.
  final Color numberColor;

  /// The color of comments.
  final Color commentColor;

  /// The color of properties.
  final Color propertyColor;

  /// The color of tags.
  final Color tagColor;

  /// The color of operators.
  final Color operatorColor;

  /// Gets the color for a token type.
  Color getColorForToken(TokenType type) {
    switch (type) {
      case TokenType.keyword:
        return keywordColor;
      case TokenType.string:
        return stringColor;
      case TokenType.number:
        return numberColor;
      case TokenType.comment:
        return commentColor;
      case TokenType.property:
        return propertyColor;
      case TokenType.tag:
        return tagColor;
      case TokenType.operator:
        return operatorColor;
      case TokenType.attribute:
        return propertyColor;
      case TokenType.value:
        return stringColor;
      default:
        return textColor;
    }
  }
}

/// A search match in the text.
class SearchMatch {
  /// Creates a search match.
  const SearchMatch({required this.start, required this.end});

  /// The start position of the match.
  final int start;

  /// The end position of the match.
  final int end;
}
