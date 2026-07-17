import 'package:flutter/material.dart';

@immutable
class XSpacing extends ThemeExtension<XSpacing> {
  const XSpacing({
    this.xs = 4,
    this.sm = 8,
    this.md = 12,
    this.lg = 16,
    this.xl = 20,
    this.xxl = 24,
    this.xxxl = 32,
  });

  final double xs;
  final double sm;
  final double md;
  final double lg;
  final double xl;
  final double xxl;
  final double xxxl;

  @override
  XSpacing copyWith({
    double? xs,
    double? sm,
    double? md,
    double? lg,
    double? xl,
    double? xxl,
    double? xxxl,
  }) => XSpacing(
    xs: xs ?? this.xs,
    sm: sm ?? this.sm,
    md: md ?? this.md,
    lg: lg ?? this.lg,
    xl: xl ?? this.xl,
    xxl: xxl ?? this.xxl,
    xxxl: xxxl ?? this.xxxl,
  );

  @override
  XSpacing lerp(ThemeExtension<XSpacing>? other, double t) {
    if (other is! XSpacing) return this;
    return XSpacing(
      xs: lerpDouble(xs, other.xs, t),
      sm: lerpDouble(sm, other.sm, t),
      md: lerpDouble(md, other.md, t),
      lg: lerpDouble(lg, other.lg, t),
      xl: lerpDouble(xl, other.xl, t),
      xxl: lerpDouble(xxl, other.xxl, t),
      xxxl: lerpDouble(xxxl, other.xxxl, t),
    );
  }
}

@immutable
class XRadius extends ThemeExtension<XRadius> {
  const XRadius({
    this.sm = 8,
    this.md = 12,
    this.lg = 16,
    this.xl = 20,
    this.pill = 999,
  });

  final double sm;
  final double md;
  final double lg;
  final double xl;
  final double pill;

  @override
  XRadius copyWith({
    double? sm,
    double? md,
    double? lg,
    double? xl,
    double? pill,
  }) => XRadius(
    sm: sm ?? this.sm,
    md: md ?? this.md,
    lg: lg ?? this.lg,
    xl: xl ?? this.xl,
    pill: pill ?? this.pill,
  );

  @override
  XRadius lerp(ThemeExtension<XRadius>? other, double t) {
    if (other is! XRadius) return this;
    return XRadius(
      sm: lerpDouble(sm, other.sm, t),
      md: lerpDouble(md, other.md, t),
      lg: lerpDouble(lg, other.lg, t),
      xl: lerpDouble(xl, other.xl, t),
      pill: lerpDouble(pill, other.pill, t),
    );
  }
}

@immutable
class XGradients extends ThemeExtension<XGradients> {
  const XGradients({
    this.primary = const LinearGradient(
      colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    this.lab = const LinearGradient(
      colors: [Color(0xFFEFF6FF), Color(0xFFF8FAFC)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  });

  final LinearGradient primary;
  final LinearGradient lab;

  @override
  XGradients copyWith({LinearGradient? primary, LinearGradient? lab}) =>
      XGradients(primary: primary ?? this.primary, lab: lab ?? this.lab);

  @override
  XGradients lerp(ThemeExtension<XGradients>? other, double t) {
    if (other is! XGradients) return this;
    return XGradients(
      primary: LinearGradient.lerp(primary, other.primary, t) ?? primary,
      lab: LinearGradient.lerp(lab, other.lab, t) ?? lab,
    );
  }
}

double lerpDouble(double a, double b, double t) => a + (b - a) * t;

extension XTheme on BuildContext {
  XSpacing get spacing => Theme.of(this).extension<XSpacing>()!;
  XRadius get radius => Theme.of(this).extension<XRadius>()!;
  XGradients get gradients => Theme.of(this).extension<XGradients>()!;
}
