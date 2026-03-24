import 'package:flutter/material.dart';
import 'package:ivox/shared/walkthrough/app_walkthrough_controller.dart';

class MascotWalkthroughOverlay extends StatelessWidget {
  final WalkthroughPage page;
  final Map<String, GlobalKey> targets;
  final ValueChanged<int> onTabSelected;

  const MascotWalkthroughOverlay({
    super.key,
    required this.page,
    required this.targets,
    required this.onTabSelected,
  });

  Rect? _targetRect(GlobalKey key) {
    final context = key.currentContext;
    if (context == null) return null;

    final render = context.findRenderObject();
    if (render is! RenderBox || !render.hasSize) return null;

    final offset = render.localToGlobal(Offset.zero);
    return offset & render.size;
  }

  void _goNext(BuildContext context) {
    final controller = AppWalkthroughController.instance;
    final next = controller.nextStep;
    if (next != null && next.page != page) {
      onTabSelected(AppWalkthroughController.tabIndexFromPage(next.page));
    }
    controller.next();

    if (!controller.isActive) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tutoriel termine')),
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
        if (step == null || step.page != page) {
          return const SizedBox.shrink();
        }

        final key = targets[step.targetId];
        final rect = key == null ? null : _targetRect(key);

        return Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => _goNext(context),
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
                  bottom: 24,
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
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.asset(
                              step.mascotAsset,
                              width: 56,
                              height: 56,
                              fit: BoxFit.cover,
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
                                const SizedBox(height: 4),
                                Text(
                                  step.description,
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Touchez l\'ecran pour continuer',
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
    final dimPath = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    if (rect != null) {
      final hole = RRect.fromRectAndRadius(
        rect!.inflate(8),
        const Radius.circular(14),
      );
      dimPath.addRRect(hole);
    }
    dimPath.fillType = PathFillType.evenOdd;

    canvas.drawPath(dimPath, Paint()..color = Colors.black54);

    if (rect != null) {
      final borderRect = RRect.fromRectAndRadius(
        rect!.inflate(8),
        const Radius.circular(14),
      );
      canvas.drawRRect(
        borderRect,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SpotlightPainter oldDelegate) {
    return oldDelegate.rect != rect;
  }
}
