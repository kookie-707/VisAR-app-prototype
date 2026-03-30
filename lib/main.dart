import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'theme/app_theme.dart';
import 'screens/home_screen.dart';
import 'screens/hud_customization_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/navigation_screen.dart';
import 'providers/app_state_provider.dart';
import 'services/config_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load persisted config before the widget tree builds.
  final configService = ConfigService();
  await configService.init();

  runApp(VisARApp(configService: configService));
}

class VisARApp extends StatelessWidget {
  final ConfigService configService;

  const VisARApp({super.key, required this.configService});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppStateProvider()),
        ChangeNotifierProvider.value(value: configService),
      ],
      child: MaterialApp(
        title: 'VisAR Smart Helmet',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const MainNavigationScreen(),
      ),
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen>
    with WidgetsBindingObserver {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const NavigationScreen(),
    const HUDCustomizationScreen(),
    const ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      final appState = Provider.of<AppStateProvider>(context, listen: false);
      appState.onAppResumed();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppTheme.backgroundBlack,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          backgroundColor: AppTheme.backgroundBlack,
          selectedItemColor: AppTheme.accentRed,
          unselectedItemColor: Colors.white70,
          selectedLabelStyle: GoogleFonts.orbitron(
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: GoogleFonts.orbitron(
            fontSize: 10,
            fontWeight: FontWeight.w400,
          ),
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.map),
              label: 'Nav',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.tune),
              label: 'HUD',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
