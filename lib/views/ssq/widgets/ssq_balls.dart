import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

///
/// 号码球展示
///
/// [reds] 红球号码,[blues] 蓝球号码
///
class SsqBalls extends StatelessWidget {
  final List<int> reds;

  final List<int> blues;

  final double size;

  final bool highlight;

  const SsqBalls({
    super.key,
    required this.reds,
    this.blues = const [],
    this.size = 30,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6.w,
      runSpacing: 6.w,
      children: [
        ...reds.map((e) => _ball(e, const Color(0xFFE53935), highlight)),
        ...blues.map((e) => _ball(e, const Color(0xFF3F7FD8), highlight)),
      ],
    );
  }

  Widget _ball(int number, Color color, bool active) {
    return Container(
      width: size.w,
      height: size.w,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: active ? color : color.withOpacity(0.85),
        shape: BoxShape.circle,
        border: active ? Border.all(color: const Color(0xFFFF0033), width: 1.5) : null,
      ),
      child: Text(
        number.toString().padLeft(2, '0'),
        style: TextStyle(
          color: Colors.white,
          fontSize: size.w * 0.4,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
