import 'package:flutter/material.dart';

/// Markdown formatting toolbar for text editing
/// Provides buttons to insert markdown syntax (bold, italic, links, etc.)
class MarkdownToolbar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback? onPreviewToggle;
  final bool showPreview;

  const MarkdownToolbar({
    super.key,
    required this.controller,
    this.onPreviewToggle,
    this.showPreview = false,
  });

  /// Insert markdown syntax around selected text
  void _insertMarkdown(String before, String after,
      [String placeholder = 'text']) {
    final text = controller.text;
    final selection = controller.selection;

    // Get selected text or use placeholder
    final selectedText = selection.textInside(text);
    final insertText = selectedText.isEmpty ? placeholder : selectedText;

    // Build new text with markdown
    final newText = text.replaceRange(
      selection.start,
      selection.end,
      before + insertText + after,
    );

    // Update controller
    controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(
        offset:
            selection.start + before.length + insertText.length + after.length,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          // Bold
          IconButton(
            icon: const Icon(Icons.format_bold, size: 20),
            onPressed: () => _insertMarkdown('**', '**', 'bold text'),
            tooltip: 'Bold',
            padding: const EdgeInsets.all(8),
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),

          // Italic
          IconButton(
            icon: const Icon(Icons.format_italic, size: 20),
            onPressed: () => _insertMarkdown('*', '*', 'italic text'),
            tooltip: 'Italic',
            padding: const EdgeInsets.all(8),
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),

          // Link
          IconButton(
            icon: const Icon(Icons.link, size: 20),
            onPressed: () => _insertMarkdown('[', '](url)', 'link text'),
            tooltip: 'Insert Link',
            padding: const EdgeInsets.all(8),
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),

          // Bullet List
          IconButton(
            icon: const Icon(Icons.format_list_bulleted, size: 20),
            onPressed: () {
              final text = controller.text;
              final selection = controller.selection;
              final lineStart = text.lastIndexOf('\n', selection.start - 1) + 1;

              controller.value = TextEditingValue(
                text: text.substring(0, lineStart) +
                    '- ' +
                    text.substring(lineStart),
                selection: TextSelection.collapsed(offset: selection.start + 2),
              );
            },
            tooltip: 'Bullet List',
            padding: const EdgeInsets.all(8),
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),

          // Code
          IconButton(
            icon: const Icon(Icons.code, size: 20),
            onPressed: () => _insertMarkdown('`', '`', 'code'),
            tooltip: 'Inline Code',
            padding: const EdgeInsets.all(8),
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),

          const Spacer(),

          // Preview Toggle
          if (onPreviewToggle != null) ...[
            const VerticalDivider(
                width: 1, thickness: 1, indent: 8, endIndent: 8),
            const SizedBox(width: 4),
            TextButton.icon(
              onPressed: onPreviewToggle,
              icon: Icon(
                showPreview ? Icons.edit : Icons.visibility,
                size: 18,
              ),
              label: Text(showPreview ? 'Edit' : 'Preview'),
              style: TextButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
