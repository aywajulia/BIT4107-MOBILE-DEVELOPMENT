/// nutrition_api_screen.dart
/// Location: lib/screens/nutrition_api_screen.dart
///
/// Week 5: Networking — Nutrition API Screen for Shredded Squad.
///
/// Connects to the Open Food Facts FREE public REST API.
/// No API key required.
///
/// API endpoint:
///   GET https://world.openfoodfacts.org/cgi/search.pl
///
/// Concepts covered:
///   • HTTP GET request using the http package
///   • JSON decoding using dart:convert
///   • Async / await for non-blocking network calls
///   • Error handling — timeout, no internet, bad response
///   • Displaying fetched records in a ListView
///
/// Add to pubspec.yaml:
///   http: ^1.2.1
library;

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../dashboard_model.dart';

// ─── Food model ───────────────────────────────────────────────────────────────

/// Represents a single food item returned from the API.
class FoodItem {
  final String name;       // product name
  final String brand;      // brand name
  final int calories;      // kcal per 100g
  final double protein;    // g per 100g
  final double carbs;      // g per 100g
  final double fat;        // g per 100g
  final String imageUrl;   // thumbnail from API

  const FoodItem({
    required this.name,
    required this.brand,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.imageUrl,
  });

  /// Parses one product JSON object from the API response into a FoodItem.
  factory FoodItem.fromJson(Map<String, dynamic> json) {
    // nutriments is a nested object inside each product
    final n = json['nutriments'] as Map<String, dynamic>? ?? {};

    return FoodItem(
      name: (json['product_name'] as String? ?? '').trim().isEmpty
          ? 'Unnamed Product'
          : json['product_name'] as String,
      brand: json['brands'] as String? ?? 'Unknown brand',
      calories: ((n['energy-kcal_100g'] as num?) ?? 0).round(),
      protein: ((n['proteins_100g']      as num?) ?? 0).toDouble(),
      carbs:   ((n['carbohydrates_100g'] as num?) ?? 0).toDouble(),
      fat:     ((n['fat_100g']           as num?) ?? 0).toDouble(),
      imageUrl: json['image_front_small_url'] as String? ?? '',
    );
  }

  /// Converts this food item into a MealEntry so the user can log it
  /// directly to the Dashboard meal list.
  MealEntry toMealEntry(String mealType) => MealEntry(
    id: DateTime.now().toIso8601String(),
    name: name,
    mealType: mealType,
    calories: calories,
    protein: protein,
    carbs: carbs,
    fat: fat,
    loggedAt: DateTime.now(),
  );
}

// ─── API service ──────────────────────────────────────────────────────────────

/// Handles all HTTP communication with the Open Food Facts API.
class _FoodApiService {
  static const _baseUrl =
      'https://world.openfoodfacts.org/cgi/search.pl';

  /// Sends a GET request and returns a list of matching FoodItems.
  ///
  /// Throws an Exception on network failure, timeout or bad status code.
  static Future<List<FoodItem>> search(String query) async {
    // Build the request URL with query parameters
    final uri = Uri.parse(_baseUrl).replace(queryParameters: {
      'search_terms': query,
      'search_simple': '1',
      'action':        'process',
      'json':          '1',
      'page_size':     '20',
      'fields':
      'product_name,brands,nutriments,image_front_small_url',
    });

    // Make the HTTP GET request — await pauses here without blocking the UI
    final response = await http
        .get(uri, headers: {'User-Agent': 'ShreddedSquad/1.0'})
        .timeout(const Duration(seconds: 10)); // timeout after 10s

    // Handle non-200 status codes
    if (response.statusCode != 200) {
      throw Exception(
          'Server returned ${response.statusCode}. Please try again.');
    }

    // Decode JSON — response.body is a raw String
    final Map<String, dynamic> body =
    jsonDecode(response.body) as Map<String, dynamic>;

    // Extract the products array
    final products =
        body['products'] as List<dynamic>? ?? [];

    // Map each JSON object to a FoodItem, skipping unnamed entries
    return products
        .whereType<Map<String, dynamic>>()
        .map(FoodItem.fromJson)
        .where((f) => f.name != 'Unnamed Product')
        .toList();
  }
}

// ─── Screen ───────────────────────────────────────────────────────────────────

class NutritionScreen extends StatefulWidget {
  /// Optional callback — lets the user log a food item to the Dashboard.
  final void Function(MealEntry)? onMealAdded;

  const NutritionScreen({super.key, this.onMealAdded});

  @override
  State<NutritionScreen> createState() => _NutritionScreenState();
}

