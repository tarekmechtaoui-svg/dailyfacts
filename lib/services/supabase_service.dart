import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/subject.dart';
import '../models/user_subject.dart';
import '../models/daily_fact.dart';

class SupabaseService {
  static SupabaseService? _instance;
  static SupabaseClient get client => Supabase.instance.client;

  SupabaseService._();

  static SupabaseService get instance {
    _instance ??= SupabaseService._();
    return _instance!;
  }

  static Future<void> initialize(String url, String anonKey) async {
    await Supabase.initialize(
      url: url,
      anonKey: anonKey,
    );
  }

  Future<List<Subject>> getSubjects() async {
    final response = await client.from('subjects').select().order('name');
    return (response as List).map((json) => Subject.fromJson(json)).toList();
  }

  Future<List<UserSubject>> getUserSubscriptions(String userId) async {
    final response = await client
        .from('user_subjects')
        .select()
        .eq('user_id', userId)
        .eq('subscribed', true);
    return (response as List)
        .map((json) => UserSubject.fromJson(json))
        .toList();
  }

  Future<void> subscribeToSubject(String userId, String subjectId) async {
    await client.from('user_subjects').upsert({
      'user_id': userId,
      'subject_id': subjectId,
      'subscribed': true,
    });
  }

  Future<void> unsubscribeFromSubject(String userId, String subjectId) async {
    await client
        .from('user_subjects')
        .update({'subscribed': false})
        .eq('user_id', userId)
        .eq('subject_id', subjectId);
  }

  Future<List<DailyFact>> getFactsForSubject(String subjectId) async {
    final response = await client
        .from('daily_facts')
        .select()
        .eq('subject_id', subjectId)
        .order('created_at', ascending: false);
    return (response as List).map((json) => DailyFact.fromJson(json)).toList();
  }

  Future<void> saveOneSignalPlayerId(String userId, String playerId) async {
    await client.from('user_notifications').upsert({
      'user_id': userId,
      'onesignal_player_id': playerId,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  Future<User?> getCurrentUser() async {
    return client.auth.currentUser;
  }

  Future<AuthResponse> signUp(String email, String password) async {
    return await client.auth.signUp(
      email: email,
      password: password,
    );
  }

  Future<AuthResponse> signIn(String email, String password) async {
    return await client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    await client.auth.signOut();
  }

  Stream<AuthState> get authStateChanges => client.auth.onAuthStateChange;
}
