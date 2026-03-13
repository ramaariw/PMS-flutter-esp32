import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/power_provider.dart';

class DashboardScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF121212),
      appBar: AppBar(
        title: Text(
          "Power Monitoring System V1.1",
          style: GoogleFonts.orbitron(fontSize: 18),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,

        // TAMBAHIN INI DI APPBAR
        actions: [
          Consumer<PowerProvider>(
            builder: (context, powerData, child) {
              return IconButton(
                icon: Icon(
                  Icons.refresh,
                  color: powerData.isConnected ? Colors.green : Colors.grey,
                ),
                onPressed: () {
                  // Panggil fungsi refresh
                  powerData.refreshData();

                  // Kasih notif dikit biar keren
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Refreshing data..."),
                      duration: Duration(seconds: 1),
                      backgroundColor: const Color.fromARGB(255, 238, 238, 238),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
      body: Consumer<PowerProvider>(
        builder: (context, powerData, child) {
          return SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                // Indikator Koneksi SEKALIGUS Tombol Toggle
                _buildHeader(context, powerData),

                SizedBox(height: 20),

                // Grid Data
                GridView.count(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 1.3,
                  children: [
                    _buildDataCard(
                      "AC VOLTAGE",
                      "${powerData.acVolt}",
                      "V",
                      Colors.blue,
                    ),
                    _buildDataCard(
                      "CURRENT",
                      "${powerData.ampere}",
                      "A",
                      Colors.green,
                    ),
                    _buildDataCard(
                      "POWER",
                      "${powerData.watt}",
                      "W",
                      Colors.red,
                    ),
                    _buildDataCard(
                      "ENERGY",
                      "${powerData.kwh}",
                      "kWh",
                      Colors.teal,
                    ),
                    _buildDataCard(
                      "DC VOLTAGE",
                      "${powerData.dcVolt}",
                      "V",
                      Colors.orange,
                    ),
                    _buildDataCard(
                      "BATTERY",
                      "${powerData.batStatus}",
                      "%",
                      Colors.purple,
                    ),
                  ],
                ),
                // Tambahin ini di bawah GridView.count di dalam Column utama
                SizedBox(height: 1),
                _buildRelayControl(powerData),
              ],
            ),
          );
        },
      ),
    );
  }

  // MODIFIKASI DI SINI: Tambah context dan powerData buat toggle
  Widget _buildHeader(BuildContext context, PowerProvider powerData) {
    bool connected = powerData.isConnected;

    return InkWell(
      onTap: () => powerData.toggleConnection(),
      borderRadius: BorderRadius.circular(15),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 300),
        padding: EdgeInsets.all(15),
        decoration: BoxDecoration(
          color:
              connected
                  ? Colors.green.withOpacity(0.1)
                  : Colors.red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: connected ? Colors.green : Colors.red,
            width: 2,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              connected ? Icons.cloud_done : Icons.cloud_off,
              color: connected ? Colors.green : Colors.red,
              size: 30, // Gedein dikit biar mantap
            ),
            SizedBox(width: 15),
            Expanded(
              // Pakai Expanded biar aman kalau teks kepanjangan
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    connected ? "SYSTEM ONLINE" : "SYSTEM OFFLINE",
                    style: GoogleFonts.orbitron(
                      color: connected ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  // ----- BAGIAN UPTIME DISINI -----
                  if (connected)
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        "Uptime: ${powerData.uptime}", // Panggil variabel uptime dari provider
                        style: GoogleFonts.shareTechMono(
                          color: Colors.orangeAccent,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  // --------------------------------
                  Text(
                    connected ? "Tap to Disconnect" : "Tap to Connect",
                    style: TextStyle(color: Colors.white54, fontSize: 10),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataCard(String label, String value, String unit, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: TextStyle(color: Colors.white60, fontSize: 10)),
          const SizedBox(height: 5),
          Text(
            value,
            style: GoogleFonts.shareTechMono(color: color, fontSize: 28),
          ),
          Text(unit, style: TextStyle(color: color, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildRelayControl(PowerProvider powerData) {
    return Container(
      padding: EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          Text(
            "RELAY CONTROL",
            style: GoogleFonts.orbitron(color: Colors.white60, fontSize: 12),
          ),
          Divider(color: Colors.white10, height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // Channel 1
              _relayItem(
                "RELAY 1",
                powerData.relay1,
                (val) => powerData.toggleRelay(1, val),
              ),
              // Channel 2
              _relayItem(
                "RELAY 2",
                powerData.relay2,
                (val) => powerData.toggleRelay(2, val),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _relayItem(String label, bool isOn, Function(bool) onChanged) {
    return Column(
      children: [
        Text(label, style: TextStyle(color: Colors.white, fontSize: 10)),
        Switch(
          value: isOn,
          onChanged: onChanged,
          activeColor: Colors.greenAccent,
          inactiveThumbColor: Colors.redAccent,
        ),
        Text(
          isOn ? "ON" : "OFF",
          style: TextStyle(
            color: isOn ? Colors.greenAccent : Colors.redAccent,
            fontWeight: FontWeight.bold,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}
