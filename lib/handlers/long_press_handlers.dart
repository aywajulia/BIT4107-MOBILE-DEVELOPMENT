/// long_press_handler.dart
/// Handles long‑press gestures with a context menu.
/// Now supports viewing detailed meal information.

library;

import 'package:flutter/material.dart';
import '../service/event_logger.dart';
import '../model/meal_entry.dart';

class LongPressHandler {
  /// Shows a bottom sheet with options for a meal.
  static void showMealOptions(
      BuildContext context,
      MealEntry meal,
      VoidCallback onDelete,
      ) {
    EventLogger.logEvent('LongPress_Meal', screen: 'Dashboard', data: meal.name);

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            // Meal name as header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                meal.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${meal.calories} kcal',
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),

            // ── Delete Option ──────────────────────────────────────────
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.redAccent),
              title: const Text(
                'Delete Meal',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                onDelete();
              },
            ),

            // ── View Details Option (now functional) ──────────────────
            ListTile(
              leading: const Icon(Icons.info, color: Colors.blueAccent),
              title: const Text(
                'View Details',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                _showMealDetailsDialog(context, meal);
              },
            ),

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  /// Shows a detailed dialog with all meal information.
  static void _showMealDetailsDialog(BuildContext context, MealEntry meal) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF2C2C2C),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          meal.name,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _detailRow('Meal Type', meal.mealTypeLabel),
            const Divider(color: Colors.white24),
            _detailRow('Calories', '${meal.calories} kcal'),
            const Divider(color: Colors.white24),
            _detailRow('Protein', '${meal.protein.toStringAsFixed(1)} g'),
            const Divider(color: Colors.white24),
            _detailRow('Carbs', '${meal.carbs.toStringAsFixed(1)} g'),
            const Divider(color: Colors.white24),
            _detailRow('Fat', '${meal.fat.toStringAsFixed(1)} g'),
            const Divider(color: Colors.white24),
            if (meal.quantity > 0) ...[
              _detailRow('Quantity', '${meal.quantity.toStringAsFixed(0)} g'),
              const Divider(color: Colors.white24),
            ],
            _detailRow('Logged At', meal.loggedAt.toString().substring(0, 16)),
            if (meal.source.isNotEmpty) ...[
              const Divider(color: Colors.white24),
              _detailRow('Source', meal.source),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Close',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}