import 'dart:math';
import 'package:flutter/widgets.dart';

const double kMaxContent = 640;

double hPad(BuildContext context) {
  final w = MediaQuery.sizeOf(context).width;
  return max(16.0, (w - kMaxContent) / 2);
}
