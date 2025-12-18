import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:flutter/physics.dart';

class CurvedListView extends StatefulWidget {
  const CurvedListView({super.key});

  @override
  State<CurvedListView> createState() => _CurvedListViewState();
}

class _CurvedListViewState extends State<CurvedListView>
    with SingleTickerProviderStateMixin {
  final int totalItems = 15;
  final int visibleItems = 5;
  double _dragOffset = 0.0;
  double _velocity = 0.0;
  late AnimationController _controller;

  final List<MaterialColor> colors = [
    Colors.purple,
    Colors.blue,
    Colors.cyan,
    Colors.teal,
    Colors.pink,
    Colors.orange,
    Colors.deepOrange,
    Colors.amber,
  ];

  @override
  void initState() {
    super.initState();
    _dragOffset = 0.0;
    _controller = AnimationController.unbounded(vsync: this);
    _controller.addListener(() {
      setState(() {
        _dragOffset = _controller.value;
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _startMomentumScroll() {
    if (_velocity.abs() < 0.01) {
      _snapToNearestItem();
      return;
    }

    final simulation = FrictionSimulation(
      0.05,
      _dragOffset,
      _velocity,
    );

    _controller.animateWith(simulation).then((_) {
      _snapToNearestItem();
    });
  }

  void _snapToNearestItem() {
    double itemOffset = 1.0 / totalItems;
    double normalizedOffset = _dragOffset % 1.0;
    if (normalizedOffset < 0) normalizedOffset += 1.0;

    double currentPosition = normalizedOffset % itemOffset;
    double targetOffset;

    if (currentPosition < itemOffset / 2) {
      targetOffset = _dragOffset - currentPosition;
    } else {
      targetOffset = _dragOffset + (itemOffset - currentPosition);
    }

    _controller.animateTo(
      targetOffset,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  Offset _calculateCurvePosition(int index, Size screenSize, double offset) {
    double itemStep = 1.0 / totalItems;
    double itemBasePosition = index * itemStep;
    double itemProgress = itemBasePosition - (offset % 1.0);

    if (itemProgress > 0.5) {
      itemProgress -= 1.0;
    } else if (itemProgress < -0.5) {
      itemProgress += 1.0;
    }

    final visibleRange = visibleItems * itemStep;
    final visibleStart = -visibleRange;

    if (itemProgress < visibleStart || itemProgress > 0.05) {
      return const Offset(-1000, -1000);
    }

    double visibleProgress = (itemProgress - visibleStart) / (-visibleStart);

    // Enhanced S-curve with extreme curve on top
    double t = visibleProgress;

    // Create a dramatic curve at the top (start of the path)
    // When t is close to 0 (top), we want maximum horizontal displacement
    double topCurveStrength = math.pow(1 - t, 5.0).toDouble();
    double baseCurve = (math.sin((t - 0.5) * math.pi) + 1) / 2;

    // Add extra curvature using a custom easing function
    double extraCurve = math.pow(1 - t, 2.0) * 0.2;
    double smoothT = baseCurve + topCurveStrength * 0.5 + extraCurve;
    smoothT = smoothT.clamp(0.0, 2.0);

    // Path coordinates - start far right, curve to left
    double startX = screenSize.width * 0.4;
    double endX = screenSize.width * 0.1;
    double startY = screenSize.height * 0.2;
    double endY = screenSize.height * 0.85;

    double x = startX + (endX - startX) * smoothT;
    double y = startY + (endY - startY) * t;

    return Offset(x, y);
  }

  Color _getItemColor(int index, double offset) {
    double itemStep = 1.0 / totalItems;
    double itemBasePosition = index * itemStep;
    double itemProgress = itemBasePosition - (offset % 1.0);

    if (itemProgress > 0.5) itemProgress -= 1.0;
    if (itemProgress < -0.5) itemProgress += 1.0;

    final bottomThreshold = itemStep * 0.5;

    if (itemProgress.abs() < bottomThreshold) {
      return colors[index % colors.length];
    } else {
      return Colors.grey;
    }
  }

  double _getItemOpacity(int index, double offset) {
    double itemStep = 1.0 / totalItems;
    double itemBasePosition = index * itemStep;
    double itemProgress = itemBasePosition - (offset % 1.0);

    if (itemProgress > 0.5) itemProgress -= 1.0;
    if (itemProgress < -0.5) itemProgress += 1.0;

    final visibleRange = visibleItems * itemStep;
    final visibleStart = -visibleRange;

    if (itemProgress < visibleStart || itemProgress > 0.05) return 0.0;

    double opacity = 1.0 - (itemProgress.abs() / (-visibleStart));
    return opacity.clamp(0.0, 1.0);
  }

  double _getItemScale(int index, double offset) {
    double itemStep = 1.0 / totalItems;
    double itemBasePosition = index * itemStep;
    double itemProgress = itemBasePosition - (offset % 1.0);

    if (itemProgress > 0.5) itemProgress -= 1.0;
    if (itemProgress < -0.5) itemProgress += 1.0;

    final visibleRange = visibleItems * itemStep;
    final visibleStart = -visibleRange;

    if (itemProgress < visibleStart || itemProgress > 0.05) return 0.4;

    // Calculate scale based on position along the curve
    // Items at the bottom (itemProgress closer to 0) will be larger
    // Items at the top (itemProgress closer to visibleStart) will be smaller
    double normalizedProgress = (itemProgress - visibleStart) / (-visibleStart);

    // Use a smooth easing function for size transition
    // When normalizedProgress = 0 (top), scale = minScale (0.4)
    // When normalizedProgress = 1 (bottom), scale = maxScale (1.0)
    double minScale = 0.4;
    double maxScale = 1.0;
    double scale = minScale + (maxScale - minScale) * math.pow(normalizedProgress, 1.5);

    return scale.clamp(minScale, maxScale);
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Stack(
      children: [

        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onVerticalDragStart: (details) {
            _controller.stop();
            _velocity = 0;
          },
          onVerticalDragUpdate: (details) {
            setState(() {
              double sensitivity = 800;
              _dragOffset -= details.delta.dy / sensitivity;
              _velocity = -details.delta.dy / sensitivity;
            });
          },
          onVerticalDragEnd: (details) {
            _velocity = -details.primaryVelocity! / 800;
            _startMomentumScroll();
          },
          child: SizedBox(
            width: screenSize.width,
            height: screenSize.height,
            child: Stack(
              clipBehavior: Clip.none,
              children: List.generate(totalItems, (index) {
                Offset pos = _calculateCurvePosition(index, screenSize, _dragOffset);

                if (pos.dx < -400) return const SizedBox.shrink();

                final MaterialColor colorSet = colors[index % colors.length];
                final itemColor = _getItemColor(index, _dragOffset);
                final bool isColorful = itemColor != Colors.grey;
                final scale = _getItemScale(index, _dragOffset);
                final opacity = _getItemOpacity(index, _dragOffset);

                // Calculate dynamic size based on scale
                final baseSize = 120.0;
                final dynamicSize = baseSize * scale;

                return Transform.translate(
                  offset: Offset(pos.dx - dynamicSize / 2, pos.dy - dynamicSize / 2),
                  child: Opacity(
                    opacity: opacity,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _getIcon(index),
                          color: isColorful ? colorSet.shade300 : Colors.grey.shade200,
                          size: (isColorful ? 90 : 80) * scale,
                        ),
                        SizedBox(width: 8 * scale),
                        Text(
                          'Item ${index + 1}',
                          style: TextStyle(
                            color: isColorful ? Colors.white : Colors.grey.shade200,
                            fontSize: (isColorful ? 28 : 24) * scale,
                            fontWeight:
                            isColorful ? FontWeight.bold : FontWeight.normal,
                            shadows: isColorful
                                ? [
                              Shadow(
                                color: Colors.black.withValues(alpha: 0.5),
                                blurRadius: 4 * scale,
                              ),
                            ]
                                : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ],
    );
  }

  IconData _getIcon(int index) {
    List<IconData> icons = [
      Icons.star,
      Icons.favorite,
      Icons.flash_on,
      Icons.wb_sunny,
      Icons.nightlight,
      Icons.cloud,
      Icons.water_drop,
      Icons.local_fire_department,
      Icons.ac_unit,
      Icons.eco,
    ];
    return icons[index % icons.length];
  }
}