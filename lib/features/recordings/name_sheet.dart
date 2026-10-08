import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_buttons.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/overlays.dart';
import 'file_actions.dart';
import 'voice_style.dart';

/// Figma "BottomSheet/Save recording" (11:151) when [voice] is given,
/// otherwise "BottomSheet/Rename recording" (11:334).
/// Returns the trimmed name, or null if cancelled.
Future<String?> showNameSheet(
  BuildContext context, {
  required String initial,
  VoiceStyle? voice,
}) {
  return showAppSheet<String>(
    context,
    builder: (_) => _NameSheet(initial: initial, voice: voice),
  );
}

class _NameSheet extends StatefulWidget {
  const _NameSheet({required this.initial, this.voice});

  final String initial;
  final VoiceStyle? voice;

  @override
  State<_NameSheet> createState() => _NameSheetState();
}

class _NameSheetState extends State<_NameSheet> {
  static const _max = 40;
  late final _controller = TextEditingController(
    text: widget.initial.length > _max
        ? widget.initial.substring(0, _max)
        : widget.initial,
  );

  bool get _isSave => widget.voice != null;
  String get _value => _controller.text.trim();

  @override
  void initState() {
    super.initState();
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (_value.isEmpty) return;
    Navigator.of(context).pop(_value);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const DragHandle(),
            const SizedBox(height: 20),
            Text(
              _isSave ? 'Save recording' : 'Rename recording',
              style: AppText.title.copyWith(color: c.textPrimary),
            ),
            const SizedBox(height: 20),
            AppTextField(
              controller: _controller,
              label: 'Name',
              helper: _isSave
                  ? 'Used as the file name and in History.'
                  : 'Up to $_max characters.',
              maxLength: _max,
              autofocus: !_isSave,
              onSubmitted: (_) => _submit(),
            ),
            if (_isSave) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: c.surfaceRaised,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Column(
                  children: [
                    _DetailRow(
                        label: 'Voice', value: widget.voice!.label, divider: true),
                    const _DetailRow(label: 'Format', value: ExportFormat.label),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 1),
                    child: Icon(LucideIcons.info, size: 16, color: c.textSecondary),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Next, choose where to save the file on your device.',
                      style: AppText.caption.copyWith(color: c.textSecondary),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 20),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: AppTextButton(
                    label: 'Cancel',
                    tone: TextButtonTone.neutral,
                    expand: true,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: PrimaryButton(
                    label: 'Save',
                    onPressed: _value.isEmpty ? null : _submit,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value, this.divider = false});

  final String label;
  final String value;
  final bool divider;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: divider ? Border(bottom: BorderSide(color: c.border)) : null,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppText.body.copyWith(color: c.textSecondary)),
          Text(value, style: AppText.bodyStrong.copyWith(color: c.textPrimary)),
        ],
      ),
    );
  }
}
