import 'package:flutter/material.dart';

class SwitchesTransition extends StatefulWidget {
  final Animation<double> animation;
  final Offset offset;
  final Widget child;

  const SwitchesTransition({
    super.key,
    required this.animation,
    required this.offset,
    required this.child,
  });

  @override
  State<SwitchesTransition> createState() => _SwitchesTransitionState();
}

class _SwitchesTransitionState extends State<SwitchesTransition>
    with SingleTickerProviderStateMixin {
  late final AnimationController animController;
  late final CurvedAnimation curvedAnimation;

  @override
  void initState() {
    super.initState();
    animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 233),
    );

    curvedAnimation =
        CurvedAnimation(parent: animController, curve: Curves.easeOut);
  }

  void didChangeWidget(SwitchesTransition oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animation.value == 1.0) {
      animController.forward();
    } else {
      animController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: widget.offset * curvedAnimation.value,
      child: widget.child,
    );
  }
}
