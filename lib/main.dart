/// FraudX Analyst - Main Entry Point
/// ====================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/app_provider.dart';
import 'screens/start_screen.dart';
import 'screens/home_screen.dart';
import 'screens/simulate_screen.dart';
import 'screens/train_screen.dart';
import 'screens/models_screen.dart';
import 'screens/history_screen.dart';
import 'screens/chat_screen.dart';

void main() {
  runApp(const FraudXApp());
}

class FraudXApp extends StatelessWidget {
  const FraudXApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppProvider()),
      ],
      child: MaterialApp(
        title: 'FraudX Analyst',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF2A9D8F),
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          scaffoldBackgroundColor: const Color(0xFFF5F7FA),
          appBarTheme: const AppBarTheme(
            centerTitle: false,
            elevation: 0,
            backgroundColor: Color(0xFFF5F7FA),
            foregroundColor: Color(0xFF1A1A2E),
          ),
          cardTheme: CardThemeData(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            color: Colors.white,
          ),
        ),
        initialRoute: '/',
        routes: {
          '/': (context) => const StartScreen(),
          '/main': (context) => const MainScreen(),
          '/history': (context) => const HistoryScreen(),
        },
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final List<Widget> _screens = const [
    HomeScreen(),
    SimulateScreen(),
    TrainScreen(),
    ChatScreen(),
    ModelsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppProvider>().loadModels();
    });
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = context.watch<AppProvider>().currentTabIndex;
    return Scaffold(
      body: _screens[selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -2)),
          ],
        ),
        child: NavigationBar(
          height: 65,
          backgroundColor: Colors.white,
          indicatorColor: const Color(0xFF2A9D8F).withOpacity(0.12),
          selectedIndex: selectedIndex,
          onDestinationSelected: (i) => context.read<AppProvider>().switchTab(i),
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: const [
            NavigationDestination(icon: Icon(Icons.grid_view_outlined, size: 22), selectedIcon: Icon(Icons.grid_view, size: 22, color: Color(0xFF2A9D8F)), label: 'Home'),
            NavigationDestination(icon: Icon(Icons.science_outlined, size: 22), selectedIcon: Icon(Icons.science, size: 22, color: Color(0xFF2A9D8F)), label: 'Simulate'),
            NavigationDestination(icon: Icon(Icons.school_outlined, size: 22), selectedIcon: Icon(Icons.school, size: 22, color: Color(0xFF2A9D8F)), label: 'Train'),
            NavigationDestination(icon: Icon(Icons.chat_bubble_outline, size: 22), selectedIcon: Icon(Icons.chat_bubble, size: 22, color: Color(0xFF2A9D8F)), label: 'Chat'),
            NavigationDestination(icon: Icon(Icons.bar_chart_outlined, size: 22), selectedIcon: Icon(Icons.bar_chart, size: 22, color: Color(0xFF2A9D8F)), label: 'Models'),
          ],
        ),
      ),
    );
  }
}
