import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart'; // Import Charting Package
import '../providers/power_provider.dart';

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
              "PMS v1.3 by Ame",
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
                  _buildHeader(context, powerData),
                  const SizedBox(height: 20),

                  // --- SECTION NEW: LIVE WATT CHART ---
                  _buildSectionLabel(isDark, "REAL-TIME LOAD (WATT)"),
                  const SizedBox(height: 10),
                  _buildWattChart(context, powerData, isDark),

                  const SizedBox(height: 25),

                  // --- SECTION: GRID DATA ---
                  _buildSectionLabel(isDark, "SENSOR PARAMETERS"),
                  const SizedBox(height: 10),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.4,
                    children: [
                      _buildDataCard(
                        context,
                        "AC VOLTAGE",
                        powerData.acVolt.toStringAsFixed(1),
                        "V",
                        Colors.blueAccent,
                      ),
                      _buildDataCard(
                        context,
                        "CURRENT",
                        powerData.ampere.toStringAsFixed(2),
                        "A",
                        isDark ? Colors.greenAccent : Colors.green[700]!,
                      ),
                      _buildDataCard(
                        context,
                        "REAL POWER",
                        powerData.watt.toStringAsFixed(1),
                        "W",
                        Colors.redAccent,
                      ),
                      _buildDataCard(
                        context,
                        "ENERGY",
                        powerData.kwh.toStringAsFixed(3),
                        "kWh",
                        isDark ? Colors.tealAccent : Colors.teal[700]!,
                      ),
                      _buildDataCard(
                        context,
                        "DC VOLTAGE",
                        powerData.dcVolt.toStringAsFixed(1),
                        "V",
                        Colors.orangeAccent,
                      ),
                      _buildDataCard(
                        context,
                        "BATTERY",
                        "${powerData.batStatus}",
                        "%",
                        _getBatColor(powerData.batStatus, isDark),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionLabel(bool isDark, String label) {
    return Text(
      label,
      style: GoogleFonts.orbitron(
        fontSize: 10,
        fontWeight: FontWeight.bold,
        color: isDark ? Colors.white38 : Colors.black38,
        letterSpacing: 1.5,
      ),
    );
  }

  Widget _buildWattChart(
    BuildContext context,
    PowerProvider powerData,
    bool isDark,
  ) {
    return Container(
      height: 120,
      padding: const EdgeInsets.fromLTRB(10, 20, 20, 10),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
        boxShadow:
            isDark
                ? []
                : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
      ),
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: false),
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots:
                  powerData.wattHistory.asMap().entries.map((e) {
                    return FlSpot(e.key.toDouble(), e.value);
                  }).toList(),
              isCurved: true,
              color: Colors.redAccent,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: Colors.redAccent.withValues(alpha: 0.15),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getBatColor(int status, bool isDark) {
    if (status > 60) return isDark ? Colors.greenAccent : Colors.green[700]!;
    if (status > 20) return Colors.orangeAccent;
    return Colors.redAccent;
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
                        fontSize: 12,
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

  Widget _buildDataCard(
    BuildContext context,
    String label,
    String value,
    String unit,
    Color color,
  ) {
    final isDark = Provider.of<PowerProvider>(context).isDarkMode;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
        boxShadow:
            isDark
                ? []
                : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isDark ? Colors.white38 : Colors.black45,
              fontSize: 9,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.shareTechMono(
              color: color,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            unit,
            style: TextStyle(color: color.withValues(alpha: 0.7), fontSize: 10),
          ),
        ],
      ),
    );
  }
}
