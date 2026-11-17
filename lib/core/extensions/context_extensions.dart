import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';

extension ContextX on BuildContext {
  TextTheme get text => Theme.of(this).textTheme;

  void showMessage(String message, {bool error = false}) {
    ScaffoldMessenger.of(this)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message), backgroundColor: error ? AppColors.red : AppColors.textPrimary));
  }
}
