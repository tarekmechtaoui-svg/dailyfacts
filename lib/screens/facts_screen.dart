import 'package:flutter/material.dart';
import '../models/daily_fact.dart';
import '../models/subject.dart';
import '../services/supabase_service.dart';

class FactsScreen extends StatefulWidget {
  const FactsScreen({super.key});

  @override
  State<FactsScreen> createState() => _FactsScreenState();
}

class _FactsScreenState extends State<FactsScreen> {
  List<DailyFact> _allFacts = [];
  List<DailyFact> _filteredFacts = [];
  Map<String, Subject> _subjectMap = {};
  bool _isLoading = true;
  String? _errorMessage;

  String? _selectedCategoryId;
  DateTimeRange? _selectedDateRange;

  @override
  void initState() {
    super.initState();
    _loadFacts();
  }

  Future<void> _loadFacts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = await SupabaseService.instance.getCurrentUser();
      if (user == null) return;

      final userSubscriptions =
          await SupabaseService.instance.getUserSubscriptions(user.id);
      final subjectIds = userSubscriptions.map((us) => us.subjectId).toList();

      if (subjectIds.isEmpty) {
        setState(() {
          _allFacts = [];
          _filteredFacts = [];
          _isLoading = false;
        });
        return;
      }

      final facts = await SupabaseService.instance.getFactsBySubjects(subjectIds);
      final subjects = await SupabaseService.instance.getSubjects();

      final subjectMap = {for (var s in subjects) s.id: s};

      setState(() {
        _allFacts = facts;
        _subjectMap = subjectMap;
        _selectedCategoryId = null;
        _selectedDateRange = null;
        _isLoading = false;
        _applyFilters();
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load facts: $e';
        _isLoading = false;
      });
    }
  }

  void _applyFilters() {
    _filteredFacts = _allFacts.where((fact) {
      bool matchesCategory = _selectedCategoryId == null ||
          fact.subjectId == _selectedCategoryId;

      bool matchesDate = _selectedDateRange == null ||
          (fact.createdAt.isAfter(_selectedDateRange!.start) &&
              fact.createdAt.isBefore(_selectedDateRange!.end.add(const Duration(days: 1))));

      return matchesCategory && matchesDate;
    }).toList();
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _selectedDateRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF3B82F6),
              surface: Color(0xFF1F2937),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDateRange = picked;
        _applyFilters();
      });
    }
  }

  void _clearFilters() {
    setState(() {
      _selectedCategoryId = null;
      _selectedDateRange = null;
      _applyFilters();
    });
  }

  List<Subject> _getSubscribedSubjects() {
    final subscribedIds = _allFacts
        .map((f) => f.subjectId)
        .toSet();
    return _subjectMap.entries
        .where((e) => subscribedIds.contains(e.key))
        .map((e) => e.value)
        .toList()
        ..sort((a, b) => a.name.compareTo(b.name));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline,
                          size: 64, color: Colors.red.shade300),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage!,
                        style: TextStyle(color: Colors.red.shade700),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadFacts,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _allFacts.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inbox_outlined,
                              size: 64, color: Colors.grey.shade600),
                          const SizedBox(height: 16),
                          Text(
                            'No facts available',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey.shade300,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Select categories to receive daily facts',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    )
                  : Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Filter Facts',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 12),
                              DropdownMenu<String?>(
                                width: MediaQuery.of(context).size.width - 32,
                                initialSelection: _selectedCategoryId,
                                onSelected: (value) {
                                  setState(() {
                                    _selectedCategoryId = value;
                                    _applyFilters();
                                  });
                                },
                                dropdownMenuEntries: [
                                  const DropdownMenuEntry<String?>(
                                    value: null,
                                    label: 'All Categories',
                                  ),
                                  ..._getSubscribedSubjects().map(
                                    (subject) => DropdownMenuEntry<String?>(
                                      value: subject.id,
                                      label: '${subject.icon} ${subject.name}',
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: _selectDateRange,
                                      icon: const Icon(Icons.calendar_today),
                                      label: Text(
                                        _selectedDateRange == null
                                            ? 'Select Date Range'
                                            : '${_selectedDateRange!.start.toString().split(' ')[0]} - ${_selectedDateRange!.end.toString().split(' ')[0]}',
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                  if (_selectedCategoryId != null ||
                                      _selectedDateRange != null) ...[
                                    const SizedBox(width: 8),
                                    IconButton(
                                      onPressed: _clearFilters,
                                      icon: const Icon(Icons.clear),
                                      tooltip: 'Clear Filters',
                                    ),
                                  ],
                                ],
                              ),
                              if (_selectedCategoryId != null ||
                                  _selectedDateRange != null) ...[
                                const SizedBox(height: 8),
                                Text(
                                  'Results: ${_filteredFacts.length} facts',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        Expanded(
                          child: _filteredFacts.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.filter_list_off,
                                          size: 64,
                                          color: Colors.grey.shade600),
                                      const SizedBox(height: 16),
                                      Text(
                                        'No facts match your filters',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.grey.shade400,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : RefreshIndicator(
                                  onRefresh: _loadFacts,
                                  child: ListView.builder(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    itemCount: _filteredFacts.length,
                                    itemBuilder: (context, index) {
                                      final fact = _filteredFacts[index];
                                      final subject = _subjectMap[fact.subjectId];

                                      return Card(
                                        margin: const EdgeInsets.only(bottom: 12),
                                        child: Padding(
                                          padding: const EdgeInsets.all(16),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              if (subject != null)
                                                Row(
                                                  children: [
                                                    Text(
                                                      subject.icon,
                                                      style: const TextStyle(
                                                          fontSize: 24),
                                                    ),
                                                    const SizedBox(width: 12),
                                                    Expanded(
                                                      child: Text(
                                                        subject.name,
                                                        style: const TextStyle(
                                                          fontSize: 14,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: Color(
                                                              0xFF3B82F6),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                )
                                              else
                                                const SizedBox.shrink(),
                                              if (subject != null)
                                                const SizedBox(height: 12),
                                              Text(
                                                fact.factText,
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  height: 1.6,
                                                  color: Colors.white70,
                                                ),
                                              ),
                                              const SizedBox(height: 12),
                                              Text(
                                                'Added on ${fact.createdAt.toString().split(' ')[0]}',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey.shade500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                        ),
                      ],
                    ),
    );
  }
}
