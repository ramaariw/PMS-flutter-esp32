import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/power_provider.dart';
import 'screens/dashboard.dart';

// Di main.dart lu
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final powerProvider = PowerProvider();
  await powerProvider.loadLocalState(); // <--- BACA MEMORI HP DULU

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
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true),
      home: const DashboardScreen(),
    );
  }
}
