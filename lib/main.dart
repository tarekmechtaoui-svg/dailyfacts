import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'services/supabase_service.dart';
import 'services/onesignal_service.dart';
import 'screens/auth_screen.dart';
import 'screens/categories_screen.dart';
import 'screens/facts_screen.dart';
import 'screens/settings_screen.dart';

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

    // Wait a moment for initialization to complete
    await Future.delayed(const Duration(seconds: 2));

    // Print subscription status
    final subscription = OneSignal.User.pushSubscription;
    print("OneSignal Player ID: ${subscription.id}");
    print("OneSignal Token: ${subscription.token}");
    print("OneSignal Opt-In: ${subscription.optedIn}");
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
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1F2937),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        fontFamily: 'Roboto',
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1F2937),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        cardTheme: CardTheme(
          color: const Color(0xFF1F2937),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Color(0xFF1F2937),
          selectedItemColor: Color(0xFF3B82F6),
          unselectedItemColor: Colors.grey,
        ),
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
      return const HomeScreen();
    }
  }

  void _setupOneSignalUserId(String userId) {
    OneSignalService.instance.setExternalUserId(userId);
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedTabIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Daily Facts',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: IndexedStack(
        index: _selectedTabIndex,
        children: const [
          CategoriesScreen(),
          FactsScreen(),
          SettingsScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedTabIndex,
        onTap: (index) {
          setState(() {
            _selectedTabIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.category_outlined),
            activeIcon: Icon(Icons.category),
            label: 'Categories',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.lightbulb_outline),
            activeIcon: Icon(Icons.lightbulb),
            label: 'Facts',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
