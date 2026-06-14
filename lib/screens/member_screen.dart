import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../data/database_helper.dart';
import '../models/member_model.dart';

class MembersScreen extends StatefulWidget {
  const MembersScreen({super.key});

  @override
  State<MembersScreen> createState() => _MembersScreenState();
}

class _MembersScreenState extends State<MembersScreen> {
  // ─── State ────────────────────────────────────────────────────────────────

  /// Full list loaded from SQLite
  List<Member> _allMembers = [];

  /// Filtered list shown in the UI (updated by search)
  List<Member> _filteredMembers = [];

  /// True while the initial DB load is in progress
  bool _isLoading = true;

  /// Current search query
  String _searchQuery = '';

  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // ─── Data operations ──────────────────────────────────────────────────────

  /// Loads all members from SQLite and refreshes the UI.
  Future<void> _loadMembers() async {
    setState(() => _isLoading = true);
    final members = await DatabaseHelper.instance.getAllMembers();
    setState(() {
      _allMembers = members;
      _applySearch(_searchQuery);
      _isLoading = false;
    });
  }

  /// Filters _allMembers by the current search query.
  void _applySearch(String query) {
    _searchQuery = query;
    if (query.trim().isEmpty) {
      _filteredMembers = List.from(_allMembers);
    } else {
      final q = query.toLowerCase();
      _filteredMembers = _allMembers
          .where((m) =>
      m.name.toLowerCase().contains(q) ||
          m.email.toLowerCase().contains(q))
          .toList();
    }
  }

  /// Called when the search field changes — live filter.
  void _onSearchChanged(String query) {
    setState(() => _applySearch(query));
  }

  /// INSERT: saves a new member to SQLite then reloads.
  Future<void> _addMember(Member member) async {
    try {
      await DatabaseHelper.instance.insertMember(member);
      await _loadMembers();
      _showSnack('${member.name} added!', Colors.green);
    } catch (e) {
      _showSnack('Email already exists. Use a different email.', Colors.red);
    }
  }

  /// UPDATE: persists changes to an existing member then reloads.
  Future<void> _updateMember(Member member) async {
    await DatabaseHelper.instance.updateMember(member);
    await _loadMembers();
    _showSnack('${member.name} updated!', Colors.blue);
  }

  /// DELETE: removes a member by id then reloads.
  Future<void> _deleteMember(Member member) async {
    await DatabaseHelper.instance.deleteMember(member.id!);
    await _loadMembers();
    _showSnack('${member.name} deleted.', Colors.red.shade700);
  }

