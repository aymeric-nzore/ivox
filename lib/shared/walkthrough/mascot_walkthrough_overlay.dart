import 'package:flutter/material.dart';
import 'package:ivox/shared/walkthrough/app_walkthrough_controller.dart';
import 'dart:async';

class MascotWalkthroughOverlay extends StatefulWidget {
  final WalkthroughPage page;
  final Map<String, GlobalKey> targets;
  final ValueChanged<int> onTabSelected;
  final Future<void> Function(BuildContext, WalkthroughStep)? onBeforeNext;

  const MascotWalkthroughOverlay({
    super.key,
    required this.page,
    required this.targets,
    required this.onTabSelected,
    this.onBeforeNext,
  });

  @override
  State<MascotWalkthroughOverlay> createState() => _MascotWalkthroughOverlayState();
}

class _MascotWalkthroughOverlayState extends State<MascotWalkthroughOverlay> {
  Timer? _repaintTicker;

  @override
  void initState() {
    super.initState();
    _repaintTicker = Timer.periodic(const Duration(milliseconds: 180), (_) {
      if (!mounted) return;
      if (!AppWalkthroughController.instance.isActive) return;
      setState(() {});
    });
  }

  @override
  void dispose() {
    _repaintTicker?.cancel();
    super.dispose();
  }

  Rect? _targetRect(GlobalKey key, BuildContext overlayContext) {
    final targetContext = key.currentContext;
    if (targetContext == null) return null;

    final targetRender = targetContext.findRenderObject();
    final overlayRender = overlayContext.findRenderObject();
    if (targetRender is! RenderBox || overlayRender is! RenderBox) return null;
    if (!targetRender.hasSize || !overlayRender.hasSize) return null;

    final offset = targetRender.localToGlobal(
      Offset.zero,
      ancestor: overlayRender,
    );
    return offset & targetRender.size;
  }

  Future<void> _goNext(BuildContext context) async {
    final controller = AppWalkthroughController.instance;
    final current = controller.currentStep;
    if (current == null) return;

    if (widget.onBeforeNext != null) {
      await widget.onBeforeNext!(context, current);
    }

    final next = controller.nextStep;
    if (next != null &&
        next.page != widget.page &&
        AppWalkthroughController.isBottomTabPage(next.page)) {
      widget.onTabSelected(AppWalkthroughController.tabIndexFromPage(next.page));
    }
    controller.next();

    if (!controller.isActive) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tutoriel terminé')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = AppWalkthroughController.instance;

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final step = controller.currentStep;
        if (step == null || step.page != widget.page) {
          return const SizedBox.shrink();
        }

        return Positioned.fill(
          child: Builder(
            builder: (overlayContext) {
              final key = widget.targets[step.targetId];
              final rect = key == null ? null : _targetRect(key, overlayContext);
              final shouldPlaceDialogTop =
                  step.page == WalkthroughPage.profile &&
                  (step.targetId == 'profile_dictionary' ||
                      step.targetId == 'profile_shop');

              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  _goNext(context);
                },
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _SpotlightPainter(rect: rect),
                      ),
                    ),
                    Positioned(
                      left: 16,
                      right: 16,
                      top: shouldPlaceDialogTop ? 24 : null,
                      bottom: shouldPlaceDialogTop ? null : 24,
                      child: Material(
                        color: Colors.transparent,
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Theme.of(context).colorScheme.outline.withValues(
                                alpha: 0.2,
                              ),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(top: 20),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.asset(
                                    step.mascotAsset,
                                    width: 96,
                                    height: 96,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      step.title,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      step.description,
                                      style: TextStyle(
                                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    const Text(
                                      'Touchez l\'écran pour continuer',
                                      style: TextStyle(fontSize: 12),
                                    ),
                                    const SizedBox(height: 8),
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: TextButton(
                                        onPressed: controller.stop,
                                        child: const Text('Passer'),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _SpotlightPainter extends CustomPainter {
  final Rect? rect;

  const _SpotlightPainter({required this.rect});

  @override
  void paint(Canvas canvas, Size size) {
    Rect? effectiveRect = rect;
    if (effectiveRect != null) {
      final areaRatio =
          (effectiveRect.width * effectiveRect.height) / (size.width * size.height);
      final almostFullScreen =
          effectiveRect.width > size.width * 0.995 &&
          effectiveRect.height > size.height * 0.9;

      if (areaRatio > 0.92 || almostFullScreen) {
        effectiveRect = null;
      }
    }

    final dimPath = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    if (effectiveRect != null) {
      final hole = RRect.fromRectAndRadius(
        effectiveRect.inflate(8),
        const Radius.circular(14),
      );
      dimPath.addRRect(hole);
    }
    dimPath.fillType = PathFillType.evenOdd;

    canvas.drawPath(dimPath, Paint()..color = Colors.black.withValues(alpha: 0.64));

    if (effectiveRect != null) {
      final borderRect = RRect.fromRectAndRadius(
        effectiveRect.inflate(2),
        const Radius.circular(14),
      );
      canvas.drawRRect(
        borderRect,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.95)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SpotlightPainter oldDelegate) {
    return oldDelegate.rect != rect;
  }
}
