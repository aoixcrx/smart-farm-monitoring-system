import 'package:flutter/material.dart';

class ShimmerText extends StatefulWidget {
  final Widget child;
  final Duration duration;

  const ShimmerText({
    super.key,
    required this.child,
    this.duration = const Duration(seconds: 2), // Default duration 3s
  });

  @override
  State<ShimmerText> createState() => _ShimmerTextState();
}

class _ShimmerTextState extends State<ShimmerText>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              colors: const [
                Colors.white,
                Color(0xFFFFF176), // Light Yellow/Gold for shimmer
                Colors.white,
              ],
              stops: const [0.0, 0.5, 1.0],
              begin: Alignment(-1.0 + (_controller.value * 3), 0.0), // Move from left
              end: Alignment(0.0 + (_controller.value * 3), 1.0),   // To right
              tileMode: TileMode.clamp,
            ).createShader(bounds);
          },
          child: widget.child,
        );
      },
    );
  }
}
