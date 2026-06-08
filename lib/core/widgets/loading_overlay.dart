import 'package:flutter/material.dart';
import '../constants/app_theme.dart';

class LoadingOverlay extends StatelessWidget {
  const LoadingOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: CircularProgressIndicator(color: context.colors.textPrimary),
    );
  }
}
