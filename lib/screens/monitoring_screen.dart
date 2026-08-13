import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/power_provider.dart';

// IMPORT SEKAT-SEKAT KOMPONEN BARU KITA ME
import 'components/energy_analytics_section.dart';
import 'components/ac_monitor_section.dart';
import 'components/dc_monitor_section.dart';

class MonitoringScreen extends StatelessWidget {
  const MonitoringScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<PowerProvider>(
      builder: (context, powerData, child) {
        final isDark = powerData.isDarkMode;

        return Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            title: Text(
              "PMS v2.0",
              style: GoogleFonts.orbitron(
                fontSize: 16,
                letterSpacing: 2,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            centerTitle: true,
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
              onPressed: () => powerData.toggleTheme(),
            ),
            actions: [
              IconButton(
                icon: Icon(
                  Icons.sync,
                  color:
                      powerData.isConnected
                          ? (isDark ? Colors.greenAccent : Colors.green[700])
                          : (isDark ? Colors.white24 : Colors.black26),
                ),
                onPressed:
                    powerData.isLoading ? null : () => powerData.refreshData(),
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: () => powerData.refreshData(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. BLOK STATUS KONEKSI & UPTIME SENSOR
                  _buildHeader(context, powerData),
                  const SizedBox(height: 20),

                  // 2. KONTEN GRAFIK (ENERGY ANALYTICS & FINANCIAL)
                  EnergyAnalyticsSection(powerData: powerData, isDark: isDark),
                  const SizedBox(height: 20),

                  // 3. SEKAT PARAMETER LISTRIK AC (PLN / INVERTER)
                  AcMonitorSection(powerData: powerData, isDark: isDark),
                  const SizedBox(height: 20),

                  // 4. SEKAT PARAMETER AKI & STATUS DC (INA219 V2.0 LIVE)
                  DcMonitorSection(powerData: powerData, isDark: isDark),
                  const SizedBox(
                    height: 20,
                  ), // Sengaja gua ganti 20 biar proporsional jon
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, PowerProvider powerData) {
    bool connected = powerData.isConnected;
    bool isDark = powerData.isDarkMode;
    Color accentColor =
        connected
            ? (isDark ? Colors.greenAccent : Colors.green[700]!)
            : Colors.redAccent;

    return InkWell(
      onTap: powerData.isLoading ? null : () => powerData.toggleConnection(),
      borderRadius: BorderRadius.circular(15),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color:
              connected
                  ? accentColor.withValues(alpha: 0.05)
                  : Colors.red.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: accentColor, width: 1.5),
        ),
        child: Row(
          children: [
            powerData.isLoading
                ? SizedBox(
                  width: 32,
                  height: 32,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: accentColor,
                  ),
                )
                : Icon(
                  connected ? Icons.sensors : Icons.sensors_off,
                  color: accentColor,
                  size: 32,
                ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    connected ? "SYSTEM CONNECTED" : "SYSTEM DISCONNECTED",
                    style: GoogleFonts.orbitron(
                      color: accentColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                  if (connected)
                    Text(
                      "UPTIME: ${powerData.uptime}",
                      style: GoogleFonts.shareTechMono(
                        color:
                            isDark ? Colors.orangeAccent : Colors.orange[800],
                        fontSize: 11,
                      ),
                    ),
                ],
              ),
            ),
            Icon(Icons.power_settings_new, color: accentColor, size: 20),
          ],
        ),
      ),
    );
  }
}
