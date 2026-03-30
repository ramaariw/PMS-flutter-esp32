import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/power_provider.dart';
import 'monitoring_screen.dart';
import 'control_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;
  final List<Widget> _pages = [const MonitoringScreen(), const ControlScreen()];

  @override
  Widget build(BuildContext context) {
    final pms = Provider.of<PowerProvider>(context);

    return Scaffold(
      // Ikut warna scaffold dari theme di main.dart
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: IndexedStack(index: _selectedIndex, children: _pages),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        // Warna background bottom bar dinamis
        backgroundColor:
            pms.isDarkMode ? const Color(0xFF151515) : Colors.white,
        selectedItemColor:
            pms.isDarkMode ? Colors.greenAccent : Colors.green[700],
        unselectedItemColor: pms.isDarkMode ? Colors.white24 : Colors.black26,
        type: BottomNavigationBarType.fixed,
        elevation: 10,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics),
            label: 'MONITOR',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.developer_board),
            label: 'CONTROL',
          ),
        ],
      ),
    );
  }
}
