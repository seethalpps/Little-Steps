import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math' as math;
// Ensure this path matches your project structure
import 'package:psychologist_app/login.dart';

class Landingpage extends StatefulWidget {
  const Landingpage({super.key});

  @override
  State<Landingpage> createState() => _LandingpageState();
}

class _LandingpageState extends State<Landingpage>
    with TickerProviderStateMixin {
  final Color primaryPurple = const Color(0xFF673AB7);
  late AnimationController _floatingController;
  late AnimationController _footstepController;

  @override
  void initState() {
    super.initState();

    // Background floating bubbles controller
    _floatingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    // Footsteps "walking" controller (5 seconds for a slow, gentle walk)
    _footstepController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..forward();

    // Navigation to Login page after 6.5 seconds (giving time for footprints)
    Timer(const Duration(seconds: 7), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const Login(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  return FadeTransition(opacity: animation, child: child);
                },
            transitionDuration: const Duration(milliseconds: 1000),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _floatingController.dispose();
    _footstepController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // 1. Background Floating Elements (Bubbles)
          ...List.generate(5, (index) => _buildFloatingBubble(index)),

          // 2. DIAGONAL WALKING ANIMATION (Bottom-Left to Top-Right)
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _footstepController,
              builder: (context, child) {
                return CustomPaint(
                  painter: DiagonalFootprintPainter(
                    progress: _footstepController.value,
                    color: primaryPurple,
                  ),
                );
              },
            ),
          ),

          // 3. Main Logo and Title Content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo with Heartbeat Pulse
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 1500),
                  curve: Curves.elasticOut,
                  builder: (context, value, child) {
                    return Transform.scale(
                      scale: value,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Pulse size must match logo size
                          _PulseRing(primaryPurple: primaryPurple, size: 200),
                          child!,
                        ],
                      ),
                    );
                  },
                  child: Container(
                    // INCREASED LOGO SIZE
                    width: 300,
                    height: 300,
                    padding: const EdgeInsets.all(35),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 50,
                          offset: Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Image.asset('assets/logo.png'),
                  ),
                ),
                const SizedBox(height: 40),
                // Shimmering Title
                _buildShimmerTitle(),
                const SizedBox(height: 10),
                // Fading Subtitle
                _buildFadeSubtitle(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- UI HELPER WIDGETS ---

  Widget _buildShimmerTitle() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 1200),
      curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
      builder: (context, value, child) {
        return ShaderMask(
          shaderCallback: (rect) => LinearGradient(
            colors: [primaryPurple, Colors.purpleAccent, primaryPurple],
            stops: [value - 0.2, value, value + 0.2],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(rect),
          child: const Text(
            "Little Steps",
            style: TextStyle(
              fontSize: 44, // Slightly larger font for larger logo
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 2,
            ),
          ),
        );
      },
    );
  }

  Widget _buildFadeSubtitle() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 1000),
      curve: const Interval(0.8, 1.0, curve: Curves.easeIn),
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: const Text(
          "Your child's health, our priority.",
          style: TextStyle(
            fontSize: 18,
            color: Colors.black45,
            fontStyle: FontStyle.italic,
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingBubble(int index) {
    return AnimatedBuilder(
      animation: _floatingController,
      builder: (context, child) {
        double speed = (index + 1) * 0.2;
        double xOffset =
            math.sin(_floatingController.value * 2 * math.pi * speed) * 20;
        double yOffset =
            math.cos(_floatingController.value * 2 * math.pi * speed) * 30;
        return Positioned(
          left: (index * 80.0) + 20 + xOffset,
          top: (index * 150.0) + 100 + yOffset,
          child: Opacity(
            opacity: 0.05,
            child: Container(
              width: 50.0 + (index * 10),
              height: 50.0 + (index * 10),
              decoration: BoxDecoration(
                color: primaryPurple,
                shape: BoxShape.circle,
              ),
            ),
          ),
        );
      },
    );
  }
}

// --- CUSTOM PAINTER FOR DIAGONAL WALKING FOOTPRINTS ---

class DiagonalFootprintPainter extends CustomPainter {
  final double progress;
  final Color color;

  DiagonalFootprintPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    const int totalSteps = 12;

    for (int i = 0; i < totalSteps; i++) {
      double stepTrigger = i / totalSteps;

      if (progress > stepTrigger) {
        // Steps have very low opacity to be subtle background elements
        double opacity = (0.25 - (progress - stepTrigger) * 0.15).clamp(
          0.05,
          0.25,
        );
        final paint = Paint()..color = color.withOpacity(opacity);

        // Path logic: Bottom-Left (0, height) to Top-Right (width, 0)
        double t = i / (totalSteps - 1);
        double x = size.width * t;
        double y = size.height - (size.height * t);

        // Human-like walking offset (left and right feet)
        double sideOffset = (i % 2 == 0) ? -25.0 : 25.0;

        canvas.save();
        canvas.translate(x + sideOffset, y);
        // Rotate footprints to align with the diagonal path
        canvas.rotate(-math.pi / 4);
        canvas.rotate((i % 2 == 0) ? -0.15 : 0.15);

        // Draw the Footprint
        canvas.drawOval(Rect.fromLTWH(0, 0, 14, 22), paint); // Main sole
        canvas.drawOval(Rect.fromLTWH(3, 24, 8, 8), paint); // Heel
        for (int j = 0; j < 4; j++) {
          canvas.drawCircle(Offset(j * 3.5 + 1, -5), 2.2, paint); // Toes
        }
        canvas.restore();
      }
    }
  }

  @override
  bool shouldRepaint(DiagonalFootprintPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

// --- PULSE RING ANIMATION ---

class _PulseRing extends StatefulWidget {
  final Color primaryPurple;
  final double size; // Added size parameter
  const _PulseRing({required this.primaryPurple, required this.size});
  @override
  State<_PulseRing> createState() => _PulseRingState();
}

class _PulseRingState extends State<_PulseRing>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
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
      builder: (context, child) => Container(
        // Base width starts at the logo size
        width: widget.size + (_controller.value * 80),
        height: widget.size + (_controller.value * 80),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: widget.primaryPurple.withOpacity(1 - _controller.value),
            width: 2,
          ),
        ),
      ),
    );
  }
}
