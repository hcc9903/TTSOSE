import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

// 蜂巢图案绘制器
class HoneycombPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFFB800).withOpacity(0.05)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    const double radius = 20;
    const double hexWidth = radius * math.sqrt(3);
    const double hexHeight = radius * 2;

    for (double y = 0; y < size.height + hexHeight; y += hexHeight * 0.75) {
      bool oddRow = ((y ~/ (hexHeight * 0.75)) % 2) == 1;
      double xOffset = oddRow ? hexWidth / 2 : 0;
      
      for (double x = -hexWidth; x < size.width + hexWidth; x += hexWidth) {
        _drawHexagon(canvas, x + xOffset, y, radius, paint);
      }
    }
  }

  void _drawHexagon(Canvas canvas, double x, double y, double radius, Paint paint) {
    final path = Path();
    for (int i = 0; i < 6; i++) {
      double angle = (60 * i - 30) * math.pi / 180;
      double px = x + radius * math.cos(angle);
      double py = y + radius * math.sin(angle);
      
      if (i == 0) {
        path.moveTo(px, py);
      } else {
        path.lineTo(px, py);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// 浮动光球
class FloatingSphere extends StatelessWidget {
  final Animation<double> animation;
  final double size;
  final Color color;
  final double top;
  final double right;
  final double bottom;
  final double left;

  const FloatingSphere({
    super.key,
    required this.animation,
    required this.size,
    required this.color,
    this.top = 0,
    this.right = 0,
    this.bottom = 0,
    this.left = 0,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Positioned(
          top: top > 0 ? top + animation.value * 30 : null,
          right: right > 0 ? right + animation.value * 30 : null,
          bottom: bottom > 0 ? bottom - animation.value * 30 : null,
          left: left > 0 ? left + animation.value * 30 : null,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  color.withOpacity(0.4),
                  color.withOpacity(0.2),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.3, 1.0],
              ),
            ),
          ),
        );
      },
    );
  }
}

// 动画背景组件
class AnimatedBackground extends StatefulWidget {
  final Widget child;

  const AnimatedBackground({super.key, required this.child});

  @override
  State<AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground>
    with TickerProviderStateMixin {
  late AnimationController _controller1;
  late AnimationController _controller2;
  late Animation<double> _animation1;
  late Animation<double> _animation2;

  @override
  void initState() {
    super.initState();
    
    _controller1 = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat(reverse: true);
    
    _controller2 = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    )..repeat(reverse: true);

    _animation1 = Tween<double>(begin: 0, end: 1).animate(_controller1);
    _animation2 = Tween<double>(begin: 0, end: 1).animate(_controller2);
  }

  @override
  void dispose() {
    _controller1.dispose();
    _controller2.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 径向渐变背景
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0, -0.3),
                radius: 0.8,
                colors: [
                  Color(0xFF1a1505),
                  Color(0xFF080808),
                ],
              ),
            ),
          ),
          
          // 蜂巢纹理
          CustomPaint(
            size: Size.infinite,
            painter: HoneycombPainter(),
          ),
          
          // 浮动光球1 - 右上角
          FloatingSphere(
            animation: _animation1,
            size: 400,
            color: const Color(0xFFFFB800),
            top: -100,
            right: -100,
          ),
          
          // 浮动光球2 - 左下角
          FloatingSphere(
            animation: _animation2,
            size: 300,
            color: const Color(0xFFFFB800).withOpacity(0.7),
            bottom: -50,
            left: -50,
          ),
          
          // 主内容
          widget.child,
        ],
      ),
    );
  }
}
