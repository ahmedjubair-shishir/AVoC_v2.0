import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_theme.dart';

/// Figma "Text field": label above, 56dp field (radius 12), clear button,
/// helper text + counter. Focused = 2px primary border. Max 40 characters.
class AppTextField extends StatefulWidget {
  const AppTextField({
    super.key,
    required this.controller,
    required this.label,
    this.helper,
    this.maxLength = 40,
    this.autofocus = false,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String label;
  final String? helper;
  final int maxLength;
  final bool autofocus;
  final ValueChanged<String>? onSubmitted;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(_rebuild);
    widget.controller.addListener(_rebuild);
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _focus.dispose();
    widget.controller.removeListener(_rebuild);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final focused = _focus.hasFocus;
    final text = widget.controller.text;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label, style: AppText.label.copyWith(color: c.textPrimary)),
        const SizedBox(height: AppSpace.s8),
        AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: 56,
          padding: EdgeInsets.only(left: focused ? 15 : 16, right: 4),
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: focused ? c.primary : c.textSecondary,
              width: focused ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: widget.controller,
                  focusNode: _focus,
                  autofocus: widget.autofocus,
                  maxLength: widget.maxLength,
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.done,
                  onSubmitted: widget.onSubmitted,
                  style: AppText.body.copyWith(color: c.textPrimary),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    counterText: '',
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
              if (text.isNotEmpty)
                IconButton(
                  tooltip: 'Clear name',
                  onPressed: () {
                    widget.controller.clear();
                    _focus.requestFocus();
                  },
                  icon: Icon(LucideIcons.x, color: c.textPrimary),
                  constraints:
                      const BoxConstraints.tightFor(width: 48, height: 48),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpace.s8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                widget.helper ?? '',
                style: AppText.caption.copyWith(color: c.textSecondary),
              ),
            ),
            const SizedBox(width: AppSpace.s8),
            Text(
              '${text.characters.length}/${widget.maxLength}',
              style: AppText.caption.copyWith(color: c.textSecondary),
            ),
          ],
        ),
      ],
    );
  }
}
