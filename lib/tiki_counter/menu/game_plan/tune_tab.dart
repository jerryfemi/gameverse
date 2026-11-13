import 'package:flutter/material.dart';

import 'package:b_ball/tiki_counter/menu/board/board_caption.dart';
import 'package:b_ball/tiki_counter/menu/board/board_paint.dart';
import 'package:b_ball/tiki_counter/menu/board/preview_board.dart';
import 'package:b_ball/tiki_counter/menu/game_plan/plan_panel.dart';
import 'package:b_ball/tiki_counter/menu/setup/tiki_setup.dart';
import 'package:b_ball/tiki_counter/menu/widgets/menu_header.dart';
import 'package:b_ball/tiki_counter/menu/widgets/text_tabs.dart';
import 'package:b_ball/tiki_counter/theme/tiki_palette.dart';
import 'package:b_ball/tiki_counter/ui/tiki_text.dart';
import 'package:tiki_core/preview/plan_preview.dart';
import 'package:tiki_core/preview/plan_words.dart';
import 'package:tiki_core/tactics/team_plan.dart';

/// Mix your own playstyle: one choice per moment of play, plus four
/// sliders. Any change makes the playstyle "Custom". The board shows the
/// moment you last touched.
class TuneTab extends StatefulWidget {
  final TikiSetup setup;
  final ValueChanged<TikiSetup> onChanged;

  const TuneTab({super.key, required this.setup, required this.onChanged});

  @override
  State<TuneTab> createState() => _TuneTabState();
}

class _TuneTabState extends State<TuneTab> {
  PreviewMoment _moment = PreviewMoment.defending;
  PreviewScene? _scene;
  String _sceneKey = '';

  TeamPlan get _plan => widget.setup.plan;

  void _set(TeamPlan p, PreviewMoment shows) {
    setState(() => _moment = shows);
    widget.onChanged(widget.setup.copyWith(plan: p.copyWith(name: 'Custom')));
  }

  PreviewScene _sceneFor(TikiSetup s) {
    final key = '${s.mode.name}|${s.formation.name}|${s.plan.toJson()}|${_moment.name}';
    if (key != _sceneKey || _scene == null) {
      _sceneKey = key;
      _scene = PlanPreview.build(
        mode: s.mode,
        formation: s.formation,
        plan: s.plan,
        moment: _moment,
      );
    }
    return _scene!;
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.setup;
    final p = _plan;
    final scene = _sceneFor(s);
    final aspect = (s.mode.length + BoardGeometry.margin * 2) /
        (s.mode.width + BoardGeometry.margin * 2);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          width: 360,
          child: PlanPanel(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _row<AttackStyle>(
                    PreviewMoment.attacking,
                    AttackStyle.values,
                    p.attack,
                    PlanWords.attack,
                    (v) => p.copyWith(attack: v),
                  ),
                  _row<Marking>(
                    PreviewMoment.defending,
                    Marking.values,
                    p.marking,
                    PlanWords.marking,
                    (v) => p.copyWith(marking: v),
                  ),
                  _row<AfterWin>(
                    PreviewMoment.gainingPossession,
                    AfterWin.values,
                    p.afterWin,
                    PlanWords.afterWin,
                    (v) => p.copyWith(afterWin: v),
                  ),
                  _row<AfterLoss>(
                    PreviewMoment.losingPossession,
                    AfterLoss.values,
                    p.afterLoss,
                    PlanWords.afterLoss,
                    (v) => p.copyWith(afterLoss: v),
                  ),
                  const SizedBox(height: 6),
                  _slider('Line height', PlanWords.line(p.lineHeight), p.lineHeight,
                      (v) => _set(p.copyWith(lineHeight: v), PreviewMoment.defending)),
                  _slider('Compactness', _pct(p.compactness), p.compactness,
                      (v) => _set(p.copyWith(compactness: v), PreviewMoment.defending)),
                  _slider('Width', _pct(p.width), p.width,
                      (v) => _set(p.copyWith(width: v), PreviewMoment.attacking)),
                  _slider('Press intensity', _pct(p.pressIntensity), p.pressIntensity,
                      (v) => _set(p.copyWith(pressIntensity: v), PreviewMoment.defending)),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 18),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '${_moment.label} · ${PlanWords.headline(p, _moment)}',
                style: TikiText.display(size: 16, weight: 800),
              ),
              const SizedBox(height: 6),
              BoardCaption(scene.caption),
              const SizedBox(height: 8),
              Expanded(
                child: BoardBox(
                  aspect: aspect,
                  child: PreviewBoard(scene: scene),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _pct(double v) => '${(v * 100).round()}';

  Widget _row<T>(
    PreviewMoment m,
    List<T> options,
    T selected,
    String Function(T) name,
    TeamPlan Function(T) change,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => setState(() => _moment = m),
            child: SectionLabel(m.label),
          ),
          TextTabs<T>(
            options: options,
            selected: selected,
            label: name,
            onChanged: (v) => _set(change(v), m),
          ),
        ],
      ),
    );
  }

  Widget _slider(String label, String value, double v, ValueChanged<double> onEnd) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(label, style: TikiText.body(size: 14, weight: 700, color: Colors.white)),
              const Spacer(),
              Text(value, style: TikiText.body(size: 13, color: TikiPalette.slate)),
            ],
          ),
          _TuneSlider(value: v, onChangeEnd: onEnd),
        ],
      ),
    );
  }
}

/// A slider that moves freely while dragging and only reports when let go,
/// so the board isn't rebuilt on every pixel.
class _TuneSlider extends StatefulWidget {
  final double value;
  final ValueChanged<double> onChangeEnd;

  const _TuneSlider({required this.value, required this.onChangeEnd});

  @override
  State<_TuneSlider> createState() => _TuneSliderState();
}

class _TuneSliderState extends State<_TuneSlider> {
  double? _drag;

  @override
  Widget build(BuildContext context) {
    return SliderTheme(
      data: SliderTheme.of(context).copyWith(
        activeTrackColor: TikiPalette.cyan,
        inactiveTrackColor: const Color(0xFF1E2E26),
        thumbColor: Colors.white,
        overlayColor: TikiPalette.cyanGlow,
        trackHeight: 4,
      ),
      child: Slider(
        value: _drag ?? widget.value,
        onChanged: (v) => setState(() => _drag = v),
        onChangeEnd: (v) {
          setState(() => _drag = null);
          widget.onChangeEnd(v);
        },
      ),
    );
  }
}
