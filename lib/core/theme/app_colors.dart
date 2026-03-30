import 'package:flutter/material.dart';

/// Centralized color constants for SABOHUB.
///
/// Use these instead of hardcoding `Color(0xFF...)` throughout the app.
/// All colors are organized by semantic purpose.
///
/// Usage:
/// ```dart
/// Container(color: AppColors.success)
/// Text('Error', style: TextStyle(color: AppColors.error))
/// ```
class AppColors {
  AppColors._(); // Prevent instantiation

  // ─── Brand Colors ─────────────────────────────────────────────────────────
  static const Color primary = Color(0xFF7C3AED);
  static const Color primaryLight = Color(0xFF9F67FF);
  static const Color primaryDark = Color(0xFF5B21B6);
  static const Color secondary = Color(0xFF06B6D4);
  static const Color secondaryLight = Color(0xFF22D3EE);
  static const Color secondaryDark = Color(0xFF0891B2);

  // ─── Semantic Colors ──────────────────────────────────────────────────────
  static const Color success = Color(0xFF10B981);
  static const Color successLight = Color(0xFFD1FAE5);
  static const Color successDark = Color(0xFF059669);

  static const Color warning = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFFEF3C7);
  static const Color warningDark = Color(0xFFD97706);

  static const Color error = Color(0xFFEF4444);
  static const Color errorLight = Color(0xFFFEE2E2);
  static const Color errorDark = Color(0xFFDC2626);

  static const Color info = Color(0xFF3B82F6);
  static const Color infoLight = Color(0xFFDBEAFE);
  static const Color infoDark = Color(0xFF2563EB);

  // ─── Surface & Background ─────────────────────────────────────────────────
  static const Color surface = Color(0xFFF8FAFC);
  static const Color surfaceVariant = Color(0xFFF1F5F9);
  static const Color background = Color(0xFFFFFFFF);
  static const Color backgroundDark = Color(0xFF0F172A);
  static const Color card = Color(0xFFFFFFFF);
  static const Color cardHover = Color(0xFFF8FAFC);

  // ─── Border & Divider ─────────────────────────────────────────────────────
  static const Color border = Color(0xFFE2E8F0);
  static const Color borderLight = Color(0xFFF1F5F9);
  static const Color borderDark = Color(0xFFCBD5E1);
  static const Color divider = Color(0xFFE2E8F0);

  // ─── Text ─────────────────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFF1E293B);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textTertiary = Color(0xFF94A3B8);
  static const Color textOnPrimary = Color(0xFFFFFFFF);
  static const Color textOnDark = Color(0xFFFFFFFF);
  static const Color textLink = Color(0xFF3B82F6);

  // ─── Status Colors (for badges, tags, status indicators) ──────────────────
  static const Color statusActive = Color(0xFF10B981);
  static const Color statusInactive = Color(0xFF94A3B8);
  static const Color statusPending = Color(0xFFF59E0B);
  static const Color statusProcessing = Color(0xFF3B82F6);
  static const Color statusCompleted = Color(0xFF10B981);
  static const Color statusCancelled = Color(0xFFEF4444);
  static const Color statusDraft = Color(0xFF94A3B8);
  static const Color statusOverdue = Color(0xFFDC2626);

  // ─── Payment Status Colors ────────────────────────────────────────────────
  static const Color paymentPaid = Color(0xFF10B981);
  static const Color paymentUnpaid = Color(0xFFEF4444);
  static const Color paymentPartial = Color(0xFFF59E0B);
  static const Color paymentDebt = Color(0xFFDC2626);
  static const Color paymentPending = Color(0xFF94A3B8);
  static const Color paymentRefunded = Color(0xFF8B5CF6);

  // ─── Delivery Status Colors ───────────────────────────────────────────────
  static const Color deliveryPending = Color(0xFF94A3B8);
  static const Color deliveryAwaitingPickup = Color(0xFFF59E0B);
  static const Color deliveryDelivering = Color(0xFF3B82F6);
  static const Color deliveryDelivered = Color(0xFF10B981);
  static const Color deliveryFailed = Color(0xFFEF4444);

  // ─── Order Status Colors ──────────────────────────────────────────────────
  static const Color orderDraft = Color(0xFF94A3B8);
  static const Color orderPendingApproval = Color(0xFFF59E0B);
  static const Color orderConfirmed = Color(0xFF3B82F6);
  static const Color orderProcessing = Color(0xFF06B6D4);
  static const Color orderReady = Color(0xFF8B5CF6);
  static const Color orderCompleted = Color(0xFF10B981);
  static const Color orderCancelled = Color(0xFFEF4444);

  // ─── Customer Tier Colors ─────────────────────────────────────────────────
  static const Color tierDiamond = Color(0xFF06B6D4);
  static const Color tierGold = Color(0xFFF59E0B);
  static const Color tierSilver = Color(0xFF94A3B8);
  static const Color tierBronze = Color(0xFFCD7F32);

  // ─── Role Colors ──────────────────────────────────────────────────────────
  static const Color roleSuperAdmin = Color(0xFFDC2626);
  static const Color roleCeo = Color(0xFF7C3AED);
  static const Color roleManager = Color(0xFF2563EB);
  static const Color roleShiftLeader = Color(0xFF0891B2);
  static const Color roleStaff = Color(0xFF10B981);
  static const Color roleDriver = Color(0xFFF59E0B);
  static const Color roleWarehouse = Color(0xFF64748B);
  static const Color roleFinance = Color(0xFF8B5CF6);

  // ─── Grey Shades ────────────────────────────────────────────────────────
  static const Color grey50 = Color(0xFFFAFAFA);
  static const Color grey100 = Color(0xFFF5F5F5);
  static const Color grey200 = Color(0xFFEEEEEE);
  static const Color grey300 = Color(0xFFE0E0E0);
  static const Color grey400 = Color(0xFFBDBDBD);
  static const Color grey500 = Color(0xFF9E9E9E);
  static const Color grey600 = Color(0xFF757575);
  static const Color grey700 = Color(0xFF616161);
  static const Color grey800 = Color(0xFF424242);
  static const Color grey900 = Color(0xFF212121);

  // ─── Neutral/UI Colors ────────────────────────────────────────────────────
  static const Color neutral400 = Color(0xFF9CA3AF); // Grey-400 Tailwind
  static const Color neutral500 = Color(0xFF6B7280); // Grey-500 Tailwind
  static const Color neutral600 = Color(0xFF4B5563); // Grey-600 Tailwind

  // ─── Chart / Graph Colors ─────────────────────────────────────────────────
  static const List<Color> chartPalette = [
    Color(0xFF7C3AED),
    Color(0xFF06B6D4),
    Color(0xFF10B981),
    Color(0xFFF59E0B),
    Color(0xFFEF4444),
    Color(0xFF8B5CF6),
    Color(0xFF3B82F6),
    Color(0xFFEC4899),
  ];

  // ─── Shimmer / Skeleton ───────────────────────────────────────────────────
  static const Color shimmerBase = Color(0xFFE2E8F0);
  static const Color shimmerHighlight = Color(0xFFF1F5F9);

  // ─── Misc ─────────────────────────────────────────────────────────────────
  static const Color overlay = Color(0x80000000);
  static const Color transparent = Colors.transparent;
  static const Color scrim = Color(0x52000000);

  // ─── Helper Methods ───────────────────────────────────────────────────────

  /// Get color for order status
  static Color forOrderStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'draft':
        return orderDraft;
      case 'pending':
      case 'pending_approval':
        return orderPendingApproval;
      case 'confirmed':
      case 'sent_to_warehouse':
        return orderConfirmed;
      case 'processing':
      case 'picking':
        return orderProcessing;
      case 'ready':
        return orderReady;
      case 'completed':
        return orderCompleted;
      case 'cancelled':
        return orderCancelled;
      default:
        return textSecondary;
    }
  }

  /// Get color for payment status
  static Color forPaymentStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'paid':
        return paymentPaid;
      case 'unpaid':
        return paymentUnpaid;
      case 'partial':
        return paymentPartial;
      case 'debt':
        return paymentDebt;
      case 'pending':
      case 'pending_transfer':
        return paymentPending;
      case 'refunded':
        return paymentRefunded;
      default:
        return textSecondary;
    }
  }

  /// Get color for delivery status
  static Color forDeliveryStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'pending':
        return deliveryPending;
      case 'awaiting_pickup':
        return deliveryAwaitingPickup;
      case 'delivering':
        return deliveryDelivering;
      case 'delivered':
        return deliveryDelivered;
      case 'failed':
        return deliveryFailed;
      default:
        return textSecondary;
    }
  }

  /// Get color for customer tier
  static Color forCustomerTier(String? tier) {
    switch (tier?.toLowerCase()) {
      case 'diamond':
        return tierDiamond;
      case 'gold':
        return tierGold;
      case 'silver':
        return tierSilver;
      case 'bronze':
        return tierBronze;
      default:
        return textSecondary;
    }
  }

  /// Get color for user role
  static Color forRole(String? role) {
    switch (role?.toLowerCase()) {
      case 'super_admin':
      case 'superadmin':
        return roleSuperAdmin;
      case 'ceo':
        return roleCeo;
      case 'manager':
        return roleManager;
      case 'shift_leader':
      case 'shiftleader':
        return roleShiftLeader;
      case 'staff':
        return roleStaff;
      case 'driver':
        return roleDriver;
      case 'warehouse':
        return roleWarehouse;
      case 'finance':
        return roleFinance;
      default:
        return textSecondary;
    }
  }

  /// Get background color (light version) for status
  static Color forStatusBackground(String? status) {
    final baseColor = forOrderStatus(status);
    return baseColor.withValues(alpha: 0.1);
  }
}
