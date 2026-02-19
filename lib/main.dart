import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'providers/theme_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/device_provider.dart';
import 'services/sensor_service.dart';
import 'services/database_service.dart';
import 'screens/splash_screen.dart';
import 'screens/welcome_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/home_screen.dart';
import 'screens/control_screen.dart';
import 'screens/data_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/edit_plot_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  print('[Main] ✅ Firebase initialized successfully');

  // NOTE: Database service (MySQL direct connection) is disabled
  // The app now uses REST API instead of direct database connection
  // Uncomment below only if you want to use local MySQL for testing
  /*
  print('[Main] Initializing database...');
  final dbService = DatabaseService();
  try {
    await dbService.userExists('init');
    print('[Main] [OK] Database initialized successfully');
  } catch (e) {
    print('[Main] ⚠️  Database initialization warning: $e');
  }
  */

  print('[Main] Using REST API for authentication');

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => DeviceProvider()),
        ChangeNotifierProvider(create: (_) => SensorService()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp.router(
            title: 'Andrographis Smart Farm',
            debugShowCheckedModeBanner: false,
            theme: themeProvider.lightTheme,
            darkTheme: themeProvider.darkTheme,
            themeMode: themeProvider.themeMode,
            routerConfig: _router,
          );
        },
      ),
    );
  }
}

final GoRouter _router = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(
      path: '/splash',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/welcome',
      builder: (context, state) => const WelcomeScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(
      path: '/main',
      builder: (context, state) => const MainTabScreen(),
      routes: [
        GoRoute(
          path: 'home',
          builder: (context, state) => const HomeScreen(),
        ),
        GoRoute(
          path: 'control',
          builder: (context, state) => const ControlScreen(),
        ),
        GoRoute(
          path: 'data',
          builder: (context, state) => const DataScreen(),
        ),
        GoRoute(
          path: 'settings',
          builder: (context, state) => const SettingsScreen(),
        ),
      ],
    ),
    GoRoute(
      path: '/edit_plot',
      builder: (context, state) {
        final plot = state.extra as dynamic;
        return EditPlotScreen(plot: plot);
      },
    ),
  ],
);

class MainTabScreen extends StatefulWidget {
  const MainTabScreen({super.key});

  @override
  State<MainTabScreen> createState() => _MainTabScreenState();
}

class _MainTabScreenState extends State<MainTabScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const ControlScreen(),
    const DataScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final colors = themeProvider.colors;

    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: colors.tabBarBg,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(25),
            topRight: Radius.circular(25),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              offset: const Offset(0, -4),
              blurRadius: 12,
              spreadRadius: 0,
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: colors.tabBarActive,
          unselectedItemColor: colors.tabBarInactive,
          selectedLabelStyle: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.eco, size: 26),
              activeIcon: Icon(Icons.eco, size: 30),
              label: 'Hydroponic',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings_remote, size: 26),
              activeIcon: Icon(Icons.settings_remote, size: 30),
              label: 'Control',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.analytics_outlined, size: 24),
              activeIcon: Icon(Icons.analytics, size: 28),
              label: 'Data',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings_outlined, size: 24),
              activeIcon: Icon(Icons.settings, size: 28),
              label: 'Set Up',
            ),
          ],
        ),
      ),
    );
  }
}
