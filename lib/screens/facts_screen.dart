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
  List<DailyFact> _facts = [];
  Map<String, Subject> _subjectMap = {};
  bool _isLoading = true;
  String? _errorMessage;

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
          _facts = [];
          _isLoading = false;
        });
        return;
      }

      final facts = await SupabaseService.instance.getFactsBySubjects(subjectIds);
      final subjects = await SupabaseService.instance.getSubjects();

      final subjectMap = {for (var s in subjects) s.id: s};

      setState(() {
        _facts = facts;
        _subjectMap = subjectMap;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load facts: $e';
        _isLoading = false;
      });
    }
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
              : _facts.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inbox_outlined,
                              size: 64, color: Colors.grey.shade400),
                          const SizedBox(height: 16),
                          Text(
                            'No facts available',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey.shade600,
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
                  : RefreshIndicator(
                      onRefresh: _loadFacts,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _facts.length,
                        itemBuilder: (context, index) {
                          final fact = _facts[index];
                          final subject = _subjectMap[fact.subjectId];

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (subject != null)
                                    Row(
                                      children: [
                                        Text(
                                          subject.icon,
                                          style: const TextStyle(fontSize: 24),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            subject.name,
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.blue,
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
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Added on ${fact.createdAt.toString().split(' ')[0]}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
