import 'package:flutter/material.dart';

import '../config/theme.dart';

const pixelTitleFont = 'PressStart2P';
const pixelBodyFont = 'VT323';

/// Flat ink box with a paper border and a hard black drop shadow.
class PixelPanel extends StatelessWidget {
  const PixelPanel({
    super.key,
    required this.child,
    this.fill = AppColors.ink,
    this.borderColor = AppColors.paper,
    this.padding = const EdgeInsets.all(12),
  });
  final Widget child;
  final Color fill;
  final Color borderColor;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      color: fill,
      border: Border.all(color: borderColor, width: 3),
      boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(3, 3))],
    ),
    child: child,
  );
}

class PixelButton extends StatefulWidget {
  const PixelButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.busy = false,
  });
  final String label;
  final VoidCallback? onPressed;
  final bool busy; // shows a spinner; caller disables onPressed

  @override
  State<PixelButton> createState() => _PixelButtonState();
}

class _PixelButtonState extends State<PixelButton> {
  bool _down = false;

  void _set(bool v) {
    if (_down != v) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.label,
      onTap: enabled ? widget.onPressed : null,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: enabled ? (_) => _set(true) : null,
        onTapUp: enabled ? (_) => _set(false) : null,
        onTapCancel: enabled ? () => _set(false) : null,
        onTap: widget.onPressed,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          child: Transform.translate(
            offset: Offset(0, _down ? 2 : 0),
            child: PixelPanel(
              fill: _down ? AppColors.primaryDeep : AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Center(
                widthFactor: 1,
                heightFactor: 1,
                child: widget.busy
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          color: AppColors.paper,
                        ),
                      )
                    : Text(
                        widget.label,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: pixelTitleFont,
                          fontSize: 12,
                          color: AppColors.paper,
                        ),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class PixelDialog extends StatelessWidget {
  const PixelDialog({
    super.key,
    required this.title,
    required this.body,
    this.content,
    this.actions = const [],
  });
  final String title;
  final String body;
  final Widget? content; // extra content under the body, e.g. a field
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) => Dialog(
    backgroundColor: Colors.transparent,
    elevation: 0,
    child: PixelPanel(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontFamily: pixelTitleFont,
              fontSize: 14,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 12),
          if (body.isNotEmpty) Text(body, style: const TextStyle(fontSize: 22)),
          ?content,
          if (actions.isNotEmpty) ...[
            const SizedBox(height: 16),
            Wrap(spacing: 12, runSpacing: 12, children: actions),
          ],
        ],
      ),
    ),
  );
}
