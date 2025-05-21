class TypeWriterTextAnimation extends StatefulWidget {
  final List<String> texts;
  final Duration duration;
  final Duration waitDuration;
  final TextStyle? textStyle;
  final int startFrom;

  const TypeWriterTextAnimation({
    super.key,
    this.startFrom = 23,
    this.duration = const Duration(seconds: 1),
    this.waitDuration = const Duration(seconds: 1),
    required this.texts,
    this.textStyle,
  });

  @override
  State<TypeWriterTextAnimation> createState() => _TypeWriterTextAnimationState();
}

class _TypeWriterTextAnimationState extends State<TypeWriterTextAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<int> _animation;
  int currentTextIndex = 0;

  @override
  void initState() {
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    animate();
    super.initState();
  }


  Future<void> animate() async {
    _animation = StepTween(begin: widget.startFrom, end: widget.texts[currentTextIndex].length)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    await _controller.forward();
    await Future.delayed(widget.waitDuration);
    await _controller.reverse();
    currentTextIndex =
        currentTextIndex < widget.texts.length - 1 ? currentTextIndex + 1 : 0;
    animate();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) => Text(
        widget.texts[currentTextIndex].substring(0, _animation.value),
        style: widget.textStyle,
      ),
    );
  }
}