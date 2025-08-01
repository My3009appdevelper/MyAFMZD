import 'package:flutter/material.dart';

class AppColors {
  // Color Mazda Soul Red Crystal (aproximado)
  static const Color primary = Color(
    0xFF3F1515,
  ); // Japanese Carmine (más cercano al 46V)
  static const Color primaryDark = Color(
    0xFF6F1E22,
  ); // Persian Plum como tono profundo
  static const Color primaryLight = Color(0xFFCE313D); // Madder Lake para hover

  // Tonos metálicos neutros y gris Mazda corporativo
  static const Color secondary = Color(0xFF2A2E33); // Gunmetal logo Mazda
  static const Color secondaryLight = Color(0xFF808080);
  static const Color secondaryDark = Color(0xFF373C41);

  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onSecondary = Color(0xFFFFFFFF);

  // Light Mode
  static const Color lightBackground = Color(0xFFF9F9F9);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightOnBackground = Color(0xFF1C1C1C);
  static const Color lightOnSurface = Color(0xFF2A2A2A);

  // Dark Mode
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1E1E1E);
  static const Color darkOnBackground = Color(0xFFEAEAEA);
  static const Color darkOnSurface = Color(0xFFD6D6D6);

  // Otros
  static const Color error = Color(0xFFB00020);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color disabled = Color(0xFF9E9E9E);
}
