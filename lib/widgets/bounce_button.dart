import 'package:flutter/material.dart';

class BounceButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double scaleBy;
  final double translateY;

  const BounceButton({
    super.key,
    required this.child,
    this.onTap,
    this.scaleBy = 1.35, // Increased as requested
    this.translateY = -12.0, // Rising up effect
  });

  @override
  State<BounceButton> createState() => _BounceButtonState();
}

class _BounceButtonState extends State<BounceButton> with SingleTickerProviderStateMixin {
  AnimationController? _controller;
  Animation<double>? _scale;
  Animation<double>? _translation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    
    _scale = Tween<double>(begin: 1.0, end: widget.scaleBy).animate(
      CurvedAnimation(parent: _controller!, curve: Curves.easeOutBack),
    );
    
    _translation = Tween<double>(begin: 0.0, end: widget.translateY).animate(
      CurvedAnimation(parent: _controller!, curve: Curves.easeOutBack),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (widget.onTap != null) {
      _controller?.forward();
    }
  }

  void _onTapUp(TapUpDetails details) {
    if (widget.onTap != null) {
      _controller?.reverse();
    }
  }

  void _onTapCancel() {
    if (widget.onTap != null) {
      _controller?.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    final scale = _scale;
    final translation = _translation;

    if (controller == null || scale == null || translation == null) {
      return widget.child;
    }

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, translation.value),
            child: Transform.scale(
              scale: scale.value,
              child: child,
            ),
          );
        },
        child: widget.child,
      ),
    );
  }
}
