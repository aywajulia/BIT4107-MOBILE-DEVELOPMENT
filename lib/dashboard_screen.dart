/// dashboard_screen.dart
/// This screen  displays three core sections:
///   1. Daily Progress Card – shows a live step count from the device pedometer,
///      a progress ring, and total calories burned from activities.
///   2. Nutrition Card – lists all logged meals with their calories,
///      provides a "Log Meal" button that auto-calculates total calories
///      based on quantity (grams) and calories per 100g.
///   3. Activity Card – lists all logged activities with their duration and
///      calories burned, provides a "Log Activity" button that auto-calculates
///      calories burned using the MET formula: MET × weight(kg) × hours.
///
/// All data is passed from the parent AppShell widget via constructor,
/// and callbacks are used to notify AppShell of changes (which then persist to SQLite).

library;

// ── Imports ────────────────────────────────────────────────────────────────────
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // for input formatters (number-only fields)
import 'package:shared_preferences/shared_preferences.dart'; // to get the current user's UID
import '../meal_entry.dart';                       // extended MealEntry model
import '../dashboard_model.dart';  // ActivityEntry, StepData (hide old MealEntry)
import '../activity_calorie_service.dart';        // MET calculation for activities
import '../database_helper.dart';                 // to fetch user weight from SQLite
import '../step_service.dart';                    // StepService for live pedometer stream

// ─── Main Widget ──────────────────────────────────────────────────────────────

/// The DashboardScreen is a stateful widget because it listens to:
///   - The pedometer stream (live step updates)
///   - User weight loading (async from database)
///   - Bottom sheet state (logging meals/activities)
class DashboardScreen extends StatefulWidget {
  // ── Data and callbacks passed from AppShell ──────────────────────────────

  /// The current list of logged meals (displayed in the Nutrition card).
  final List<MealEntry> meals;

  /// The current list of logged activities (displayed in the Activity card).
  final List<ActivityEntry> activities;

  /// Callback to add a new meal (triggers SQLite insert in AppShell).
  final void Function(MealEntry) onMealAdded;

  /// Callback to remove a meal by its ID (triggers SQLite delete in AppShell).
  final void Function(MealEntry) onMealRemoved;

  /// Callback to add a new activity (triggers SQLite insert in AppShell).
  final void Function(ActivityEntry) onActivityAdded;

  /// Callback to remove an activity by its ID (triggers SQLite delete in AppShell).
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

// ─── State Class ──────────────────────────────────────────────────────────────

class _DashboardScreenState extends State<DashboardScreen> {
  // ─── Step Data ────────────────────────────────────────────────────────────

  /// Holds the current step count and the user's daily target.
  /// Updated live whenever the pedometer emits a new value.
  StepData _stepData = const StepData(currentSteps: 0, targetSteps: 10000);

  /// Reference to the step stream subscription – kept for potential cancellation,
  /// though broadcast streams don't need explicit cancellation.
  Stream<int>? _stepStream;

  // ─── User Weight ───────────────────────────────────────────────────────────

  /// The user's weight in kilograms, loaded from SQLite on startup.
  /// Used in activity calorie calculations (MET formula).
  /// Defaults to 70.0 kg if not found or during loading.
  double _userWeightKg = 70.0;

  // ─── Lifecycle ──────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    // Load user weight from SQLite and start listening to pedometer.
    _loadUserWeight();
    _initStepListener();
  }

  @override
  void dispose() {
    // Nullify the stream reference to allow garbage collection.
    _stepStream = null;
    super.dispose();
  }

  // ─── Data Loading ───────────────────────────────────────────────────────────

