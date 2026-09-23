import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_colors.dart';
import 'home_shell.dart';

/// 로그인 직후, 시장으로 들어가기 전에 한 번 보여주는 도착 화면.
class LoginArrivalScreen extends StatefulWidget {
  const LoginArrivalScreen({super.key});

  @override
  State<LoginArrivalScreen> createState() => _LoginArrivalScreenState();
}

class _LoginArrivalScreenState extends State<LoginArrivalScreen>
    with TickerProviderStateMixin {
  late final AnimationController _intro;
  late final AnimationController _live;

  @override
  void initState() {
    super.initState();
    _intro = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1700),
    )..forward();
    _live = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat();
  }

  @override
  void dispose() {
    _intro.dispose();
    _live.dispose();
    super.dispose();
  }

  void _start() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomeShell()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF7EC8F0),
              Color(0xFFEAF7FF),
              Color(0xFFFFF8E8),
            ],
            stops: [0, 0.38, 1],
          ),
        ),
        child: Stack(
          children: [
            const Positioned.fill(child: _ConfettiField()),
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _live,
                builder: (context, _) {
                  final sway = math.sin(_live.value * math.pi * 2);
                  return Stack(
                    children: [
                      _lantern(0.1, 0.08, 34, sway),
                      _lantern(0.86, 0.04, 42, -sway),
                      _lantern(0.78, 0.2, 26, sway * 0.7),
                      _lantern(0.08, 0.24, 28, -sway * 0.8),
                    ],
                  );
                },
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 18, 24, 16),
                child: Column(
                  children: [
                    const Spacer(),
                    _CheckBurst(intro: _intro, live: _live),
                    const SizedBox(height: 14),
                    FadeTransition(
                      opacity: CurvedAnimation(
                        parent: _intro,
                        curve: const Interval(0.08, 0.4, curve: Curves.easeOut),
                      ),
                      child: const Text(
                        '로그인 완료',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: AppColors.deepBlue,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    FadeTransition(
                      opacity: CurvedAnimation(
                        parent: _intro,
                        curve: const Interval(0.12, 0.45, curve: Curves.easeOut),
                      ),
                      child: Text(
                        '시장을 찾으러',
                        style: GoogleFonts.jua(fontSize: 22, color: AppColors.navy),
                      ),
                    ),
                    _UnfoldTitle(intro: _intro, live: _live),
                    const SizedBox(height: 6),
                    _WaveText(animation: _live, intro: _intro),
                    const SizedBox(height: 16),
                    _PaintMap(intro: _intro),
                    const SizedBox(height: 12),
                    _StampRow(intro: _intro),
                    const Spacer(),
                    _GlowButton(live: _live, onPressed: _start),
                    const SizedBox(height: 10),
                    const Text(
                      '마감할인 · 스탬프 · 지도 색칠',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.deepBlue,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _lantern(double x, double y, double size, double sway) {
    return Align(
      alignment: Alignment(x * 2 - 1, y * 2 - 1),
      child: Transform.rotate(
        angle: sway * 0.16,
        alignment: Alignment.topCenter,
        child: CustomPaint(
          size: Size(size, size * 1.35),
          painter: const _LanternPainter(),
        ),
      ),
    );
  }
}

class _CheckBurst extends StatelessWidget {
  const _CheckBurst({required this.intro, required this.live});

  final Animation<double> intro;
  final Animation<double> live;

  @override
  Widget build(BuildContext context) {
    final pop = CurvedAnimation(
      parent: intro,
      curve: const Interval(0, 0.42, curve: Curves.elasticOut),
    );
    return SizedBox(
      width: 120,
      height: 120,
      child: AnimatedBuilder(
        animation: Listenable.merge([intro, live]),
        builder: (context, child) {
          return Stack(
            alignment: Alignment.center,
            children: [
              for (var i = 0; i < 3; i++)
                _ring((live.value + i / 3) % 1, intro.value),
              Transform.scale(scale: pop.value, child: child),
            ],
          );
        },
        child: Container(
          width: 84,
          height: 84,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF2EAF62),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2EAF62).withValues(alpha: 0.38),
                blurRadius: 22,
                spreadRadius: 1,
              ),
            ],
          ),
          child: const Icon(Icons.check_rounded, color: Colors.white, size: 48),
        ),
      ),
    );
  }

  Widget _ring(double t, double introValue) {
    final appear = ((introValue - 0.2) / 0.5).clamp(0.0, 1.0);
    return Opacity(
      opacity: (1 - t) * 0.55 * appear,
      child: Transform.scale(
        scale: 0.7 + t * 1.15,
        child: Container(
          width: 84,
          height: 84,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: const Color(0xFF2EAF62),
              width: 2.4,
            ),
          ),
        ),
      ),
    );
  }
}

class _UnfoldTitle extends StatelessWidget {
  const _UnfoldTitle({required this.intro, required this.live});

  final Animation<double> intro;
  final Animation<double> live;

