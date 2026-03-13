import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/power_provider.dart';

class ControlScreen extends StatelessWidget {
  const ControlScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(
          "HARDWARE CONTROL",
          style: GoogleFonts.orbitron(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Consumer<PowerProvider>(
        builder: (context, powerData, child) {
          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(
                      8,
                    ), // Ganti withOpacity biar gak deprecated
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      // UPDATE: Sekarang kita kirim 5 argumen (context, label, status, fungsi, channel)
                      _relayItem(
                        context,
                        "RELAY 1",
                        powerData.relay1,
                        (val) => powerData.toggleRelay(1, val),
                        1,
                      ),
                      _relayItem(
                        context,
                        "RELAY 2",
                        powerData.relay2,
                        (val) => powerData.toggleRelay(2, val),
                        2,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // FUNGSI KONFIRMASI (Biar gak undefined_method)
  void _showConfirmDialog(
    BuildContext context,
    String label,
    bool currentValue,
    Function(bool) onChanged,
  ) {
    if (!currentValue) {
      onChanged(true);
      return;
    }

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: const Color(0xFF1A1A1A),
            title: Text(
              "WARNING",
              style: GoogleFonts.orbitron(
                color: Colors.redAccent,
                fontSize: 14,
              ),
            ),
            content: Text(
              "Turn OFF $label?",
              style: const TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("CANCEL"),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                ),
                onPressed: () {
                  onChanged(false);
                  Navigator.pop(context);
                },
                child: const Text("YES"),
              ),
            ],
          ),
    );
  }

  Widget _relayItem(
    BuildContext context,
    String label,
    bool isOn,
    Function(bool) onChanged,
    int channel,
  ) {
    return Consumer<PowerProvider>(
      builder: (context, powerData, child) {
        return Column(
          children: [
            Text(
              label,
              style: GoogleFonts.shareTechMono(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 10),
            Transform.scale(
              scale: 1.2,
              child: Switch(
                value: isOn,
                onChanged: (val) {
                  if (val == false) powerData.setRelayTimer(0, channel);
                  _showConfirmDialog(context, label, isOn, onChanged);
                },
                activeColor: Colors.greenAccent,
                inactiveThumbColor: Colors.redAccent,
              ),
            ),

            // UI TIMER ADD-ON
            AnimatedOpacity(
              duration: const Duration(milliseconds: 500),
              opacity: isOn ? 1.0 : 0.0,
              child:
                  isOn
                      ? Column(
                        children: [
                          const SizedBox(height: 10),
                          Text(
                            powerData.remainingSeconds > 0
                                ? "OFF IN: ${powerData.formattedTimer}"
                                : "SET TIMER",
                            style: GoogleFonts.shareTechMono(
                              color:
                                  powerData.remainingSeconds > 0
                                      ? Colors.orangeAccent
                                      : Colors.white24,
                              fontSize: 10,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              _timerBtn(
                                context,
                                "5m",
                                () => powerData.setRelayTimer(5, channel),
                              ),
                              _timerBtn(
                                context,
                                "X",
                                () => powerData.setRelayTimer(0, channel),
                              ),
                            ],
                          ),
                        ],
                      )
                      : const SizedBox.shrink(),
            ),
          ],
        );
      },
    );
  }

  Widget _timerBtn(BuildContext context, String label, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(12),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.orangeAccent.withAlpha(50)),
          ),
          child: Text(
            label,
            style: const TextStyle(color: Colors.orangeAccent, fontSize: 9),
          ),
        ),
      ),
    );
  }
}
