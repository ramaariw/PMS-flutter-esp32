import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/power_provider.dart';
import 'package:flutter/services.dart';

class ControlScreen extends StatelessWidget {
  const ControlScreen({super.key});

  // --- FUNGSI BARU: TIME PICKER JADWAL ---
  Future<void> _selectSchedule(
    BuildContext context,
    PowerProvider powerData,
    int channel,
  ) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Colors.cyanAccent,
              onPrimary: Colors.black,
              surface: Color(0xFF1A1A1A),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      // Format jadi HH:MM (Misal "21:30")
      String formattedTime =
          "${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}";
      powerData.sendScheduleToHardware(channel, formattedTime);
    }
  }

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
                  color: Colors.orangeAccent.withValues(alpha: 0.1),
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
                    "SET TIMER FOR RELAY $channel",
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
                      fillColor: Colors.white.withValues(alpha: 0.05),
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
                        powerData.sendTimerToHardware(channel, mins);
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
                color: Colors.white.withValues(alpha: 0.05),
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
    int remaining =
        (channel == 1)
            ? powerData.remainingSecondsR1
            : powerData.remainingSecondsR2;
    String schedule =
        (channel == 1) ? powerData.scheduleR1 : powerData.scheduleR2;

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
              if (val == false) {
                powerData.sendTimerToHardware(channel, 0);
                powerData.sendScheduleToHardware(channel, "OFF");
              }
              powerData.toggleRelay(channel, val);
            },
            activeColor: Colors.greenAccent,
            inactiveThumbColor: Colors.redAccent,
          ),
        ),
        const SizedBox(height: 10),
        if (isOn) ...[
          Text(
            remaining > 0
                ? "OFF IN: ${powerData.formatRemainingTime(remaining)}"
                : "MANUAL ON",
            style: GoogleFonts.shareTechMono(
              color: remaining > 0 ? Colors.orangeAccent : Colors.white24,
              fontSize: 10,
            ),
          ),
          // INFO JADWAL
          Text(
            schedule.isNotEmpty && schedule != "OFF"
                ? "SCH: $schedule"
                : "NO SCH",
            style: GoogleFonts.shareTechMono(
              color:
                  schedule.isNotEmpty && schedule != "OFF"
                      ? Colors.cyanAccent
                      : Colors.white12,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _timerBtn(
                context,
                "SET",
                () => _showTimerInput(context, powerData, channel),
              ),
              const SizedBox(width: 4),
              // TOMBOL BARU: CLOCK
              _timerBtn(
                context,
                "CLOCK",
                () => _selectSchedule(context, powerData, channel),
              ),
              const SizedBox(width: 4),
              _timerBtn(context, "X", () {
                powerData.sendTimerToHardware(channel, 0);
                powerData.sendScheduleToHardware(channel, "OFF");
              }),
            ],
          ),
        ],
      ],
    );
  }

  Widget _timerBtn(BuildContext context, String label, VoidCallback onTap) {
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.white10),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 9,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