class _NutritionScreenState extends State<NutritionScreen> {
  // ── State ──────────────────────────────────────────────────────────────────

  final _searchCtrl = TextEditingController();

  List<FoodItem> _results = [];   // items from the last API call
  bool _isLoading = false;        // true while HTTP request is in flight
  String? _error;                 // error message to display
  bool _hasSearched = false;      // false = show the initial prompt

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // ── API call ───────────────────────────────────────────────────────────────

  Future<void> _search(String query) async {
    if (query.trim().isEmpty) return;

    // Show spinner and clear previous results / errors
    setState(() {
      _isLoading  = true;
      _error      = null;
      _results    = [];
      _hasSearched = true;
    });

    try {
      // Await the HTTP GET — UI stays responsive during the wait
      final items = await _FoodApiService.search(query.trim());
      setState(() => _results = items);

    } on TimeoutException {
      // Network took too long
      setState(() =>
      _error = 'Request timed out.\nCheck your internet connection and try again.');

    } catch (e) {
      // Any other error — server error, no internet, parse failure
      setState(() =>
      _error = e.toString().replaceAll('Exception: ', ''));

    } finally {
      // Always hide the spinner
      setState(() => _isLoading = false);
    }
  }

  // ── Log food to dashboard ──────────────────────────────────────────────────

