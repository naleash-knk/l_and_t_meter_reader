import 'package:flutter/material.dart';

class ResponsiveSizing {
  ResponsiveSizing(this.size);

  factory ResponsiveSizing.of(BuildContext context) {
    return ResponsiveSizing(MediaQuery.sizeOf(context));
  }

  final Size size;

  double get width => size.width;
  double get height => size.height;

  double get _widthScale => width / 390;
  double get _heightScale => height / 844;

  double get scale {
    final base = _widthScale < _heightScale ? _widthScale : _heightScale;
    return base.clamp(0.7, 1.25);
  }

  double scaled(double value) => value * scale;

  double widthScaled(double value) => value * _widthScale.clamp(0.7, 1.3);
  double heightScaled(double value) => value * _heightScale.clamp(0.7, 1.3);
}
