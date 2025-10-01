import 'dart:math';
import 'package:flutter/material.dart';

class VoiceVisualization extends StatefulWidget {
  final bool isActive;
  final Color color;
  final int barCount;
  final double minHeight;
  final double maxHeight;

  const VoiceVisualization({
    super.key,
    required this.isActive,
    required this.color,
    this.barCount = 30,
    this.minHeight = 5.0,
    this.maxHeight = 60.0,
  });

  @override
  State<VoiceVisualization> createState() => _VoiceVisualizationState();
}

class _VoiceVisualizationState extends State<VoiceVisualization>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<double> _heights;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );

    _heights = List.generate(widget.barCount, (_) => _generateRandomHeight());

    if (widget.isActive) {
      _startAnimation();
    }
  }

  @override
  void didUpdateWidget(VoiceVisualization oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive != oldWidget.isActive) {
      if (widget.isActive) {
        _startAnimation();
      } else {
        _controller.stop();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _startAnimation() {
    _controller.repeat(reverse: true);
    _controller.addListener(() {
      if (mounted && widget.isActive) {
        setState(() {
          // Update a random subset of bars each animation frame
          for (int i = 0; i < widget.barCount ~/ 3; i++) {
            final index = _random.nextInt(widget.barCount);
            _heights[index] = _generateRandomHeight();
          }
        });
      }
    });
  }

  double _generateRandomHeight() {
    return widget.minHeight +
        _random.nextDouble() * (widget.maxHeight - widget.minHeight);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(
        widget.barCount,
        (index) => _buildBar(_heights[index]),
      ),
    );
  }

  Widget _buildBar(double height) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: 3,
      height: height,
      decoration: BoxDecoration(
        color: widget.isActive
            ? widget.color
            : widget.color.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(5),
      ),
    );
  }
}
