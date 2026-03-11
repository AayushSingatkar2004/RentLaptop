// lib/core/constants/app_colors.dart

import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ── Brand ──────────────────────────────────────────────────
  static const Color primary      = Color(0xFF1A56DB); // deep blue
  static const Color primaryLight = Color(0xFFEBF5FF);
  static const Color accent       = Color(0xFF0E9F6E); // green

  // ── Background ─────────────────────────────────────────────
  static const Color background   = Color(0xFFF9FAFB);
  static const Color surface      = Color(0xFFFFFFFF);
  static const Color divider      = Color(0xFFE5E7EB);

  // ── Text ───────────────────────────────────────────────────
  static const Color textPrimary   = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textHint      = Color(0xFF9CA3AF);

  // ── Status — Laptop ────────────────────────────────────────
  static const Color available    = Color(0xFF0E9F6E); // green
  static const Color rented       = Color(0xFF1A56DB); // blue
  static const Color damaged      = Color(0xFFE02424); // red
  static const Color underRepair  = Color(0xFFFF8A4C); // orange

  // ── Status — Customer ──────────────────────────────────────
  static const Color active       = Color(0xFF0E9F6E); // green
  static const Color inactive     = Color(0xFF6B7280); // grey

  // ── Due Status ─────────────────────────────────────────────
  static const Color pending      = Color(0xFFFF8A4C); // orange
  static const Color partial      = Color(0xFFE3A008); // amber
  static const Color paid         = Color(0xFF0E9F6E); // green
  static const Color waived       = Color(0xFF9CA3AF); // grey
  static const Color overdue      = Color(0xFFE02424); // red

  // ── Stat Card Colors ───────────────────────────────────────
  static const Color cardBlue     = Color(0xFF1A56DB);
  static const Color cardGreen    = Color(0xFF0E9F6E);
  static const Color cardOrange   = Color(0xFFFF8A4C);
  static const Color cardRed      = Color(0xFFE02424);
  static const Color cardPurple   = Color(0xFF7E3AF2);
  static const Color cardTeal     = Color(0xFF0694A2);
}