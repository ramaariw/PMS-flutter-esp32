import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/power_provider.dart';

class MonitoringScreen extends StatelessWidget {
  const MonitoringScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<PowerProvider>(
      builder: (context, powerData, child) {
        return Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            title: Text(
              "PMS v1.3 by Ame",
              style: GoogleFonts.orbitron(
                fontSize: 16,
                letterSpacing: 2,
                fontWeight: FontWeight.bold,
              ),
            ),
            centerTitle: true,
            backgroundColor: Colors.transparent,
            elevation: 0,
            actions: [
              IconButton(
                icon: Icon(
                  Icons.sync,
                  color:
                      powerData.isConnected
                          ? Colors.greenAccent
                          : Colors.white24,
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
                children: [
                  _buildHeader(powerData),
                  const SizedBox(height: 20),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.4,
                    children: [
                      _buildDataCard(
                        "AC VOLTAGE",
                        powerData.acVolt.toStringAsFixed(1),
                        "V",
                        Colors.blueAccent,
                      ),
                      _buildDataCard(
                        "CURRENT",
                        powerData.ampere.toStringAsFixed(2),
                        "A",
                        Colors.greenAccent,
                      ),
                      _buildDataCard(
                        "REAL POWER",
                        powerData.watt.toStringAsFixed(1),
                        "W",
                        Colors.redAccent,
                      ),
                      _buildDataCard(
                        "ENERGY",
                        powerData.kwh.toStringAsFixed(3),
                        "kWh",
                        Colors.tealAccent,
                      ),
                      _buildDataCard(
                        "DC VOLTAGE",
                        powerData.dcVolt.toStringAsFixed(1),
                        "V",
                        Colors.orangeAccent,
                      ),
                      _buildDataCard(
                        "BATTERY",
                        "${powerData.batStatus}",
                        "%",
                        _getBatColor(powerData.batStatus),
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

  Color _getBatColor(int status) {
    if (status > 60) return Colors.greenAccent;
    if (status > 20) return Colors.orangeAccent;
    return Colors.redAccent;
  }

  Widget _buildHeader(PowerProvider powerData) {
    bool connected = powerData.isConnected;
    bool loading = powerData.isLoading;

    return InkWell(
      onTap: loading ? null : () => powerData.toggleConnection(),
      borderRadius: BorderRadius.circular(15),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color:
              connected
                  ? Colors.green.withValues(alpha: 0.05)
                  : Colors.red.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: connected ? Colors.greenAccent : Colors.redAccent,
            width: 1.5,
          ),
          boxShadow: [
            if (connected)
              BoxShadow(
                color: Colors.greenAccent.withValues(alpha: 0.1),
                blurRadius: 10,
                spreadRadius: 1,
              ),
          ],
        ),
        child: Row(
          children: [
            loading
                ? const SizedBox(
                  width: 32,
                  height: 32,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
                : Icon(
                  connected ? Icons.sensors : Icons.sensors_off,
                  color: connected ? Colors.greenAccent : Colors.redAccent,
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
                      color: connected ? Colors.greenAccent : Colors.redAccent,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                  if (connected)
                    Text(
                      "UPTIME: ${powerData.uptime}",
                      style: GoogleFonts.shareTechMono(
                        color: Colors.orangeAccent,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),
            Icon(
              Icons.power_settings_new,
              color: connected ? Colors.greenAccent : Colors.redAccent,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataCard(String label, String value, String unit, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white38,
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
