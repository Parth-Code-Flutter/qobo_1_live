import 'package:aligned_rewards/constants/color_constants.dart';
import 'package:aligned_rewards/utils/text_utils/text_styles.dart';
import 'package:aligned_rewards/utils/ui_utils/app_ui_utils.dart';
import 'package:flutter/material.dart';

/// Rich Text Editor Widget with formatting toolbar
/// Provides text editing capabilities with formatting options like bold, italic, underline, lists, etc.
class RichTextEditorWidget extends StatefulWidget {
  /// Controller for the text editor
  final TextEditingController controller;
  
  /// Placeholder text to show when editor is empty
  final String? placeholder;
  
  /// Minimum height of the editor
  final double? minHeight;
  
  /// Maximum height of the editor
  final double? maxHeight;
  
  /// Callback when text changes
  final ValueChanged<String>? onChanged;

  const RichTextEditorWidget({
    super.key,
    required this.controller,
    this.placeholder,
    this.minHeight,
    this.maxHeight,
    this.onChanged,
  });

  @override
  State<RichTextEditorWidget> createState() => _RichTextEditorWidgetState();
}

class _RichTextEditorWidgetState extends State<RichTextEditorWidget> {
  // Track formatting states
  bool _isBold = false;
  bool _isItalic = false;
  bool _isUnderline = false;
  bool _isBulletList = false;
  bool _isNumberedList = false;
  
