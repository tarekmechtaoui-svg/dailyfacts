import 'package:flutter/material.dart';
import '../models/subject.dart';
import '../services/supabase_service.dart';
import '../widgets/subject_card.dart';

class SubjectsScreen extends StatefulWidget {
  const SubjectsScreen({super.key});

  @override
  State<SubjectsScreen> createState() => _SubjectsScreenState();
}

class _SubjectsScreenState extends State<SubjectsScreen> {
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

    try {
      if (_selectedSubjectIds.contains(subjectId)) {
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
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _handleSignOut() async {
    try {
      await SupabaseService.instance.signOut();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error signing out: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Choose Your Interests',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _handleSignOut,
            tooltip: 'Sign Out',
          ),
        ],
      ),
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
                            'Select subjects to receive daily facts',
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