  /// Fetches the logged‑in user's weight from the SQLite 'users' table.
  ///
  /// Steps:
  ///   1. Get the user's UID from SharedPreferences (stored during login).
  ///   2. Query the database for that user's record.
  ///   3. If a weight exists, parse it and update `_userWeightKg`.
  ///   4. If anything fails, keep the default 70.0 kg – no UI crash.
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
      // Silently fall back to default weight – the app stays functional.
    }
  }

  /// Starts listening to the pedometer stream and updates the UI on each step event.
  ///
  /// The stream emits a new integer step count whenever the device's step sensor
  /// detects movement. We update `_stepData` with the new count, keeping the
  /// user's target unchanged.
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
      // If the sensor is unavailable (e.g., emulator), log it but don't crash.
      // debugPrint is used so this is stripped in release builds.
      debugPrint('Step sensor error: $error');
    });
  }

  // ─── Computed Totals ──────────────────────────────────────────────────────

  /// Sums the calories of all meals in the current list.
  int get _totalMealCalories =>
      widget.meals.fold(0, (sum, m) => sum + m.calories);

  /// Sums the calories burned from all activities in the current list.
  int get _totalCaloriesBurned =>
      widget.activities.fold(0, (sum, a) => sum + a.caloriesBurned);

  // ─── Log Meal Bottom Sheet ────────────────────────────────────────────────────

  /// Opens a modal bottom sheet that allows the user to manually log a meal.
  ///
  /// The user enters:
  ///   - Food name (text)
  ///   - Calories per 100g (number) – from a label or estimate
  ///   - Quantity in grams (number)
  ///
  /// The total calories are calculated using the formula:
  ///   totalCalories = (caloriesPer100g / 100) × quantityInGrams
  ///
  /// On save, a MealEntry is created and passed to `onMealAdded`,
  /// which triggers AppShell to persist it to SQLite.
  void _showLogMealSheet() {
    // Controllers for the three input fields.
    final nameCtrl = TextEditingController();
    final calPer100Ctrl = TextEditingController();
    final quantityCtrl = TextEditingController();

    // Form key to validate all fields together.
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // allows the sheet to expand when the keyboard appears
      backgroundColor: const Color(0xFF1E1E1E), // dark theme matching the app
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        // StatefulBuilder is used so only the sheet rebuilds when the user types,
        // not the entire DashboardScreen.
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
                      // ── Sheet Title ──────────────────────────────────
                      const Text(
                        'Log a Meal',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 20),

                      // ── Food Name ────────────────────────────────────
                      _sheetField(
                        controller: nameCtrl,
                        label: 'Food Name',
                        validator: (v) =>
                        v == null || v.isEmpty ? 'Enter a food name' : null,
                      ),
                      const SizedBox(height: 12),

                      // ── Calories per 100g ────────────────────────────
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
                        // onChanged triggers a rebuild of the preview text below.
                        onChanged: (_) => setSheetState(() {}),
                      ),
                      const SizedBox(height: 12),

                      // ── Quantity in grams ────────────────────────────
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

                      // ── Live Total Calories Preview ───────────────────
                      // This Builder rebuilds every time the text fields change
                      // because the onChanged callbacks call setSheetState.
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

                      // ── Save Button ───────────────────────────────────
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
                            // Validate all fields before proceeding.
                            if (!formKey.currentState!.validate()) return;

                            // Calculate total calories from the inputs.
                            final calPer100 =
                                double.tryParse(calPer100Ctrl.text) ?? 0;
                            final qty =
                                double.tryParse(quantityCtrl.text) ?? 0;
                            final totalCal = (calPer100 / 100) * qty;

                            // Create a MealEntry with the calculated calories.
                            // mealType is set to 'Custom' because this is a manual log.
                            final meal = MealEntry(
                              id: DateTime.now().toIso8601String(),
                              name: nameCtrl.text.trim(),
                              mealType: 'Custom',
                              calories: totalCal.round(),
                              protein: 0, // simplified; we only store calories
                              carbs: 0,
                              fat: 0,
                              loggedAt: DateTime.now(),
                              quantity: qty,
                              source: 'custom',
                            );

                            // Pass the meal up to AppShell to insert into SQLite.
                            widget.onMealAdded(meal);

                            Navigator.pop(context); // close the sheet

                            // Show a confirmation snackbar.
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

  // ─── Log Activity Bottom Sheet ─────────────────────────────────────────────

  /// Opens a modal bottom sheet to log an activity with auto‑calculated calorie burn.
  ///
  /// The user:
  ///   - Selects an activity type from a dropdown (which determines the MET value)
  ///   - Enters a custom name for the session
  ///   - Enters the duration in minutes
  ///
  /// Calories burned are calculated using the MET formula:
  ///   Calories = MET × weight(kg) × duration(hours)
  ///
  /// The user's weight (`_userWeightKg`) is used (loaded from SQLite at startup).
  void _showLogActivitySheet() {
    final nameCtrl = TextEditingController();
    final durationCtrl = TextEditingController();
    String selectedActivity = 'Running (jog)'; // default selection
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
                      // ── Sheet Title ──────────────────────────────────
                      const Text(
                        'Log an Activity',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 20),

                      // ── Activity Name ────────────────────────────────
                      _sheetField(
                        controller: nameCtrl,
                        label: 'Activity Name',
                        validator: (v) => v == null || v.isEmpty
                            ? 'Enter an activity name'
                            : null,
                      ),
                      const SizedBox(height: 12),

                      // ── Activity Type Dropdown (MET selection) ───────
                      // This dropdown uses the MET map from ActivityCalorieService.
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

                      // ── Duration ──────────────────────────────────────
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

                      // ── Live Calories Burned Preview ──────────────────
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

                      // ── Save Button ───────────────────────────────────
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

                            final minutes =
                                int.tryParse(durationCtrl.text) ?? 0;
                            final calories =
                            ActivityCalorieService.calculateCalories(
                                selectedActivity, _userWeightKg, minutes);

                            // Create a new ActivityEntry with the calculated calories.
                            final activity = ActivityEntry(
                              id: DateTime.now().toIso8601String(),
                              name: nameCtrl.text.trim(),
                              caloriesBurned: calories.round(),
                              durationMinutes: minutes,
                              loggedAt: DateTime.now(),
                            );

                            widget.onActivityAdded(activity);
                            Navigator.pop(context);

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('${activity.name} logged!'),
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

  // ─── Update Target Steps Dialog ────────────────────────────────────────────

  /// Shows a dialog that allows the user to change their daily step target.
  /// The current target is pre‑filled, and the current steps are shown for context.
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
            // Show current steps so the user can decide a realistic target.
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
              _buildDailyProgressCard(), // steps + total burned
              const SizedBox(height: 16),
              _buildNutritionCard(), // meals list + log meal button
              const SizedBox(height: 16),
              _buildActivityCard(), // activities list + log activity button
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Daily Progress Card ──────────────────────────────────────────────────

  /// Builds the card showing the step progress ring and total calories burned.
  ///
  /// The ring is interactive – tapping it opens the target update dialog.
  /// The card also shows today's steps, target, remaining steps, and total burned.
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
              // ── Step Ring ─────────────────────────────────────────────
              // Tapping the ring opens the target update dialog.
              GestureDetector(
                onTap: _showUpdateStepsDialog,
                child: SizedBox(
                  width: 130,
                  height: 130,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Background ring (100% grey – always full).
                      const SizedBox(
                        width: 130,
                        height: 130,
                        child: CircularProgressIndicator(
                          value: 1.0,
                          strokeWidth: 12,
                          color: Color(0xFFE0DEF0),
                        ),
                      ),
                      // Progress ring (black, value = current / target).
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
                      // Centre text: percentage and "Steps".
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

              // ── Step Stats ─────────────────────────────────────────────
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

          // ── Total Calories Burned ─────────────────────────────────────
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

  /// Builds the card that lists logged meals and provides the "Log Meal" button.
  ///
  /// If there are no meals, it shows a placeholder message.
  /// Each meal shows its name, meal type (e.g., Breakfast), macro summary,
  /// and calories. Long‑pressing a meal triggers deletion (via `onMealRemoved`).
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
              // Show total calories if there are meals.
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

          // ── Meal List ──────────────────────────────────────────────────
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
                  // Long press to delete the meal – triggers the callback.
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

  /// Builds the card that lists logged activities and provides the "Log Activity" button.
  ///
  /// If there are no activities, it shows a placeholder message.
  /// Each activity shows its name, duration, and calories burned.
  /// Long‑pressing an activity triggers deletion (via `onActivityRemoved`).
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

          // ── Activity List ──────────────────────────────────────────────
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
                  // Long press to delete the activity.
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

  // ─── Reusable UI Helpers ──────────────────────────────────────────────────

  /// A styled card container with a white background, rounded corners, and a border.
  /// Used consistently across all three sections for a clean visual hierarchy.
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

  /// A dark button used for primary actions inside cards (e.g., "Log Meal", "Log Activity").
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

  /// A row showing a label (left) and a value (right) – used for step stats.
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

  /// A reusable, dark‑themed text field for use in bottom sheets and dialogs.
  ///
  /// Supports:
  ///   - Custom keyboard types (number, text, etc.)
  ///   - Input formatters (e.g., digits‑only)
  ///   - Validation
  ///   - onChanged callback (used to trigger preview updates)
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

  /// Formats an integer with thousand separators (e.g., 10000 → "10,000").
  String _formatNumber(int n) => n.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
}