  // Focus node for the text field
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // Listen to text changes to update formatting states
    widget.controller.addListener(_onTextChanged);
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    _focusNode.removeListener(_onFocusChanged);
    _focusNode.dispose();
    super.dispose();
  }

  /// Handle text changes to update formatting states
  void _onTextChanged() {
    if (widget.onChanged != null) {
      widget.onChanged!(widget.controller.text);
    }
  }

  /// Handle focus changes
  void _onFocusChanged() {
    // Focus change handling if needed
  }

  /// Apply bold formatting
  void _applyBold() {
    setState(() {
      _isBold = !_isBold;
    });
    _applyFormatting('**', '**');
  }

  /// Apply italic formatting
  void _applyItalic() {
    setState(() {
      _isItalic = !_isItalic;
    });
    _applyFormatting('*', '*');
  }

  /// Apply underline formatting
  void _applyUnderline() {
    setState(() {
      _isUnderline = !_isUnderline;
    });
    _applyFormatting('<u>', '</u>');
  }

  /// Apply bullet list formatting
  void _applyBulletList() {
    setState(() {
      _isBulletList = !_isBulletList;
      _isNumberedList = false; // Disable numbered list if bullet is active
    });
    _insertAtCursor('- ');
  }

  /// Apply numbered list formatting
  void _applyNumberedList() {
    setState(() {
      _isNumberedList = !_isNumberedList;
      _isBulletList = false; // Disable bullet list if numbered is active
    });
    _insertAtCursor('1. ');
  }

  /// Insert link formatting
  void _insertLink() {
    _showLinkDialog();
  }

  /// Clear all formatting
  void _clearFormatting() {
    setState(() {
      _isBold = false;
      _isItalic = false;
      _isUnderline = false;
      _isBulletList = false;
      _isNumberedList = false;
    });
    // Remove markdown-like formatting from text
    String text = widget.controller.text;
    text = text.replaceAll(RegExp(r'\*\*(.*?)\*\*'), r'$1'); // Remove bold
    text = text.replaceAll(RegExp(r'\*(.*?)\*'), r'$1'); // Remove italic
    text = text.replaceAll(RegExp(r'<u>(.*?)</u>'), r'$1'); // Remove underline
    widget.controller.text = text;
    widget.controller.selection = TextSelection.collapsed(offset: widget.controller.text.length);
  }

  /// Apply formatting to selected text or insert formatting markers
  void _applyFormatting(String prefix, String suffix) {
    final selection = widget.controller.selection;
    if (selection.isValid) {
      final text = widget.controller.text;
      final selectedText = selection.textInside(text);
      
      if (selectedText.isNotEmpty) {
        // Replace selected text with formatted version
        final formattedText = '$prefix$selectedText$suffix';
        widget.controller.text = text.replaceRange(
          selection.start,
          selection.end,
          formattedText,
        );
        // Restore selection to cover the formatted text
        widget.controller.selection = TextSelection(
          baseOffset: selection.start,
          extentOffset: selection.start + formattedText.length,
        );
      } else {
        // Insert formatting markers at cursor
        _insertAtCursor('$prefix$suffix');
        // Move cursor between markers
        widget.controller.selection = TextSelection.collapsed(
          offset: selection.start + prefix.length,
        );
      }
    }
  }

  /// Insert text at cursor position
  void _insertAtCursor(String text) {
    final selection = widget.controller.selection;
    if (selection.isValid) {
      final currentText = widget.controller.text;
      final newText = currentText.replaceRange(
        selection.start,
        selection.end,
        text,
      );
      widget.controller.text = newText;
      widget.controller.selection = TextSelection.collapsed(
        offset: selection.start + text.length,
      );
    }
  }

  /// Show dialog to insert link
  void _showLinkDialog() {
    final linkTextController = TextEditingController();
    final linkUrlController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Insert Link'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: linkTextController,
              decoration: const InputDecoration(
                labelText: 'Link Text',
                hintText: 'Enter link text',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: linkUrlController,
              decoration: const InputDecoration(
                labelText: 'URL',
                hintText: 'https://example.com',
              ),
              keyboardType: TextInputType.url,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (linkTextController.text.isNotEmpty &&
                  linkUrlController.text.isNotEmpty) {
                final linkMarkdown =
                    '[${linkTextController.text}](${linkUrlController.text})';
                _insertAtCursor(linkMarkdown);
                Navigator.of(context).pop();
              }
            },
            child: const Text('Insert'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: kColorWhite,
        borderRadius: AppUIUtils.primaryBorderRadius,
        border: Border.all(color: kColorTextFieldBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Formatting toolbar
          _buildToolbar(),
          // Divider between toolbar and editor
          Divider(height: 1, thickness: 0.5, color: kColorGreyDA),
          // Text editor area
          _buildEditor(),
        ],
      ),
    );
  }

  /// Build formatting toolbar with all formatting options
  Widget _buildToolbar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          // Text style dropdown (Normal)
          _buildToolbarButton(
            icon: Icons.format_size,
            label: 'Normal',
            onTap: () {
              // Text style selection can be implemented here
            // For now, just show it's selected
            },
            isSelected: true,
          ),
          const SizedBox(width: 4),
          const Text(':', style: TextStyle(color: kColorGrey76)),
          const SizedBox(width: 8),
          // Bold button
          _buildToolbarIconButton(
            icon: Icons.format_bold,
            isSelected: _isBold,
            onTap: _applyBold,
            tooltip: 'Bold',
          ),
          const SizedBox(width: 4),
          // Italic button
          _buildToolbarIconButton(
            icon: Icons.format_italic,
            isSelected: _isItalic,
            onTap: _applyItalic,
            tooltip: 'Italic',
          ),
          const SizedBox(width: 4),
          // Underline button
          _buildToolbarIconButton(
            icon: Icons.format_underlined,
            isSelected: _isUnderline,
            onTap: _applyUnderline,
            tooltip: 'Underline',
          ),
          const SizedBox(width: 4),
          // Link button
          _buildToolbarIconButton(
            icon: Icons.link,
            isSelected: false,
            onTap: _insertLink,
            tooltip: 'Insert Link',
          ),
          const SizedBox(width: 4),
          // Bullet list button
          _buildToolbarIconButton(
            icon: Icons.format_list_bulleted,
            isSelected: _isBulletList,
            onTap: _applyBulletList,
            tooltip: 'Bullet List',
          ),
          const SizedBox(width: 4),
          // Numbered list button
          _buildToolbarIconButton(
            icon: Icons.format_list_numbered,
            isSelected: _isNumberedList,
            onTap: _applyNumberedList,
            tooltip: 'Numbered List',
          ),
          const SizedBox(width: 4),
          // Clear formatting button
          _buildToolbarIconButton(
            icon: Icons.format_clear,
            isSelected: false,
            onTap: _clearFormatting,
            tooltip: 'Clear Formatting',
          ),
        ],
      ),
    );
  }

  /// Build toolbar button with icon
  Widget _buildToolbarIconButton({
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    String? tooltip,
  }) {
    return Tooltip(
      message: tooltip ?? '',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: isSelected ? kColorGrey187.withValues(alpha: 0.2) : Colors.transparent,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Icon(
            icon,
            size: 20,
            color: isSelected ? kColorPrimary : kColorGrey76,
          ),
        ),
      ),
    );
  }

  /// Build toolbar button with label
  Widget _buildToolbarButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool isSelected,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? kColorGrey187.withValues(alpha: 0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: kColorGrey76),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyles.kRegularLato(
                fontSize: 12,
                colors: kColorGrey76,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build text editor area
  /// Uses flexible height constraints to prevent overflow
  Widget _buildEditor() {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate available height, ensuring it doesn't exceed maxHeight
        final availableHeight = constraints.maxHeight;
        final minHeight = widget.minHeight ?? 300;
        final maxHeight = widget.maxHeight ?? 500;
        
        // Use the smaller of available height or maxHeight
        final editorHeight = availableHeight > maxHeight 
            ? maxHeight 
            : (availableHeight > minHeight ? availableHeight : minHeight);
        
        return Container(
          height: editorHeight,
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: widget.controller,
            focusNode: _focusNode,
            maxLines: null,
            expands: true,
            textAlignVertical: TextAlignVertical.top,
            style: TextStyles.kRegularLato(
              fontSize: 14,
              colors: kColorBlack,
            ),
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: widget.placeholder ?? 'Start typing...',
              hintStyle: TextStyles.kRegularLato(
                fontSize: 14,
                colors: kColorGrey76,
              ).copyWith(fontStyle: FontStyle.italic),
              contentPadding: EdgeInsets.zero,
            ),
          ),
        );
      },
    );
  }
}

