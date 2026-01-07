import 'package:flutter/material.dart';

class DraggableFloatingActionButton extends StatefulWidget {
  final VoidCallback onPressed;
  final Widget child;
  final Color? backgroundColor;
  final String? heroTag;
  final Offset? initialOffset;

  const DraggableFloatingActionButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.backgroundColor,
    this.heroTag,
    this.initialOffset,
  });

  @override
  State<DraggableFloatingActionButton> createState() =>
      _DraggableFloatingActionButtonState();
}

class _DraggableFloatingActionButtonState
    extends State<DraggableFloatingActionButton> {
  Offset _position = const Offset(20, 20); // Fallback
  bool _isInit = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInit) {
      final size = MediaQuery.of(context).size;
      // Default to bottom-right, roughly where a FAB would be.
      // Adjusting for common SafeArea/AppBar heights if this is inside a body.
      // We'll place it at Bottom-Right with some padding.
      // Assuming parent Stack covers available space.
      if (widget.initialOffset != null) {
        _position = widget.initialOffset!;
      } else {
        _position = Offset(size.width - 72, size.height - 100);
      }
      _isInit = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: _position.dx,
      top: _position.dy,
      child: GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            _position += details.delta;
          });
        },
        child: FloatingActionButton(
          heroTag: widget.heroTag,
          onPressed: widget.onPressed,
          backgroundColor: widget.backgroundColor,
          elevation: 6,
          child: widget.child,
        ),
      ),
    );
  }
}
