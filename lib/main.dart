import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'services/supabase_service.dart';
import 'services/onesignal_service.dart';
import 'screens/auth_screen.dart';
import 'screens/subjects_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: '.env');

  final supabaseUrl = dotenv.env['VITE_SUPABASE_URL'] ?? '';
  final supabaseAnonKey = dotenv.env['VITE_SUPABASE_ANON_KEY'] ?? '';
  final oneSignalAppId = dotenv.env['ONESIGNAL_APP_ID'] ?? '';

  // Initialize Supabase
  await SupabaseService.initialize(supabaseUrl, supabaseAnonKey);

  // Initialize OneSignal
  if (oneSignalAppId.isNotEmpty) {
    OneSignal.Debug.setLogLevel(OSLogLevel.verbose);

    await OneSignalService.instance.initialize(oneSignalAppId);

    // Request notification permissions
    await OneSignal.Notifications.requestPermission(true);

    // ✅ Print the Player ID after initialization
    final playerId = OneSignal.User.pushSubscription.id;
    print("🔔 OneSignal Player ID: $playerId");
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Daily Subject Facts',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  void initState() {
    super.initState();
    _setupAuthListener();
  }

  void _setupAuthListener() {
    SupabaseService.instance.authStateChanges.listen((event) {
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = SupabaseService.client.auth.currentUser;

    if (user == null) {
      return const AuthScreen();
    } else {
      _setupOneSignalUserId(user.id);
      return const SubjectsScreen();
    }
  }

  void _setupOneSignalUserId(String userId) {
    OneSignalService.instance.setExternalUserId(userId);
  }
}