  static const _text = 'Tradada GO!';

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([intro, live]),
      builder: (context, _) {
        final shine = live.value;
        return FittedBox(
          fit: BoxFit.scaleDown,
          child: ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment(-1.2 + shine * 2.4, 0),
              end: Alignment(-0.2 + shine * 2.4, 0),
              colors: const [
                AppColors.goldDeep,
                AppColors.gold,
                Color(0xFFFFF3C4),
                AppColors.gold,
                AppColors.goldDeep,
              ],
            ).createShader(bounds);
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < _text.length; i++)
                _letter(i),
            ],
          ),
        ),
        );
      },
    );
  }

  Widget _letter(int index) {
    final start = 0.18 + index * 0.035;
    final t = Interval(start, (start + 0.28).clamp(0, 1), curve: Curves.easeOutBack)
        .transform(intro.value.clamp(0, 1));
    return Transform(
      alignment: Alignment.bottomCenter,
      transform: Matrix4.identity()
        ..setEntry(3, 2, 0.004)
        ..rotateY((1 - t) * 1.15)
        ..scaleByDouble(t, t, 1, 1),
      child: Opacity(
        opacity: t.clamp(0, 1),
        child: Text(
          _text[index],
          style: GoogleFonts.jua(
            fontSize: 40,
            height: 1.05,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

class _WaveText extends StatelessWidget {
  const _WaveText({required this.animation, required this.intro});

  final Animation<double> animation;
  final Animation<double> intro;

  static const text = '시장도 여행처럼! 혜택은 보물처럼!';

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([animation, intro]),
      builder: (context, _) {
        final phase = animation.value * math.pi * 2;
        final shown = Interval(0.35, 0.7, curve: Curves.easeOut).transform(intro.value);
        return Opacity(
          opacity: shown,
          child: Wrap(
            alignment: WrapAlignment.center,
            children: [
              for (var i = 0; i < text.length; i++)
                Transform.translate(
                  offset: Offset(0, math.sin(phase + i * 0.36) * 2.6),
                  child: Text(
                    text[i],
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: _colorFor(i),
                      fontSize: 15,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Color _colorFor(int index) {
    const benefit = '혜택';
    final at = text.indexOf(benefit);
    if (index >= at && index < at + benefit.length) return AppColors.teal;
    return AppColors.navy;
  }
}

class _PaintMap extends StatelessWidget {
  const _PaintMap({required this.intro});

  final Animation<double> intro;

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: CurvedAnimation(
        parent: intro,
        curve: const Interval(0.4, 0.7, curve: Curves.easeOut),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          children: [
            const Row(
              children: [
                Icon(Icons.map_outlined, size: 18, color: AppColors.navy),
                SizedBox(width: 6),
                Text(
                  '내 시장 지도 색칠 중',
                  style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.navy),
                ),
              ],
            ),
            const SizedBox(height: 10),
            AnimatedBuilder(
              animation: intro,
              builder: (context, _) {
                final paint = Interval(0.48, 1, curve: Curves.easeOut).transform(intro.value);
                return Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  alignment: WrapAlignment.center,
                  children: [
                    for (var i = 0; i < 18; i++)
                      _tile(i, paint),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _tile(int index, double paint) {
    final start = index / 18;
    final filled = ((paint - start) / 0.12).clamp(0.0, 1.0);
    return Container(
      width: 22,
      height: 16,
      decoration: BoxDecoration(
        color: Color.lerp(const Color(0xFFE6EDF4), AppColors.gold, filled),
        borderRadius: BorderRadius.circular(4),
        boxShadow: filled > 0.8
            ? [
                BoxShadow(
                  color: AppColors.goldDeep.withValues(alpha: 0.35),
                  blurRadius: 4,
                ),
              ]
            : null,
      ),
    );
  }
}

class _StampRow extends StatelessWidget {
  const _StampRow({required this.intro});

  final Animation<double> intro;

  @override
  Widget build(BuildContext context) {
    const stamps = [
      (Icons.flag_rounded, '첫 방문'),
      (Icons.local_offer_rounded, '마감할인'),
      (Icons.explore_rounded, '탐험가'),
    ];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        for (var i = 0; i < stamps.length; i++)
          _badge(stamps[i].$1, stamps[i].$2, i),
      ],
    );
  }

  Widget _badge(IconData icon, String label, int index) {
    final start = 0.55 + index * 0.1;
    final curve = CurvedAnimation(
      parent: intro,
      curve: Interval(start, (start + 0.28).clamp(0, 1), curve: Curves.elasticOut),
    );
    return ScaleTransition(
      scale: curve,
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              border: Border.all(color: AppColors.goldDeep, width: 2),
              boxShadow: [
                BoxShadow(
                  color: AppColors.gold.withValues(alpha: 0.35),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(icon, color: AppColors.navy, size: 24),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: AppColors.navy,
            ),
          ),
        ],
      ),
    );
  }
}

class _GlowButton extends StatelessWidget {
  const _GlowButton({required this.live, required this.onPressed});

  final Animation<double> live;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: live,
      builder: (context, child) {
        final glow = 0.5 + 0.5 * math.sin(live.value * math.pi * 2);
        return DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.goldDeep.withValues(alpha: 0.28 + glow * 0.38),
                blurRadius: 10 + glow * 16,
                spreadRadius: glow * 1.4,
              ),
            ],
          ),
          child: child,
        );
      },
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: const LinearGradient(
                colors: [AppColors.gold, AppColors.goldDeep],
              ),
            ),
            child: const SizedBox(
              width: double.infinity,
              height: 52,
              child: Center(
                child: Text(
                  '시장 탐험 시작하기',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    color: AppColors.navy,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ConfettiField extends StatefulWidget {
  const _ConfettiField();

  @override
  State<_ConfettiField> createState() => _ConfettiFieldState();
}

class _ConfettiFieldState extends State<_ConfettiField>
    with SingleTickerProviderStateMixin {
  late final AnimationController _burst;
  late final List<_Bit> _bits;

  @override
  void initState() {
    super.initState();
    final random = math.Random(7);
    const colors = [
      AppColors.gold,
      AppColors.goldDeep,
      AppColors.sky,
      AppColors.navy,
      AppColors.teal,
      Colors.white,
    ];
    _bits = [
      for (var i = 0; i < 26; i++)
        _Bit(
          angle: random.nextDouble() * math.pi * 2,
          distance: 70 + random.nextDouble() * 150,
          spin: random.nextDouble() * 6,
          size: 6 + random.nextDouble() * 7,
          kind: random.nextInt(3),
          color: colors[random.nextInt(colors.length)],
          delay: random.nextDouble() * 0.2,
        ),
    ];
    _burst = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..forward();
  }

  @override
  void dispose() {
    _burst.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _burst,
        builder: (context, _) {
          return CustomPaint(
            size: Size.infinite,
            painter: _ConfettiPainter(bits: _bits, t: _burst.value),
          );
        },
      ),
    );
  }
}

class _Bit {
  const _Bit({
    required this.angle,
    required this.distance,
    required this.spin,
    required this.size,
    required this.kind,
    required this.color,
    required this.delay,
  });

  final double angle;
  final double distance;
  final double spin;
  final double size;
  final int kind;
  final Color color;
  final double delay;
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter({required this.bits, required this.t});

  final List<_Bit> bits;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final origin = Offset(size.width / 2, size.height * 0.34);
    for (final bit in bits) {
      final local = ((t - bit.delay) / (1 - bit.delay)).clamp(0.0, 1.0);
      if (local <= 0) continue;
      final travel = Curves.easeOutCubic.transform(local);
      final offset = Offset(
        math.cos(bit.angle) * bit.distance * travel,
        math.sin(bit.angle) * bit.distance * travel * 0.72 + local * 28,
      );
      final paint = Paint()..color = bit.color.withValues(alpha: (1 - local) * 0.9);
      canvas.save();
      canvas.translate(origin.dx + offset.dx, origin.dy + offset.dy);
      canvas.rotate(bit.spin * local);
      switch (bit.kind) {
        case 0:
          _star(canvas, bit.size, paint);
        case 1:
          canvas.drawCircle(Offset.zero, bit.size * 0.45, paint);
        default:
          canvas.drawRect(
            Rect.fromCenter(center: Offset.zero, width: bit.size, height: bit.size * 0.7),
            paint,
          );
      }
      canvas.restore();
    }
  }

  void _star(Canvas canvas, double size, Paint paint) {
    final path = Path();
    for (var i = 0; i < 5; i++) {
      final angle = -math.pi / 2 + i * math.pi * 4 / 5;
      final point = Offset(math.cos(angle) * size * 0.55, math.sin(angle) * size * 0.55);
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) => oldDelegate.t != t;
}

class _LanternPainter extends CustomPainter {
  const _LanternPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final string = Paint()
      ..color = AppColors.navy.withValues(alpha: 0.45)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(size.width / 2, 0), Offset(size.width / 2, size.height * 0.12), string);

    final body = Path()
      ..moveTo(size.width * 0.5, size.height * 0.12)
      ..quadraticBezierTo(
        size.width * 0.98,
        size.height * 0.28,
        size.width * 0.8,
        size.height * 0.55,
      )
      ..quadraticBezierTo(
        size.width * 0.66,
        size.height * 0.86,
        size.width * 0.5,
        size.height * 0.78,
      )
      ..quadraticBezierTo(
        size.width * 0.34,
        size.height * 0.86,
        size.width * 0.2,
        size.height * 0.55,
      )
      ..quadraticBezierTo(
        size.width * 0.02,
        size.height * 0.28,
        size.width * 0.5,
        size.height * 0.12,
      );
    canvas.drawPath(body, Paint()..color = AppColors.gold);
    canvas.drawPath(
      body,
      Paint()
        ..color = AppColors.goldDeep.withValues(alpha: 0.55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.32, size.height * 0.1, size.width * 0.36, size.height * 0.08),
        const Radius.circular(2),
      ),
      Paint()..color = AppColors.goldDeep,
    );
    canvas.drawLine(
      Offset(size.width * 0.5, size.height * 0.78),
      Offset(size.width * 0.5, size.height * 0.96),
      Paint()
        ..color = AppColors.goldDeep
        ..strokeWidth = 1.4,
    );
  }

  @override
  bool shouldRepaint(covariant _LanternPainter oldDelegate) => false;
}
