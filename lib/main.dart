import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/power_provider.dart';
import 'screens/dashboard.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final powerProvider = PowerProvider();
  await powerProvider.loadLocalState();

  runApp(
    MultiProvider(
      providers: [ChangeNotifierProvider.value(value: powerProvider)],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<PowerProvider>(
      builder: (context, pms, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'PMS V1.3',

          // --- LIGHT THEME (Google Bright) ---
          theme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.light,
            scaffoldBackgroundColor: const Color(
              0xFFF8F9FA,
            ), // Abu Google ultra light
            cardColor: Colors.white,
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black87,
              elevation: 0,
              centerTitle: true,
            ),
          ),

          // --- DARK THEME (Original V1.2) ---
          darkTheme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.dark,
            scaffoldBackgroundColor: Colors.black,
            cardColor: const Color(0xFF1A1A1A),
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              elevation: 0,
              centerTitle: true,
            ),
          ),

          // Penentu Tema Aktif
          themeMode: pms.isDarkMode ? ThemeMode.dark : ThemeMode.light,

          home: const DashboardScreen(),
        );
      },
    );
  }
}
