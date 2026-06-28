/// meal_history_screen.dart
/// Location: lib/screens/meal_history_screen.dart
///
/// Displays all logged meals grouped by date.
/// Shows total calories per day, and expands to show meal‑type breakdown.
library;

import 'package:flutter/material.dart';
import '../model/meal_entry.dart';

class MealHistoryScreen extends StatelessWidget {
  final List<MealEntry> meals;

  const MealHistoryScreen({super.key, required this.meals});

  @override
  Widget build(BuildContext context) {
    // Group meals by date
    final Map<String, List<MealEntry>> grouped = {};
    for (final meal in meals) {
      final key = meal.dateKey;
      grouped.putIfAbsent(key, () => []).add(meal);
    }

    final sortedDates = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFFFFF), Color(0xFFB0B0B0)],
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Text('Meal History', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: Color(0xFF1A1A1A))),
              ),
              const SizedBox(height: 8),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text('Your food log, grouped by day', style: TextStyle(fontSize: 13, color: Colors.black45)),
              ),
              const SizedBox(height: 16),

              Expanded(
                child: sortedDates.isEmpty
                    ? const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.restaurant, size: 64, color: Colors.black26),
                      SizedBox(height: 16),
                      Text('No meals logged yet.\nStart logging from the Nutrition screen!', textAlign: TextAlign.center, style: TextStyle(color: Colors.black45, fontSize: 15, height: 1.5)),
                    ],
                  ),
                )
                    : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: sortedDates.length,
                  itemBuilder: (context, index) {
                    final date = sortedDates[index];
                    final dayMeals = grouped[date]!;
                    final totalCalories = dayMeals.fold(0, (sum, m) => sum + m.calories);
                    final dateTime = DateTime.tryParse(date);
                    return _buildDateCard(
                      date: date,
                      dateTime: dateTime,
                      meals: dayMeals,
                      totalCalories: totalCalories,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateCard({
    required String date,
    required DateTime? dateTime,
    required List<MealEntry> meals,
    required int totalCalories,
  }) {
    String displayDate;
    if (dateTime != null) {
      displayDate = '${_dayName(dateTime.weekday)}, ${dateTime.day} ${_monthName(dateTime.month)} ${dateTime.year}';
    } else {
      displayDate = date;
    }

    final mealTypeCounts = <String, int>{};
    for (final meal in meals) {
      mealTypeCounts[meal.mealType] = (mealTypeCounts[meal.mealType] ?? 0) + 1;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: ExpansionTile(
        title: Text(displayDate, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
        subtitle: Row(
          children: [
            const Icon(Icons.local_fire_department, size: 16, color: Colors.orange),
            const SizedBox(width: 4),
            Text('$totalCalories kcal • ${meals.length} meals', style: const TextStyle(color: Colors.black54, fontSize: 13)),
          ],
        ),
        trailing: Wrap(
          spacing: 8,
          children: mealTypeCounts.entries.map((entry) {
            final icon = _mealTypeIcon(entry.key);
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 2),
                Text('${entry.value}', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              ],
            );
          }).toList(),
        ),
        children: [
          const Divider(),
          ...meals.map((meal) => _buildMealTile(meal)),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildMealTile(MealEntry meal) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: _mealTypeColor(meal.mealType),
        radius: 16,
        child: Icon(_mealTypeIcon(meal.mealType), size: 16, color: Colors.white),
      ),
      title: Text(meal.name, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(
        '${meal.mealTypeLabel}  •  ${meal.quantity > 0 ? '${meal.quantity}g' : ''}  •  ${meal.source}',
        style: const TextStyle(fontSize: 12, color: Colors.black54),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text('${meal.calories} kcal', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
          Text(meal.loggedAt.toString().substring(11, 16), style: const TextStyle(fontSize: 10, color: Colors.black38)), // HH:mm
        ],
      ),
    );
  }

  IconData _mealTypeIcon(String type) {
    switch (type) {
      case 'breakfast': return Icons.wb_sunny;
      case 'lunch':     return Icons.lunch_dining;
      case 'dinner':    return Icons.dinner_dining;
      case 'snack':     return Icons.cookie;
      default:          return Icons.restaurant;
    }
  }

  Color _mealTypeColor(String type) {
    switch (type) {
      case 'breakfast': return Colors.amber.shade700;
      case 'lunch':     return Colors.blue.shade700;
      case 'dinner':    return Colors.deepPurple.shade700;
      case 'snack':     return Colors.orange.shade700;
      default:          return Colors.grey.shade600;
    }
  }

  String _dayName(int weekday) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[weekday - 1];
  }

  String _monthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }
}