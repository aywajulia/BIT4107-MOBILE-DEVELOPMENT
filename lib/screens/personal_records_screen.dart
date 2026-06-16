/// personal_records_screen.dart
/// Location: lib/screens/personal_records_screen.dart
///
/// Personal Records Manager for Shredded Squad — Week 4.
///
/// ALL state (records list + FAB + forms) lives in ONE StatefulWidget.
/// No GlobalKey, no callbacks between parent/child.
/// This is the simplest, most reliable architecture.
///
/// CRUD:
///   ADD    → FAB opens a bottom sheet form
///   READ   → list loaded from SQLite on init and after every change
///   UPDATE → tap a card to open the pre-filled form
///   DELETE → tap the delete icon on a card → confirmation dialog
///   SEARCH → search bar filters the list live

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../data/pr_database_helper.dart';
import '../models/personal_record_model.dart';

// Available units for the dropdown
const _units = ['kg', 'lbs', 'reps', 'min', 'sec', 'km', 'm'];

class PersonalRecordsScreen extends StatefulWidget {
  const PersonalRecordsScreen({super.key});

  @override
  State<PersonalRecordsScreen> createState() =>
      _PersonalRecordsScreenState();
}

class _PersonalRecordsScreenState
    extends State<PersonalRecordsScreen> {
  // ── State variables ────────────────────────────────────────────────────────

  List<PersonalRecord> _records = []; // current displayed list
  bool _isLoading = true;             // shows spinner on first load
  String _searchQuery = '';           // current search text
  final _searchCtrl = TextEditingController();

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _load(); // fetch all records from SQLite on startup
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // ── Data helpers ───────────────────────────────────────────────────────────

  /// Loads all records OR searches if a query is active.
  /// Called after every CRUD operation to keep the list fresh.
  Future<void> _load() async {
    setState(() => _isLoading = true);

    final results = _searchQuery.trim().isEmpty
        ? await PRDatabaseHelper.instance.getAllPRs()
        : await PRDatabaseHelper.instance.searchPRs(_searchQuery);

    // setState triggers a rebuild with the new list
    setState(() {
      _records = results;
      _isLoading = false;
    });
  }

  // ── CRUD operations ────────────────────────────────────────────────────────

  /// INSERT — saves a new record to SQLite then reloads the list
  Future<void> _insert(PersonalRecord pr) async {
    await PRDatabaseHelper.instance.insertPR(pr);
    await _load(); // reload so the new record appears immediately
    _snack('${pr.exercise} PR logged! 🏆', Colors.green.shade700);
  }

  /// UPDATE — saves changes to an existing record then reloads
  Future<void> _update(PersonalRecord pr) async {
    await PRDatabaseHelper.instance.updatePR(pr);
    await _load();
    _snack('${pr.exercise} updated!', Colors.blue.shade700);
  }

  /// DELETE — removes a record by id then reloads
  Future<void> _delete(PersonalRecord pr) async {
    await PRDatabaseHelper.instance.deletePR(pr.id!);
    await _load();
    _snack('${pr.exercise} deleted.', Colors.red.shade700);
  }

  void _snack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: color));
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Gradient background matching the app's design
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
              // ── Header ────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Personal\nRecords',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF1A1A1A),
                        height: 1.1,
                      ),
                    ),
                    // Count badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1A1A),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '🏆 ${_records.length} PRs',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ── Search bar ────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: (q) {
                    _searchQuery = q;
                    _load(); // re-query SQLite on every keystroke
                  },
                  style: const TextStyle(
                      color: Color(0xFF1A1A1A), fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Search exercise...',
                    hintStyle: const TextStyle(
                        color: Colors.black38, fontSize: 13),
                    prefixIcon: const Icon(Icons.search,
                        color: Colors.black45, size: 20),
                    // Clear button — shown only when there is text
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                      icon: const Icon(Icons.close,
                          color: Colors.black38, size: 18),
                      onPressed: () {
                        _searchCtrl.clear();
                        _searchQuery = '';
                        _load(); // reload full list
                      },
                    )
                        : null,
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.85),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 16),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // ── List area ─────────────────────────────────────────────
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _records.isEmpty
                    ? _buildEmpty()
                    : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(
                      20, 0, 20, 100),
                  itemCount: _records.length,
                  itemBuilder: (_, i) =>
                      _buildCard(_records[i]),
                ),
              ),
            ],
          ),
        ),
      ),

      // ── FAB — Add PR ──────────────────────────────────────────────────────
      // FAB is inside the same widget so _showForm() can call _insert()
      // directly without any GlobalKey or callback plumbing
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showForm(), // no argument = ADD mode
        backgroundColor: const Color(0xFF1A1A1A),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  // ── Empty state ────────────────────────────────────────────────────────────

  Widget _buildEmpty() => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('🏆', style: TextStyle(fontSize: 56)),
        const SizedBox(height: 16),
        Text(
          _searchQuery.isNotEmpty
              ? 'No results for "$_searchQuery"'
              : 'No records yet.\nTap + to log your first PR!',
          textAlign: TextAlign.center,
          style: const TextStyle(
              color: Colors.black45, fontSize: 15, height: 1.5),
        ),
      ],
    ),
  );

  // ── Record card ────────────────────────────────────────────────────────────

  Widget _buildCard(PersonalRecord pr) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black12),
      ),
      child: Row(
        children: [
          // Trophy icon
          const CircleAvatar(
            radius: 24,
            backgroundColor: Color(0xFF1A1A1A),
            child: Text('🏆', style: TextStyle(fontSize: 18)),
          ),

          const SizedBox(width: 14),

          // Exercise name + date + notes
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pr.exercise,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  pr.date,
                  style: const TextStyle(
                      fontSize: 11, color: Colors.black45),
                ),
                if (pr.notes != null && pr.notes!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    pr.notes!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 11,
                        color: Colors.black38,
                        fontStyle: FontStyle.italic),
                  ),
                ],
              ],
            ),
          ),

          // PR value — large on the right
          Text(
            pr.displayValue,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: Color(0xFF1A1A1A),
            ),
          ),

          const SizedBox(width: 8),

          // Action buttons — edit and delete
          Column(
            children: [
              // Edit button — opens form in UPDATE mode
              GestureDetector(
                onTap: () => _showForm(pr: pr),
                child: const Icon(Icons.edit_outlined,
                    size: 20, color: Colors.black45),
              ),
              const SizedBox(height: 8),
              // Delete button — shows confirmation dialog
              GestureDetector(
                onTap: () => _confirmDelete(pr),
                child: const Icon(Icons.delete_outline,
                    size: 20, color: Colors.redAccent),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Delete confirmation dialog ─────────────────────────────────────────────

  Future<void> _confirmDelete(PersonalRecord pr) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF2C2C2C),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete PR',
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.w800)),
        content: Text(
          'Delete your ${pr.exercise} record of ${pr.displayValue}?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel',
                style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) _delete(pr);
  }

  // ── Add / Edit form (bottom sheet) ────────────────────────────────────────

  /// Opens the form bottom sheet.
  /// [pr] == null → ADD mode (blank form)
  /// [pr] != null → EDIT mode (pre-filled form)
  void _showForm({PersonalRecord? pr}) {
    final isEditing = pr != null;

    // Pre-fill controllers with existing data when editing
    final exerciseCtrl =
    TextEditingController(text: isEditing ? pr.exercise : '');
    final valueCtrl = TextEditingController(
        text: isEditing
            ? (pr.value % 1 == 0
            ? pr.value.toInt().toString()
            : pr.value.toString())
            : '');
    final dateCtrl = TextEditingController(
        text: isEditing ? pr.date : _todayString());
    final notesCtrl =
    TextEditingController(text: isEditing ? pr.notes ?? '' : '');

    // Unit dropdown value
    String selectedUnit =
    isEditing ? pr.unit : _units.first;

    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // allows sheet to grow with keyboard
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        // StatefulBuilder lets the unit dropdown update inside the sheet
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            // Push the form up when the keyboard appears
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Sheet title
                  Text(
                    isEditing ? 'Edit PR' : 'Log New PR 🏆',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── Exercise name ──────────────────────────────────
                  _field(
                    controller: exerciseCtrl,
                    label: 'Exercise *',
                    hint: 'e.g. Bench Press, 5km Run',
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'Enter exercise name'
                        : null,
                  ),

                  const SizedBox(height: 14),

                  // ── Value + Unit row ───────────────────────────────
                  Row(
                    children: [
                      // Numeric value
                      Expanded(
                        flex: 3,
                        child: _field(
                          controller: valueCtrl,
                          label: 'Value *',
                          hint: 'e.g. 80',
                          keyboardType:
                          const TextInputType.numberWithOptions(
                              decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                                RegExp(r'[\d.]'))
                          ],
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Enter value';
                            }
                            if (double.tryParse(v) == null) {
                              return 'Numbers only';
                            }
                            return null;
                          },
                        ),
                      ),

                      const SizedBox(width: 14),

                      // Unit dropdown
                      Expanded(
                        flex: 2,
                        child: DropdownButtonFormField<String>(
                          initialValue: selectedUnit,
                          dropdownColor: const Color(0xFF2C2C2C),
                          style: const TextStyle(
                              color: Colors.white, fontSize: 14),
                          decoration: const InputDecoration(
                            labelText: 'Unit',
                            labelStyle: TextStyle(
                                color: Colors.white54, fontSize: 13),
                            enabledBorder: UnderlineInputBorder(
                                borderSide: BorderSide(
                                    color: Colors.white24)),
                            focusedBorder: UnderlineInputBorder(
                                borderSide: BorderSide(
                                    color: Colors.white,
                                    width: 1.5)),
                            isDense: true,
                            contentPadding:
                            EdgeInsets.only(bottom: 4),
                          ),
                          items: _units
                              .map((u) => DropdownMenuItem(
                            value: u,
                            child: Text(u,
                                style: const TextStyle(
                                    color: Colors.white)),
                          ))
                              .toList(),
                          onChanged: (v) =>
                              setSheet(() => selectedUnit = v!),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // ── Date ────────────────────────────────────────────
                  _field(
                    controller: dateCtrl,
                    label: 'Date *',
                    hint: 'YYYY-MM-DD',
                    keyboardType: TextInputType.datetime,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Enter a date';
                      }
                      // Basic format check
                      if (!RegExp(r'^\d{4}-\d{2}-\d{2}$')
                          .hasMatch(v.trim())) {
                        return 'Use format YYYY-MM-DD';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 14),

                  // ── Notes ───────────────────────────────────────────
                  _field(
                    controller: notesCtrl,
                    label: 'Notes (optional)',
                    hint: 'e.g. Felt strong, new max',
                  ),

                  const SizedBox(height: 24),

                  // ── Save button ─────────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3A3A3A),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () {
                        // Validate all required fields first
                        if (!formKey.currentState!.validate()) return;

                        // Build the PersonalRecord object from form values
                        final record = PersonalRecord(
                          id: isEditing ? pr.id : null,
                          exercise: exerciseCtrl.text.trim(),
                          value: double.parse(valueCtrl.text.trim()),
                          unit: selectedUnit,
                          date: dateCtrl.text.trim(),
                          notes: notesCtrl.text.trim().isEmpty
                              ? null
                              : notesCtrl.text.trim(),
                        );

                        // Close the sheet first
                        Navigator.pop(ctx);

                        // Then call insert or update
                        if (isEditing) {
                          _update(record);
                        } else {
                          _insert(record);
                        }
                      },
                      child: Text(
                        isEditing ? 'Save Changes' : 'Log PR',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
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

  // ── Shared form field widget ───────────────────────────────────────────────

  /// Underline text field styled for the dark bottom sheet.
  Widget _field({
    required TextEditingController controller,
    required String label,
    String? hint,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) =>
      TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        validator: validator,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          labelStyle:
          const TextStyle(color: Colors.white54, fontSize: 13),
          hintStyle:
          const TextStyle(color: Colors.white24, fontSize: 12),
          enabledBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white24)),
          focusedBorder: const UnderlineInputBorder(
              borderSide:
              BorderSide(color: Colors.white, width: 1.5)),
          errorBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.redAccent)),
          focusedErrorBorder: const UnderlineInputBorder(
              borderSide:
              BorderSide(color: Colors.redAccent, width: 2)),
          errorStyle:
          const TextStyle(color: Colors.redAccent, fontSize: 11),
          contentPadding: const EdgeInsets.only(bottom: 4),
          isDense: true,
        ),
      );

  // ── Utility ───────────────────────────────────────────────────────────────

  /// Returns today's date as a YYYY-MM-DD string.
  String _todayString() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }
}