  /// Shows a meal type picker then passes the MealEntry to AppShell.
  void _logFood(FoodItem food) {
    if (widget.onMealAdded == null) return;

    String selectedType = 'Breakfast';

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Food name
              Text(
                food.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${food.calories} kcal per 100g',
                style: const TextStyle(
                    color: Colors.white54, fontSize: 13),
              ),
              const SizedBox(height: 20),

              // Meal type chips
              const Text('Log as:',
                  style: TextStyle(
                      color: Colors.white70, fontSize: 13)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                children: ['Breakfast', 'Lunch', 'Dinner', 'Snack']
                    .map((type) => ChoiceChip(
                  label: Text(type),
                  selected: selectedType == type,
                  onSelected: (_) =>
                      setSheet(() => selectedType = type),
                  selectedColor: const Color(0xFF4A4A4A),
                  backgroundColor: const Color(0xFF2C2C2C),
                  labelStyle: TextStyle(
                    color: selectedType == type
                        ? Colors.white
                        : Colors.white54,
                    fontSize: 12,
                  ),
                ))
                    .toList(),
              ),
              const SizedBox(height: 24),

              // Confirm button
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
                    Navigator.pop(ctx);
                    widget.onMealAdded!(food.toMealEntry(selectedType));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                            '${food.name} added to $selectedType!'),
                        backgroundColor: Colors.green.shade700,
                      ),
                    );
                  },
                  child: const Text(
                    'Add to Meal Log',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
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
              // ── Header ──────────────────────────────────────────────
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Nutrition',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    SizedBox(height: 2),
                    // API attribution
                    Text(
                      'Powered by Open Food Facts API',
                      style: TextStyle(
                          fontSize: 11, color: Colors.black38),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ── Search bar + button ──────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchCtrl,
                        onSubmitted: _search, // fires when user taps Enter
                        textInputAction: TextInputAction.search,
                        style: const TextStyle(
                            color: Color(0xFF1A1A1A), fontSize: 14),
                        decoration: InputDecoration(
                          hintText:
                          'Search food (e.g. chicken, banana, oats)',
                          hintStyle: const TextStyle(
                              color: Colors.black38, fontSize: 13),
                          prefixIcon: const Icon(Icons.search,
                              color: Colors.black45, size: 20),
                          // Clear button
                          suffixIcon: _searchCtrl.text.isNotEmpty
                              ? IconButton(
                            icon: const Icon(Icons.close,
                                color: Colors.black38, size: 18),
                            onPressed: () {
                              _searchCtrl.clear();
                              setState(() {
                                _results     = [];
                                _error       = null;
                                _hasSearched = false;
                              });
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
                    const SizedBox(width: 10),
                    // Search button
                    GestureDetector(
                      onTap: () => _search(_searchCtrl.text),
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A1A1A),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.search,
                            color: Colors.white, size: 22),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // ── Content area ─────────────────────────────────────────
              Expanded(
                child: _isLoading
                    ? _buildLoading()
                    : _error != null
                    ? _buildError()
                    : !_hasSearched
                    ? _buildPrompt()
                    : _results.isEmpty
                    ? _buildNoResults()
                    : _buildResults(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── State widgets ──────────────────────────────────────────────────────────

  /// Spinner shown while the HTTP request is in flight
  Widget _buildLoading() => const Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircularProgressIndicator(color: Color(0xFF1A1A1A)),
        SizedBox(height: 14),
        Text('Fetching from API...',
            style: TextStyle(color: Colors.black45, fontSize: 14)),
      ],
    ),
  );

  /// Error state with a retry button
  Widget _buildError() => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.wifi_off_outlined,
              size: 56, color: Colors.black26),
          const SizedBox(height: 16),
          Text(
            _error!,
            textAlign: TextAlign.center,
            style: const TextStyle(
                color: Colors.black54, fontSize: 14, height: 1.5),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1A1A1A),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => _search(_searchCtrl.text),
            child: const Text('Retry',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    ),
  );

  /// Initial state before the user has searched
  Widget _buildPrompt() => const Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.restaurant_menu_outlined,
            size: 64, color: Colors.black26),
        SizedBox(height: 16),
        Text(
          'Search any food item\nto see its nutritional data.',
          textAlign: TextAlign.center,
          style: TextStyle(
              color: Colors.black45, fontSize: 15, height: 1.5),
        ),
        SizedBox(height: 8),
        Text(
          'Data provided by Open Food Facts',
          style: TextStyle(color: Colors.black26, fontSize: 11),
        ),
      ],
    ),
  );

  /// Shown when the API returned zero products
  Widget _buildNoResults() => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.search_off, size: 56, color: Colors.black26),
        const SizedBox(height: 16),
        Text(
          'No results for "${_searchCtrl.text}".\nTry a different term.',
          textAlign: TextAlign.center,
          style: const TextStyle(
              color: Colors.black54, fontSize: 14, height: 1.5),
        ),
      ],
    ),
  );

  /// Scrollable list of food cards returned from the API
  Widget _buildResults() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // Result count label
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
        child: Text(
          '${_results.length} results for "${_searchCtrl.text}"',
          style: const TextStyle(
              color: Colors.black45, fontSize: 12),
        ),
      ),

      // Food item cards
      Expanded(
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          itemCount: _results.length,
          itemBuilder: (_, i) => _buildFoodCard(_results[i]),
        ),
      ),
    ],
  );

  // ── Food card ──────────────────────────────────────────────────────────────

  Widget _buildFoodCard(FoodItem food) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Top row: image + name + brand ─────────────────────────
          Row(
            children: [
              // Food image from API (falls back to icon)
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: food.imageUrl.isNotEmpty
                    ? Image.network(
                  food.imageUrl,
                  width: 48,
                  height: 48,
                  fit: BoxFit.cover,
                  // Show icon if image fails to load
                  errorBuilder: (_, __, ___) =>
                      _foodIcon(),
                )
                    : _foodIcon(),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      food.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      food.brand,
                      style: const TextStyle(
                          fontSize: 11, color: Colors.black45),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // ── Nutrition row ──────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(
                vertical: 8, horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _nutrient('Calories',
                    '${food.calories} kcal', true),
                _vDivider(),
                _nutrient('Protein',
                    '${food.protein.toStringAsFixed(1)}g', false),
                _vDivider(),
                _nutrient('Carbs',
                    '${food.carbs.toStringAsFixed(1)}g', false),
                _vDivider(),
                _nutrient(
                    'Fat', '${food.fat.toStringAsFixed(1)}g', false),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // ── Footer: per 100g label + Log button ───────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('per 100g',
                  style: TextStyle(
                      fontSize: 10, color: Colors.black38)),
              // Only show log button if the callback is connected
              if (widget.onMealAdded != null)
                GestureDetector(
                  onTap: () => _logFood(food),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A1A),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      '+ Log Meal',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Small helper widgets ───────────────────────────────────────────────────

  /// Fallback icon when no food image is available
  Widget _foodIcon() => Container(
    width: 48,
    height: 48,
    decoration: BoxDecoration(
      color: const Color(0xFF1A1A1A),
      borderRadius: BorderRadius.circular(10),
    ),
    child: const Icon(Icons.fastfood,
        color: Colors.white, size: 22),
  );

  /// One nutrient column in the nutrition row
  Widget _nutrient(String label, String value, bool bold) => Column(
    children: [
      Text(value,
          style: TextStyle(
              fontSize: 12,
              fontWeight:
              bold ? FontWeight.w800 : FontWeight.w600,
              color: const Color(0xFF1A1A1A))),
      const SizedBox(height: 2),
      Text(label,
          style: const TextStyle(
              fontSize: 10, color: Colors.black45)),
    ],
  );

  /// Thin vertical divider between nutrients
  Widget _vDivider() =>
      Container(width: 1, height: 28, color: Colors.black12);
}