  void _showSnack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color),
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
        child: Column(
          children: [
            // ── Header ────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Members',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  // Member count badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A1A),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_allMembers.length} total',
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

            // ── Search bar ────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                controller: _searchCtrl,
                onChanged: _onSearchChanged,
                style: const TextStyle(
                    color: Color(0xFF1A1A1A), fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Search by name or email...',
                  hintStyle: const TextStyle(
                      color: Colors.black38, fontSize: 14),
                  prefixIcon: const Icon(Icons.search,
                      color: Colors.black45, size: 20),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? GestureDetector(
                    onTap: () {
                      _searchCtrl.clear();
                      _onSearchChanged('');
                    },
                    child: const Icon(Icons.close,
                        color: Colors.black45, size: 18),
                  )
                      : null,
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.8),
                  contentPadding: const EdgeInsets.symmetric(
                      vertical: 12, horizontal: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // ── Member list ───────────────────────────────────────────────
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredMembers.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                itemCount: _filteredMembers.length,
                itemBuilder: (_, i) =>
                    _buildMemberCard(_filteredMembers[i]),
              ),
            ),
          ],
        ),
      ),

      // ── FAB: Add member ─────────────────────────────────────────────────
      // Wrapped in Stack so FAB floats over the list
    );
  }

  // ─── Empty state ──────────────────────────────────────────────────────────

  Widget _buildEmptyState() {
    final isSearching = _searchQuery.isNotEmpty;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isSearching ? Icons.search_off : Icons.group_outlined,
            size: 64,
            color: Colors.black26,
          ),
          const SizedBox(height: 16),
          Text(
            isSearching
                ? 'No members match "$_searchQuery"'
                : 'No members yet.\nTap + to add the first one.',
            textAlign: TextAlign.center,
            style: const TextStyle(
                color: Colors.black45,
                fontSize: 15,
                height: 1.5),
          ),
        ],
      ),
    );
  }

  // ─── Member card ──────────────────────────────────────────────────────────

  Widget _buildMemberCard(Member member) {
    return Dismissible(
      // Swipe left to delete
      key: Key('member_${member.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.red.shade700,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete_outline,
            color: Colors.white, size: 28),
      ),
      confirmDismiss: (_) async {
        return await _confirmDelete(member);
      },
      onDismissed: (_) => _deleteMember(member),
      child: GestureDetector(
        onTap: () => _showMemberSheet(member: member), // tap to edit
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.88),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.black12),
          ),
          child: Row(
            children: [
              // Avatar circle with initials
              CircleAvatar(
                radius: 26,
                backgroundColor: const Color(0xFF1A1A1A),
                child: Text(
                  member.initials,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      member.name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      member.email,
                      style: const TextStyle(
                          fontSize: 12, color: Colors.black54),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _chip(member.activityLevel),
                        if (member.goal != null &&
                            member.goal!.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          _chip(member.goal!),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // Edit icon
              const Icon(Icons.chevron_right,
                  color: Colors.black38, size: 22),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFE8E8E8),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 10, color: Color(0xFF1A1A1A)),
      ),
    );
  }

  // ─── Delete confirmation ──────────────────────────────────────────────────

  Future<bool> _confirmDelete(Member member) async {
    return await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF2C2C2C),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Member',
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.w800)),
        content: Text(
          'Remove ${member.name} from Shredded Squad? This cannot be undone.',
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
    ) ??
        false;
  }

  // ─── Add / Edit bottom sheet ──────────────────────────────────────────────

  /// Opens a form bottom sheet.
  /// If [member] is provided it pre-fills for editing; otherwise it's a new entry.
  void _showMemberSheet({Member? member}) {
    final isEditing = member != null;

    // Controllers pre-filled with existing data when editing
    final nameCtrl =
    TextEditingController(text: isEditing ? member.name : '');
    final emailCtrl =
    TextEditingController(text: isEditing ? member.email : '');
    final phoneCtrl =
    TextEditingController(text: isEditing ? member.phone ?? '' : '');
    final heightCtrl = TextEditingController(
        text: isEditing && member.height != null
            ? member.height.toString()
            : '');
    final weightCtrl = TextEditingController(
        text: isEditing && member.weight != null
            ? member.weight.toString()
            : '');
    final targetCtrl = TextEditingController(
        text: isEditing && member.targetWeight != null
            ? member.targetWeight.toString()
            : '');
    final goalCtrl =
    TextEditingController(text: isEditing ? member.goal ?? '' : '');

    String activityLevel = isEditing ? member.activityLevel : 'Beginner';
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isEditing ? 'Edit Member' : 'Add Member',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      // Delete button when editing
                      if (isEditing)
                        GestureDetector(
                          onTap: () async {
                            Navigator.pop(ctx);
                            final confirm =
                            await _confirmDelete(member);
                            if (confirm) _deleteMember(member);
                          },
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.red.shade900,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.delete_outline,
                                color: Colors.white, size: 20),
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 20),
                  _sheetDivider('Personal Info'),
                  const SizedBox(height: 12),

                  // Name
                  _sheetField(
                    controller: nameCtrl,
                    label: 'Full name *',
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'Name is required'
                        : null,
                  ),
                  const SizedBox(height: 12),

                  // Email
                  _sheetField(
                    controller: emailCtrl,
                    label: 'Email *',
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Email is required';
                      }
                      if (!RegExp(r'^[^@]+@[^@]+\.[^@]+')
                          .hasMatch(v.trim())) {
                        return 'Enter a valid email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),

                  // Phone
                  _sheetField(
                    controller: phoneCtrl,
                    label: 'Phone (optional)',
                    keyboardType: TextInputType.phone,
                  ),

                  const SizedBox(height: 16),
                  _sheetDivider('Physical Metrics'),
                  const SizedBox(height: 12),

                  // Height / Weight row
                  Row(
                    children: [
                      Expanded(
                        child: _sheetField(
                          controller: heightCtrl,
                          label: 'Height (cm)',
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                                RegExp(r'[\d.]'))
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _sheetField(
                          controller: weightCtrl,
                          label: 'Weight (kg)',
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                                RegExp(r'[\d.]'))
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Target weight
                  _sheetField(
                    controller: targetCtrl,
                    label: 'Target weight (kg)',
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))
                    ],
                  ),

                  const SizedBox(height: 16),
                  _sheetDivider('Activity & Goal'),
                  const SizedBox(height: 12),

                  // Activity level chips
                  Wrap(
                    spacing: 8,
                    children: ['Beginner', 'Intermediate', 'Advanced']
                        .map((level) => ChoiceChip(
                      label: Text(level),
                      selected: activityLevel == level,
                      onSelected: (_) => setSheetState(
                              () => activityLevel = level),
                      selectedColor: const Color(0xFF4A4A4A),
                      backgroundColor: const Color(0xFF2C2C2C),
                      labelStyle: TextStyle(
                        color: activityLevel == level
                            ? Colors.white
                            : Colors.white54,
                        fontSize: 12,
                      ),
                    ))
                        .toList(),
                  ),
                  const SizedBox(height: 12),

                  // Goal
                  _sheetField(
                    controller: goalCtrl,
                    label: 'Goal (e.g. Lose weight, Build muscle)',
                  ),

                  const SizedBox(height: 24),

                  // Save button
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
                        if (!formKey.currentState!.validate()) return;

                        final now = DateTime.now().toIso8601String();

                        final updated = Member(
                          id: isEditing ? member.id : null,
                          name: nameCtrl.text.trim(),
                          email: emailCtrl.text.trim(),
                          phone: phoneCtrl.text.trim().isEmpty
                              ? null
                              : phoneCtrl.text.trim(),
                          height: double.tryParse(heightCtrl.text),
                          weight: double.tryParse(weightCtrl.text),
                          targetWeight:
                          double.tryParse(targetCtrl.text),
                          activityLevel: activityLevel,
                          joinDate:
                          isEditing ? member.joinDate : now,
                          goal: goalCtrl.text.trim().isEmpty
                              ? null
                              : goalCtrl.text.trim(),
                        );

                        Navigator.pop(ctx);

                        if (isEditing) {
                          _updateMember(updated);
                        } else {
                          _addMember(updated);
                        }
                      },
                      child: Text(
                        isEditing ? 'Save Changes' : 'Add Member',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700),
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

  // ─── Sheet helpers ────────────────────────────────────────────────────────

  Widget _sheetDivider(String label) {
    return Row(
      children: [
        Text(label,
            style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8)),
        const SizedBox(width: 8),
        const Expanded(child: Divider(color: Colors.white24, height: 1)),
      ],
    );
  }

  Widget _sheetField({
    required TextEditingController controller,
    required String label,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle:
        const TextStyle(color: Colors.white54, fontSize: 13),
        enabledBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.white24)),
        focusedBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.white, width: 1.5)),
        errorBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.redAccent)),
        focusedErrorBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.redAccent, width: 2)),
        errorStyle: const TextStyle(color: Colors.redAccent, fontSize: 11),
        contentPadding: const EdgeInsets.only(bottom: 4),
        isDense: true,
      ),
    );
  }
}

// ─── Floating action button wrapper ───────────────────────────────────────────

/// Wraps MembersScreen with a Scaffold so the FAB floats correctly.
class MembersTab extends StatefulWidget {
  const MembersTab({super.key});

  @override
  State<MembersTab> createState() => _MembersTabState();
}

class _MembersTabState extends State<MembersTab> {
  final _screenKey = GlobalKey<_MembersScreenState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: MembersScreen(key: _screenKey),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _screenKey.currentState?._showMemberSheet(),
        backgroundColor: const Color(0xFF1A1A1A),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}