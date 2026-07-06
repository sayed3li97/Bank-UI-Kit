import 'package:flutter/material.dart';

/// A believable phone mockup used across the showcase to preview the
/// mobile-first banking screens at their true handset proportions.
///
/// The [child] is laid out at a fixed logical phone size (390 x 844) with its
/// [MediaQuery] overridden to that size, then the whole device is scaled to
/// fit the available space with [FittedBox]. This keeps every embedded screen
/// pixel-identical to how it renders on a real device, regardless of the
/// surrounding canvas.
class DeviceFrame extends StatelessWidget {
  const DeviceFrame({
    required this.child,
    super.key,
    this.showNotch = true,
    this.maxHeight = 900,
  });

  final Widget child;
  final bool showNotch;
  final double maxHeight;

  static const double _screenW = 390;
  static const double _screenH = 844;
  static const double _bezel = 14;
  static const double _outerRadius = 52;
  static const double _screenRadius = 40;

  @override
  Widget build(BuildContext context) {
    const outerW = _screenW + _bezel * 2;
    const outerH = _screenH + _bezel * 2;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: FittedBox(
          fit: BoxFit.contain,
          child: Padding(
            // Room so the drop shadow is not clipped by an ancestor.
            padding: const EdgeInsets.all(28),
            child: Container(
              width: outerW,
              height: outerH,
              decoration: BoxDecoration(
                color: const Color(0xFF0B0D12),
                borderRadius: BorderRadius.circular(_outerRadius),
                border: Border.all(color: const Color(0xFF23262E), width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.28),
                    blurRadius: 60,
                    spreadRadius: 4,
                    offset: const Offset(0, 32),
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.16),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(_bezel),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(_screenRadius),
                  child: SizedBox(
                    width: _screenW,
                    height: _screenH,
                    child: MediaQuery(
                      data: MediaQuery.of(context).copyWith(
                        size: const Size(_screenW, _screenH),
                        padding: EdgeInsets.zero,
                        viewPadding: EdgeInsets.zero,
                        viewInsets: EdgeInsets.zero,
                        devicePixelRatio: 3,
                      ),
                      child: Stack(
                        children: [
                          Positioned.fill(child: child),
                          if (showNotch)
                            Positioned(
                              top: 10,
                              left: 0,
                              right: 0,
                              child: Center(child: _DynamicIsland()),
                            ),
                        ],
                      ),
                    ),
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

class _DynamicIsland extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 112,
      height: 30,
      decoration: BoxDecoration(
        color: const Color(0xFF0B0D12),
        borderRadius: BorderRadius.circular(18),
      ),
    );
  }
}
