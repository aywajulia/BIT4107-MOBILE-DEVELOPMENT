/// dashboard_screen.dart
/// Location: lib/screen/dashboard_screen.dart
///
/// Main dashboard – now with:
///   • Accelerometer-based step counter
///   • GPS tracking in activity logging (distance + pace)

library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ─── Models ─────────────────────────────────────────────────────────────────
import '../model/meal_entry.dart';
import '../model/dashboard_model.dart';

// ─── Services ────────────────────────────────────────────────────────────────
import '../service/activity_calorie_service.dart';
import '../service/database_helper.dart';
import '../service/step_service.dart';
import '../service/location_service.dart';

// ─── Handlers ────────────────────────────────────────────────────────────────
import '../handlers/long_press_handlers.dart';

class DashboardScreen extends StatefulWidget {
  final List<MealEntry> meals;
  final List<ActivityEntry> activities;
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
  StepData _stepData = const StepData(currentSteps: 0, targetSteps: 10000);
  Stream<int>? _stepStream;
  double _userWeightKg = 70.0;

  @override
  void initState() {
    super.initState();
    _loadUserWeight();
    _initStepListener();
  }

  @override
  void dispose() {
    _stepStream = null;
    StepService.dispose();
    super.dispose();
  }

  Future<void> _loadUserWeight() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final uid = prefs.getString('user_uid');
      if (uid != null) {
        final db = DatabaseHelper();
        final userMap = await db.getUserByUid(uid);
        if (userMap != null && userMap['weight'] != null) {
          setState(() {
            _userWeightKg = double.tryParse(userMap['weight']) ?? 70.0;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading user weight: $e');
    }
  }

  void _initStepListener() async {
    _stepStream = StepService.stepStream;
    _stepStream!.listen((steps) {
      setState(() {
        _stepData = StepData(
          currentSteps: steps,
          targetSteps: _stepData.targetSteps,
        );
      });
    }, onError: (error) {
      debugPrint('Step sensor error: $error');
    });
  }

  int get _totalMealCalories =>
      widget.meals.fold(0, (sum, m) => sum + m.calories);

  int get _totalCaloriesBurned =>
      widget.activities.fold(0, (sum, a) => sum + a.caloriesBurned);

  // ─── Log Meal Sheet ──────────────────────────────────────────────────────

  void _showLogMealSheet() {
    final nameCtrl = TextEditingController();
    final calPer100Ctrl = TextEditingController();
    final quantityCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Form(
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

                      _sheetField(
                        controller: nameCtrl,
                        label: 'Food Name',
                        validator: (v) =>
                        v == null || v.isEmpty ? 'Enter a food name' : null,
                      ),
                      const SizedBox(height: 12),

                      _sheetField(
                        controller: calPer100Ctrl,
                        label: 'Calories per 100g (kcal)',
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ],
                        validator: (v) => v == null || v.isEmpty
                            ? 'Enter calories per 100g'
                            : null,
                        onChanged: (_) => setSheetState(() {}),
                      ),
                      const SizedBox(height: 12),

                      _sheetField(
                        controller: quantityCtrl,
                        label: 'Quantity (grams)',
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ],
                        validator: (v) => v == null || v.isEmpty
                            ? 'Enter quantity'
                            : null,
                        onChanged: (_) => setSheetState(() {}),
                      ),
                      const SizedBox(height: 20),

                      Builder(
                        builder: (context) {
                          final double calPer100 =
                              double.tryParse(calPer100Ctrl.text) ?? 0;
                          final double qty =
                              double.tryParse(quantityCtrl.text) ?? 0;
                          final total = (calPer100 / 100) * qty;
                          return Text(
                            'Total Calories: ${total.toStringAsFixed(0)} kcal',
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 16),
                          );
                        },
                      ),

                      const SizedBox(height: 24),

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
                            final calPer100 =
                                double.tryParse(calPer100Ctrl.text) ?? 0;
                            final qty =
                                double.tryParse(quantityCtrl.text) ?? 0;
                            final totalCal = (calPer100 / 100) * qty;

                            final meal = MealEntry(
                              id: DateTime.now().toIso8601String(),
                              name: nameCtrl.text.trim(),
                              mealType: 'Custom',
                              calories: totalCal.round(),
                              protein: 0,
                              carbs: 0,
                              fat: 0,
                              loggedAt: DateTime.now(),
                              quantity: qty,
                              source: 'custom',
                            );

                            widget.onMealAdded(meal);
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('${meal.name} logged!'),
                                backgroundColor: Colors.green.shade700,
                              ),
                            );
                          },
                          child: const Text('Save Meal',
                              style: TextStyle(
                                  color: Colors.white, fontSize: 16)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ─── Log Activity Sheet (with GPS toggle) ────────────────────────────────

  void _showLogActivitySheet() {
    final nameCtrl = TextEditingController();
    final durationCtrl = TextEditingController();
    String selectedActivity = 'Running (jog)';
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            bool useGps = false;
            bool isTrackingGps = false;

            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
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
                        label: 'Activity Name',
                        validator: (v) => v == null || v.isEmpty
                            ? 'Enter an activity name'
                            : null,
                      ),
                      const SizedBox(height: 12),

                      DropdownButtonFormField<String>(
                        initialValue: selectedActivity,
                        dropdownColor: const Color(0xFF2C2C2C),
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: 'Activity Type (for calorie calc)',
                          labelStyle: TextStyle(color: Colors.white54),
                          enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.white24)),
                          focusedBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.white)),
                        ),
                        items: ActivityCalorieService.metValues.keys
                            .map((key) => DropdownMenuItem(
                          value: key,
                          child: Text(key),
                        ))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setSheetState(() => selectedActivity = val);
                          }
                        },
                      ),
                      const SizedBox(height: 12),

                      _sheetField(
                        controller: durationCtrl,
                        label: 'Duration (minutes)',
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ],
                        validator: (v) => v == null || v.isEmpty
                            ? 'Enter duration'
                            : null,
                        onChanged: (_) => setSheetState(() {}),
                      ),
                      const SizedBox(height: 12),

                      // ─── GPS Tracking Toggle ──────────────────────────
                      Row(
                        children: [
                          const Icon(Icons.gps_fixed, color: Colors.white54, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              // ignore: dead_code
                              isTrackingGps ? 'Tracking GPS...' : 'Track distance with GPS',
                              style: const TextStyle(color: Colors.white70, fontSize: 13),
                            ),
                          ),
                          Switch(
                            value: useGps,
                            activeThumbColor: Colors.green,
                            onChanged: (val) async {
                              if (val) {
                                try {
                                  setSheetState(() {
                                    useGps = true;
                                    isTrackingGps = true;
                                  });
                                  await LocationService().startTracking();
                                } catch (e) {
                                  setSheetState(() {
                                    useGps = false;
                                    isTrackingGps = false;
                                  });
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('GPS Error: $e'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                }
                              } else {
                                LocationService().cancelTracking();
                                setSheetState(() {
                                  useGps = false;
                                  isTrackingGps = false;
                                });
                              }
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      Builder(
                        builder: (context) {
                          final minutes =
                              int.tryParse(durationCtrl.text) ?? 0;
                          final calories =
                          ActivityCalorieService.calculateCalories(
                              selectedActivity, _userWeightKg, minutes);
                          return Text(
                            'Calories Burned: ${calories.toStringAsFixed(0)} kcal',
                            style: const TextStyle(
                                color: Colors.greenAccent, fontSize: 16),
                          );
                        },
                      ),
                      const SizedBox(height: 24),

                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF3A3A3A),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () async {
                            if (!formKey.currentState!.validate()) return;

                            final minutes =
                                int.tryParse(durationCtrl.text) ?? 0;
                            double distance = 0.0;
                            double pace = 0.0;

                            if (useGps) {
                              final result =
                              await LocationService().stopTracking(minutes);
                              distance = result.distance;
                              pace = result.pace;
                              setSheetState(() => isTrackingGps = false);
                            }

                            final calories =
                            ActivityCalorieService.calculateCalories(
                                selectedActivity, _userWeightKg, minutes);

                            final activity = ActivityEntry(
                              id: DateTime.now().toIso8601String(),
                              name: nameCtrl.text.trim(),
                              caloriesBurned: calories.round(),
                              durationMinutes: minutes,
                              loggedAt: DateTime.now(),
                              distance: distance > 0 ? distance : null,
                              pace: pace > 0 ? pace : null,
                            );

                            widget.onActivityAdded(activity);

                            if (!context.mounted) return;
                            Navigator.pop(context);

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  '${activity.name} logged! '
                                      '${distance > 0 ? "(${distance.toStringAsFixed(2)} km, ${pace.toStringAsFixed(1)} min/km)" : ""}',
                                ),
                                backgroundColor: Colors.green.shade700,
                              ),
                            );
                          },
                          child: const Text('Save Activity',
                              style: TextStyle(
                                  color: Colors.white, fontSize: 16)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ─── Update Steps Dialog ──────────────────────────────────────────────────

  void _showUpdateStepsDialog() {
    final targetCtrl =
    TextEditingController(text: _stepData.targetSteps.toString());

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2C2C2C),
        title: const Text('Update Target Steps',
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Current Steps: ${_stepData.currentSteps}',
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 12),
            _sheetField(
              controller: targetCtrl,
              label: 'Daily Target',
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
                  currentSteps: _stepData.currentSteps,
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

  // ─── Build ──────────────────────────────────────────────────────────────────

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
              GestureDetector(
                onTap: _showUpdateStepsDialog,
                child: SizedBox(
                  width: 130,
                  height: 130,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      const SizedBox(
                        width: 130,
                        height: 130,
                        child: CircularProgressIndicator(
                          value: 1.0,
                          strokeWidth: 12,
                          color: Color(0xFFE0DEF0),
                        ),
                      ),
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
                      'Tap ring to update target',
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
                      '${meal.mealTypeLabel}  •  ${meal.macroSummary}',
                      style: const TextStyle(
                          color: Colors.black45, fontSize: 12)),
                  trailing: Text('${meal.calories} kcal',
                      style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1A1A1A),
                          fontSize: 13)),
                  onLongPress: () => LongPressHandler.showMealOptions(
                    context,
                    meal,
                        () => widget.onMealRemoved(meal),
                  ),
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
                    '${activity.durationLabel}  •  ${activity.caloriesLabel} burned  •  ${activity.distanceLabel}  •  ${activity.paceLabel}',
                    style: const TextStyle(
                        color: Colors.black45, fontSize: 12),
                  ),
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

  // ─── Reusable Helpers ─────────────────────────────────────────────────────

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
    void Function(String)? onChanged,
  }) =>
      TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        validator: validator,
        onChanged: onChanged,
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

  String _formatNumber(int n) => n.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
}