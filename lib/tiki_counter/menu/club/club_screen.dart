import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:b_ball/tiki_counter/menu/home/club_badge.dart';
import 'package:b_ball/tiki_counter/menu/setup/tiki_setup.dart';
import 'package:b_ball/tiki_counter/menu/widgets/menu_header.dart';
import 'package:b_ball/tiki_counter/theme/tiki_palette.dart';
import 'package:b_ball/tiki_counter/ui/tiki_text.dart';

/// Your club's name and 3-letter short form. The short form fills itself
/// from the name's initials until you edit it yourself.
class ClubScreen extends StatefulWidget {
  final TikiSetup setup;
  final ValueChanged<TikiSetup> onSave;
  final VoidCallback onBack;

  const ClubScreen({
    super.key,
    required this.setup,
    required this.onSave,
    required this.onBack,
  });

  @override
  State<ClubScreen> createState() => _ClubScreenState();
}

class _ClubScreenState extends State<ClubScreen> {
  late final TextEditingController _name =
      TextEditingController(text: widget.setup.clubName);
  late final TextEditingController _code =
      TextEditingController(text: widget.setup.clubCode);
  bool _codeTouched = false;

  @override
  void dispose() {
    _name.dispose();
    _code.dispose();
    super.dispose();
  }

  /// "Lagos Tiki FC" → "LTF"; short names borrow their next letters.
  static String initials(String name) {
    final letter = RegExp('[A-Za-z]');
    final firsts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty && letter.hasMatch(w[0]))
        .map((w) => w[0])
        .join();
    final all = (firsts + name.replaceAll(RegExp('[^A-Za-z]'), '')).toUpperCase();
    return all.length >= 3 ? all.substring(0, 3) : all.padRight(3, 'X');
  }

  void _nameChanged(String v) {
    if (!_codeTouched) _code.text = initials(v);
    setState(() {});
  }

  bool get _valid =>
      _name.text.trim().isNotEmpty && _code.text.trim().length == 3;

  void _save() {
    if (!_valid) return;
    widget.onSave(
      widget.setup.copyWith(
        clubName: _name.text.trim(),
        clubCode: _code.text.trim().toUpperCase(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final code = _code.text.toUpperCase();
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            MenuHeader(title: 'Your club', onBack: widget.onBack),
            const SizedBox(height: 18),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    width: 380,
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SectionLabel('Team name'),
                          _field(
                            _name,
                            maxLength: 22,
                            onChanged: _nameChanged,
                            hint: 'e.g. Lagos Tiki FC',
                          ),
                          const SizedBox(height: 18),
                          const SectionLabel('Short form'),
                          SizedBox(
                            width: 150,
                            child: _field(
                              _code,
                              maxLength: 3,
                              display: true,
                              formatters: [
                                FilteringTextInputFormatter.allow(RegExp('[A-Za-z]')),
                                _UpperCase(),
                              ],
                              onChanged: (_) => setState(() => _codeTouched = true),
                            ),
                          ),
                          Text(
                            '3 letters, shown on the score bar.',
                            style: TikiText.body(size: 12, color: TikiPalette.slate),
                          ),
                          const SizedBox(height: 24),
                          Opacity(
                            opacity: _valid ? 1 : 0.4,
                            child: PrimaryButton(label: 'SAVE CLUB', onTap: _save),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 28),
                  Expanded(child: _preview(code)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController c, {
    required int maxLength,
    required ValueChanged<String> onChanged,
    List<TextInputFormatter>? formatters,
    bool display = false,
    String? hint,
  }) {
    return TextField(
      controller: c,
      maxLength: maxLength,
      onChanged: onChanged,
      inputFormatters: formatters,
      cursorColor: TikiPalette.cyan,
      style: display
          ? TikiText.display(size: 24, weight: 900, letterSpacing: 3)
          : TikiText.display(size: 20, weight: 700),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TikiText.body(size: 16, color: const Color(0xFF52665C)),
        counterText: '',
        filled: true,
        fillColor: const Color(0xFF0F1A15),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: TikiPalette.frameBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: TikiPalette.cyan, width: 1.5),
        ),
      ),
    );
  }

  Widget _preview(String code) {
    return Container(
      decoration: BoxDecoration(
        color: TikiPalette.frame,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFF1E2E26)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ClubBadge(code: code.isEmpty ? '?' : code, size: 110),
          const SizedBox(height: 16),
          Text(
            _name.text.trim().isEmpty ? 'Team name' : _name.text.trim(),
            style: TikiText.display(size: 28, weight: 900),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: TikiPalette.panel,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: TikiPalette.panelBorder),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(code.padRight(3, '·'), style: TikiText.display(size: 14, weight: 800)),
                const SizedBox(width: 12),
                Text('2 – 1', style: TikiText.display(size: 18, weight: 900)),
                const SizedBox(width: 12),
                Text(
                  'HRV',
                  style: TikiText.display(size: 14, weight: 800, color: TikiPalette.amber),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _UpperCase extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) =>
      newValue.copyWith(text: newValue.text.toUpperCase());
}
