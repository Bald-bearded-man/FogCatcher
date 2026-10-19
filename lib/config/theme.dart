import 'package:flutter/material.dart';

import 'pack.g.dart';

export 'pack.g.dart' show AppColors;

const _bodyFont = 'VT323';
const _titleFont = 'PressStart2P';

ThemeData buildTheme() {
  const scheme = ColorScheme.dark(
    primary: AppColors.primary,
    onPrimary: AppColors.ink,
    secondary: AppColors.accent,
    surface: AppColors.ink,
    onSurface: AppColors.paper,
    error: AppColors.alert,
  );
  const squareButton = RoundedRectangleBorder();
  final buttonShape = WidgetStateProperty.all<OutlinedBorder>(squareButton);
  final border = WidgetStateProperty.all(
    const BorderSide(color: AppColors.paper, width: 3),
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.ink,
    fontFamily: _bodyFont,
    textTheme: const TextTheme(
      bodyLarge: TextStyle(
        fontFamily: _bodyFont,
        fontSize: 20,
        color: AppColors.paper,
      ),
      bodyMedium: TextStyle(
        fontFamily: _bodyFont,
        fontSize: 20,
        color: AppColors.paper,
      ),
      bodySmall: TextStyle(
        fontFamily: _bodyFont,
        fontSize: 20,
        color: AppColors.paper,
      ),
      titleLarge: TextStyle(
        fontFamily: _titleFont,
        fontSize: 14,
        color: AppColors.paper,
      ),
      titleMedium: TextStyle(
        fontFamily: _titleFont,
        fontSize: 14,
        color: AppColors.paper,
      ),
      titleSmall: TextStyle(
        fontFamily: _titleFont,
        fontSize: 14,
        color: AppColors.paper,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: ButtonStyle(shape: buttonShape, side: border),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ButtonStyle(shape: buttonShape, side: border),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: ButtonStyle(shape: buttonShape, side: border),
    ),
    textButtonTheme: TextButtonThemeData(
      style: ButtonStyle(shape: buttonShape, side: border),
    ),
  );
}
