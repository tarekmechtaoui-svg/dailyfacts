import 'package:flutter/material.dart';
import '../models/subject.dart';
import '../services/supabase_service.dart';
import '../widgets/subject_card.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  List<Subject> _subjects = [];
  Set<String> _selectedSubjectIds = {};
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = await SupabaseService.instance.getCurrentUser();
      if (user == null) return;

      final subjects = await SupabaseService.instance.getSubjects();
      final userSubscriptions =
          await SupabaseService.instance.getUserSubscriptions(user.id);

      setState(() {
        _subjects = subjects;
        _selectedSubjectIds =
            userSubscriptions.map((us) => us.subjectId).toSet();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load subjects: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleSubject(String subjectId) async {
    final user = await SupabaseService.instance.getCurrentUser();
    if (user == null) return;

    final isCurrentlySelected = _selectedSubjectIds.contains(subjectId);
    final subject = _subjects.firstWhere((s) => s.id == subjectId);

    try {
      if (isCurrentlySelected) {
        await SupabaseService.instance
            .unsubscribeFromSubject(user.id, subjectId);
        setState(() {
          _selectedSubjectIds.remove(subjectId);
        });
      } else {
        await SupabaseService.instance.subscribeToSubject(user.id, subjectId);
        setState(() {
          _selectedSubjectIds.add(subjectId);
        });

        _showConfirmationPopup(subject);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  void _showConfirmationPopup(Subject subject) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.green.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle,
                size: 48,
                color: Colors.green.shade600,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Category Added!',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: Theme.of(context).textTheme.bodyMedium,
                children: [
                  const TextSpan(text: 'You will receive daily facts about '),
                  TextSpan(
                    text: subject.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text('Got It'),
            ),
          ),
        ],
      ),
    );
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
                        onPressed: _loadData,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24.0),
                      color: Colors.blue.shade600,
                      child: Column(
                        children: [
                          const Text(
                            'Select categories to receive daily facts',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${_selectedSubjectIds.length} selected',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: _loadData,
                        child: GridView.builder(
                          padding: const EdgeInsets.all(16.0),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: 0.85,
                          ),
                          itemCount: _subjects.length,
                          itemBuilder: (context, index) {
                            final subject = _subjects[index];
                            return SubjectCard(
                              subject: subject,
                              isSelected:
                                  _selectedSubjectIds.contains(subject.id),
                              onTap: () => _toggleSubject(subject.id),
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
