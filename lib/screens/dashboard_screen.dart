/// dashboard_screen.dart
/// Location: lib/screens/dashboard_screen.dart
///
/// Updated version — receives shared meals & activities from AppShell
/// via constructor so both Dashboard and Progress tabs share the same data.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/dashboard_models.dart';

class DashboardScreen extends StatefulWidget {
  // ── Shared lists passed in from AppShell ──────────────────────────────────
  final List<MealEntry> meals;
  final List<ActivityEntry> activities;

  // ── Callbacks to mutate the shared lists ──────────────────────────────────
  final void Function(MealEntry) onMealAdded;
  final void Function(MealEntry) onMealRemoved;
  final void Function(ActivityEntry) onActivityAdded;
  final void Function(ActivityEntry) onActivityRemoved;

  const DashboardScreen({
    super.key,
    required this.meals,
    required this.activities,
    required this.onMealAdded,
    required this.onMealRemoved,
    required this.onActivityAdded,
    required this.onActivityRemoved,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // ─── Step data ────────────────────────────────────────────────────────────
  /// In production replace with the pedometer package for real-time steps.
  StepData _stepData = const StepData(
    currentSteps: 4200,
    targetSteps: 10000,
  );

  // ─── Computed totals ──────────────────────────────────────────────────────

  int get _totalMealCalories =>
      widget.meals.fold(0, (sum, m) => sum + m.calories);

  int get _totalCaloriesBurned =>
      widget.activities.fold(0, (sum, a) => sum + a.caloriesBurned);

  // ─── Log Meal Sheet ───────────────────────────────────────────────────────

  void _showLogMealSheet() {
    final nameCtrl = TextEditingController();
    final caloriesCtrl = TextEditingController();
    final proteinCtrl = TextEditingController();
    final carbsCtrl = TextEditingController();
    final fatCtrl = TextEditingController();
    String selectedType = 'Breakfast';
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: StatefulBuilder(
          builder: (ctx, setSheetState) => Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Log a Meal',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 20),

                  // Meal type chips
                  Wrap(
                    spacing: 8,
                    children: ['Breakfast', 'Lunch', 'Dinner', 'Snack']
                        .map((type) => ChoiceChip(
                      label: Text(type),
                      selected: selectedType == type,
                      onSelected: (_) =>
                          setSheetState(() => selectedType = type),
                      selectedColor: const Color(0xFF4A4A4A),
                      backgroundColor: const Color(0xFF2C2C2C),
                      labelStyle: TextStyle(
                        color: selectedType == type
                            ? Colors.white
                            : Colors.white54,
                      ),
                    ))
                        .toList(),
                  ),
                  const SizedBox(height: 16),

                  _sheetField(
                    controller: nameCtrl,
                    label: 'Meal name',
                    validator: (v) =>
                    v == null || v.isEmpty ? 'Enter a meal name' : null,
                  ),
                  const SizedBox(height: 12),

                  _sheetField(
                    controller: caloriesCtrl,
                    label: 'Calories (kcal)',
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (v) =>
                    v == null || v.isEmpty ? 'Enter calories' : null,
                  ),
                  const SizedBox(height: 12),

                  // Macros row
                  Row(
                    children: [
                      Expanded(
                          child: _sheetField(
                              controller: proteinCtrl,
                              label: 'Protein (g)',
                              keyboardType: TextInputType.number)),
                      const SizedBox(width: 8),
                      Expanded(
                          child: _sheetField(
                              controller: carbsCtrl,
                              label: 'Carbs (g)',
                              keyboardType: TextInputType.number)),
                      const SizedBox(width: 8),
                      Expanded(
                          child: _sheetField(
                              controller: fatCtrl,
                              label: 'Fat (g)',
                              keyboardType: TextInputType.number)),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Save button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3A3A3A),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        if (!formKey.currentState!.validate()) return;
                        final meal = MealEntry(
                          id: DateTime.now().toIso8601String(),
                          name: nameCtrl.text.trim(),
                          mealType: selectedType,
                          calories: int.tryParse(caloriesCtrl.text) ?? 0,
                          protein: double.tryParse(proteinCtrl.text) ?? 0,
                          carbs: double.tryParse(carbsCtrl.text) ?? 0,
                          fat: double.tryParse(fatCtrl.text) ?? 0,
                          loggedAt: DateTime.now(),
                        );
                        // Notify AppShell → updates shared list
                        widget.onMealAdded(meal);
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text('${meal.name} logged!'),
                          backgroundColor: Colors.green.shade700,
                        ));
                      },
                      child: const Text('Save Meal',
                          style:
                          TextStyle(color: Colors.white, fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─── Log Activity Sheet ───────────────────────────────────────────────────

  void _showLogActivitySheet() {
    final nameCtrl = TextEditingController();
    final caloriesCtrl = TextEditingController();
    final durationCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Log an Activity',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 20),

              _sheetField(
                controller: nameCtrl,
                label: 'Activity (e.g. Running, Weight Training)',
                validator: (v) => v == null || v.isEmpty
                    ? 'Enter an activity name'
                    : null,
              ),
              const SizedBox(height: 12),

              _sheetField(
                controller: durationCtrl,
                label: 'Duration (minutes)',
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (v) =>
                v == null || v.isEmpty ? 'Enter duration' : null,
              ),
              const SizedBox(height: 12),

              _sheetField(
                controller: caloriesCtrl,
                label: 'Calories burned (kcal)',
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (v) => v == null || v.isEmpty
                    ? 'Enter calories burned'
                    : null,
              ),
              const SizedBox(height: 24),

              // Save button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3A3A3A),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    if (!formKey.currentState!.validate()) return;
                    final activity = ActivityEntry(
                      id: DateTime.now().toIso8601String(),
                      name: nameCtrl.text.trim(),
                      caloriesBurned:
                      int.tryParse(caloriesCtrl.text) ?? 0,
                      durationMinutes:
                      int.tryParse(durationCtrl.text) ?? 0,
                      loggedAt: DateTime.now(),
                    );
                    // Notify AppShell → updates shared list
                    widget.onActivityAdded(activity);
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('${activity.name} logged!'),
                      backgroundColor: Colors.green.shade700,
                    ));
                  },
                  child: const Text('Save Activity',
                      style:
                      TextStyle(color: Colors.white, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Update Steps Dialog ──────────────────────────────────────────────────

  void _showUpdateStepsDialog() {
    final stepsCtrl =
    TextEditingController(text: _stepData.currentSteps.toString());
    final targetCtrl =
    TextEditingController(text: _stepData.targetSteps.toString());

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2C2C2C),
        title: const Text('Update Steps',
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _sheetField(
              controller: stepsCtrl,
              label: 'Current steps',
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            const SizedBox(height: 12),
            _sheetField(
              controller: targetCtrl,
              label: 'Daily target',
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel',
                style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3A3A3A)),
            onPressed: () {
              setState(() {
                _stepData = StepData(
                  currentSteps: int.tryParse(stepsCtrl.text) ??
                      _stepData.currentSteps,
                  targetSteps: int.tryParse(targetCtrl.text) ??
                      _stepData.targetSteps,
                );
              });
              Navigator.pop(ctx);
            },
            child: const Text('Update',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFFFFF), Color(0xFFB0B0B0)],
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Column(
            children: [
              _buildDailyProgressCard(),
              const SizedBox(height: 16),
              _buildNutritionCard(),
              const SizedBox(height: 16),
              _buildActivityCard(),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Daily Progress Card ──────────────────────────────────────────────────

  Widget _buildDailyProgressCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Daily Progress',
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1A1A1A)),
          ),
          const SizedBox(height: 20),

          Row(
            children: [
              // Step ring — tap to update
              GestureDetector(
                onTap: _showUpdateStepsDialog,
                child: SizedBox(
                  width: 130,
                  height: 130,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Background ring
                      const SizedBox(
                        width: 130,
                        height: 130,
                        child: CircularProgressIndicator(
                          value: 1.0,
                          strokeWidth: 12,
                          color: Color(0xFFE0DEF0),
                        ),
                      ),
                      // Progress ring
                      SizedBox(
                        width: 130,
                        height: 130,
                        child: CircularProgressIndicator(
                          value: _stepData.progress,
                          strokeWidth: 12,
                          color: const Color(0xFF1A1A1A),
                          strokeCap: StrokeCap.round,
                        ),
                      ),
                      // Centre label
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${_stepData.percentComplete}%',
                            style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF1A1A1A)),
                          ),
                          const Text(
                            'Steps',
                            style: TextStyle(
                                fontSize: 11, color: Colors.black54),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 20),

              // Step stats
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _statRow('Steps today',
                        _formatNumber(_stepData.currentSteps)),
                    const SizedBox(height: 8),
                    _statRow(
                        'Target', _formatNumber(_stepData.targetSteps)),
                    const SizedBox(height: 8),
                    _statRow('Remaining',
                        _formatNumber(_stepData.remainingSteps)),
                    const SizedBox(height: 8),
                    const Text(
                      'Tap ring to update',
                      style: TextStyle(
                          fontSize: 11,
                          color: Colors.black38,
                          fontStyle: FontStyle.italic),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),
          const Divider(color: Colors.black12),
          const SizedBox(height: 12),

          // Total calories burned
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Calories burned',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A1A)),
              ),
              Text(
                '$_totalCaloriesBurned kcal',
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A1A)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Nutrition Card ───────────────────────────────────────────────────────

  Widget _buildNutritionCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Nutrition',
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1A1A1A)),
              ),
              if (widget.meals.isNotEmpty)
                Text(
                  '$_totalMealCalories kcal',
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black54),
                ),
            ],
          ),
          const SizedBox(height: 14),

          if (widget.meals.isEmpty)
            const Text(
              'No meals logged yet. Tap below to add one.',
              style: TextStyle(color: Colors.black45, fontSize: 13),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: widget.meals.length,
              separatorBuilder: (_, e_) =>
              const Divider(color: Colors.black12, height: 1),
              itemBuilder: (_, i) {
                final meal = widget.meals[i];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(meal.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A1A1A),
                          fontSize: 14)),
                  subtitle: Text(
                      '${meal.mealType}  •  ${meal.macroSummary}',
                      style: const TextStyle(
                          color: Colors.black45, fontSize: 12)),
                  trailing: Text('${meal.calories} kcal',
                      style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1A1A1A),
                          fontSize: 13)),
                  // Long press to delete
                  onLongPress: () => widget.onMealRemoved(meal),
                );
              },
            ),

          const SizedBox(height: 12),
          _darkButton(
              label: '+ Log Meal', onPressed: _showLogMealSheet),
        ],
      ),
    );
  }

  // ─── Activity Card ────────────────────────────────────────────────────────

  Widget _buildActivityCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Activity Log',
            style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: Color(0xFF1A1A1A)),
          ),
          const SizedBox(height: 14),

          if (widget.activities.isEmpty)
            const Text(
              'No activities logged yet. Tap below to add one.',
              style: TextStyle(color: Colors.black45, fontSize: 13),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: widget.activities.length,
              separatorBuilder: (_, err_) =>
              const Divider(color: Colors.black12, height: 1),
              itemBuilder: (_, i) {
                final activity = widget.activities[i];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFF2C2C2C),
                    child: Icon(Icons.fitness_center,
                        color: Colors.white, size: 18),
                  ),
                  title: Text(activity.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1A1A1A),
                          fontSize: 14)),
                  subtitle: Text(
                      '${activity.durationLabel}  •  ${activity.caloriesLabel} burned',
                      style: const TextStyle(
                          color: Colors.black45, fontSize: 12)),
                  // Long press to delete
                  onLongPress: () =>
                      widget.onActivityRemoved(activity),
                );
              },
            ),

          const SizedBox(height: 12),
          _darkButton(
              label: 'Log activity',
              onPressed: _showLogActivitySheet),
        ],
      ),
    );
  }

  // ─── Shared helper widgets ────────────────────────────────────────────────

  Widget _card({required Widget child}) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.85),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Colors.black, width: 1.5),
    ),
    child: child,
  );

  Widget _darkButton(
      {required String label, required VoidCallback onPressed}) =>
      SizedBox(
        width: double.infinity,
        height: 46,
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2C2C2C),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
            elevation: 0,
          ),
          child: Text(label,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500)),
        ),
      );

  Widget _statRow(String label, String value) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(label,
          style: const TextStyle(color: Colors.black54, fontSize: 13)),
      Text(value,
          style: const TextStyle(
              color: Color(0xFF1A1A1A),
              fontSize: 13,
              fontWeight: FontWeight.w700)),
    ],
  );

  Widget _sheetField({
    required TextEditingController controller,
    required String label,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) =>
      TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        validator: validator,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle:
          const TextStyle(color: Colors.white54, fontSize: 13),
          enabledBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white30)),
          focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white, width: 2)),
          errorStyle: const TextStyle(color: Colors.redAccent),
          contentPadding: const EdgeInsets.only(bottom: 4),
        ),
      );

  /// Formats a number with commas e.g. 10000 → 10,000
  String _formatNumber(int n) => n.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
}