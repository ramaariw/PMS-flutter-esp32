import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/power_provider.dart';
import 'package:flutter/services.dart';

class ControlScreen extends StatelessWidget {
  const ControlScreen({super.key});

  // Fungsi buat munculin input manual
  void _showTimerInput(
    BuildContext context,
    PowerProvider powerData,
    int channel,
  ) {
    TextEditingController timerController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => AnimatedPadding(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutQuad,
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Container(
              padding: const EdgeInsets.all(25),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(30),
                ),
                border: Border.all(
                  color: Colors.orangeAccent.withAlpha(40),
                  width: 1,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white12,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "SET TIMER FOR R$channel",
                    style: GoogleFonts.orbitron(
                      color: Colors.orangeAccent,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 25),
                  TextField(
                    controller: timerController,
                    keyboardType: TextInputType.number,
                    autofocus: true,
                    // FIX ERROR DI SINI: Pakai TextAlign.center
                    textAlign: TextAlign.center,
                    style: GoogleFonts.orbitron(
                      color: Colors.white,
                      fontSize: 24,
                      letterSpacing: 2,
                    ),
                    decoration: InputDecoration(
                      suffixText: "min",
                      suffixStyle: const TextStyle(color: Colors.white24),
                      filled: true,
                      fillColor: Colors.white.withAlpha(5),
                      enabledBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.white10),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: const BorderSide(
                          color: Colors.orangeAccent,
                        ),
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                  ),
                  const SizedBox(height: 25),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orangeAccent,
                      foregroundColor: Colors.black,
                      minimumSize: const Size(double.infinity, 55),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    onPressed: () {
                      int? mins = int.tryParse(timerController.text);
                      if (mins != null && mins > 0) {
                        powerData.setRelayTimer(mins, channel);
                      }
                      Navigator.pop(context);
                    },
                    child: Text(
                      "ACTIVATE COUNTDOWN",
                      style: GoogleFonts.orbitron(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
    );
  }

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
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(10),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _relayItem(
                    context,
                    powerData,
                    "RELAY 1",
                    powerData.relay1,
                    1,
                  ),
                  _relayItem(
                    context,
                    powerData,
                    "RELAY 2",
                    powerData.relay2,
                    2,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _relayItem(
    BuildContext context,
    PowerProvider powerData,
    String label,
    bool isOn,
    int channel,
  ) {
    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.shareTechMono(color: Colors.white, fontSize: 14),
        ),
        const SizedBox(height: 10),
        Transform.scale(
          scale: 1.2,
          child: Switch(
            value: isOn,
            onChanged: (val) {
              if (val == false) powerData.setRelayTimer(0, channel);
              powerData.toggleRelay(
                channel,
                val,
              ); // Langsung toggle tanpa warning
            },
            activeColor: Colors.greenAccent,
            inactiveThumbColor: Colors.redAccent,
          ),
        ),

        // UI TIMER ADD-ON
        const SizedBox(height: 10),
        if (isOn) ...[
          Text(
            powerData.remainingSeconds > 0
                ? "OFF IN: ${powerData.formattedTimer}"
                : "TIMER OFF",
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
              // Tombol Input Manual
              _timerBtn(
                context,
                "SET",
                () => _showTimerInput(context, powerData, channel),
              ),
              const SizedBox(width: 5),
              // Tombol Cancel
              _timerBtn(
                context,
                "X",
                () => powerData.setRelayTimer(0, channel),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _timerBtn(BuildContext context, String label, VoidCallback onTap) {
    return InkWell(
      onTap: () {
        // TAMBAHIN INI: Getar halus pas tombol menu ditekan
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(15),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.orangeAccent.withAlpha(80)),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.orangeAccent,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
