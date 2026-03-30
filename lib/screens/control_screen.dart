import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/power_provider.dart';
import 'package:flutter/services.dart';

class ControlScreen extends StatelessWidget {
  const ControlScreen({super.key});

  // --- LOGIC TIME PICKER ---
  Future<void> _selectSchedule(
    BuildContext context,
    PowerProvider powerData,
    int channel,
  ) async {
    final isDark = powerData.isDarkMode;
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data:
              isDark
                  ? ThemeData.dark().copyWith(
                    colorScheme: const ColorScheme.dark(
                      primary: Colors.cyanAccent,
                      onPrimary: Colors.black,
                      surface: Color(0xFF1A1A1A),
                      onSurface: Colors.white,
                    ),
                  )
                  : ThemeData.light().copyWith(
                    colorScheme: ColorScheme.light(
                      primary: Colors.cyan[700]!,
                      onPrimary: Colors.white,
                      surface: Colors.white,
                      onSurface: Colors.black87,
                    ),
                  ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      String formattedTime =
          "${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}";
      powerData.sendScheduleToHardware(channel, formattedTime);
    }
  }

  // --- LOGIC TIMER MODAL ---
  void _showTimerInput(
    BuildContext context,
    PowerProvider powerData,
    int channel,
  ) {
    final isDark = powerData.isDarkMode;
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
                color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(30),
                ),
                border: Border.all(
                  color:
                      isDark
                          ? Colors.orangeAccent.withValues(alpha: 0.1)
                          : Colors.black12,
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
                      color: isDark ? Colors.white12 : Colors.black12,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "SET TIMER FOR RELAY $channel",
                    style: GoogleFonts.orbitron(
                      color: isDark ? Colors.orangeAccent : Colors.orange[800],
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
                      color: isDark ? Colors.white : Colors.black87,
                      fontSize: 24,
                      letterSpacing: 2,
                    ),
                    decoration: InputDecoration(
                      suffixText: "min",
                      suffixStyle: TextStyle(
                        color: isDark ? Colors.white24 : Colors.black26,
                      ),
                      filled: true,
                      fillColor:
                          isDark
                              ? Colors.white.withValues(alpha: 0.05)
                              : Colors.black.withValues(alpha: 0.05),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: isDark ? Colors.white10 : Colors.black12,
                        ),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color:
                              isDark
                                  ? Colors.orangeAccent
                                  : Colors.orange[800]!,
                        ),
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                  ),
                  const SizedBox(height: 25),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          isDark ? Colors.orangeAccent : Colors.orange[800],
                      foregroundColor: isDark ? Colors.black : Colors.white,
                      minimumSize: const Size(double.infinity, 55),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    onPressed: () {
                      int? mins = int.tryParse(timerController.text);
                      if (mins != null && mins > 0)
                        powerData.sendTimerToHardware(channel, mins);
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
    final isDark = Provider.of<PowerProvider>(context).isDarkMode;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(
          "HARDWARE CONTROL",
          style: GoogleFonts.orbitron(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Consumer<PowerProvider>(
        builder: (context, powerData, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- SECTION 1: RELAY CONTROLLER ---
                _buildSectionTitle(isDark, "RELAY CONTROLLER"),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 25),
                  decoration: BoxDecoration(
                    color:
                        isDark
                            ? Colors.white.withValues(alpha: 0.05)
                            : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDark ? Colors.white10 : Colors.black12,
                    ),
                    boxShadow:
                        isDark
                            ? []
                            : [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                              ),
                            ],
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
                        isDark,
                      ),
                      _relayItem(
                        context,
                        powerData,
                        "RELAY 2",
                        powerData.relay2,
                        2,
                        isDark,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                // --- SECTION 2: NETWORK TERMINAL ---
                _buildSectionTitle(isDark, "NETWORK TERMINAL"),
                const SizedBox(height: 10),
                _buildInfoCard(
                  context,
                  isDark,
                  icon: Icons.lan,
                  title: "MQTT BROKER",
                  value: "HiveMQ Cloud (Secure)",
                  subValue:
                      powerData.isConnected
                          ? "CONNECTED (Port 8883)"
                          : "DISCONNECTED",
                  accent:
                      powerData.isConnected
                          ? Colors.cyanAccent
                          : Colors.redAccent,
                ),

                const SizedBox(height: 30),

                // --- SECTION 3: SYSTEM ACTIONS ---
                _buildSectionTitle(isDark, "SYSTEM ACTIONS"),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _buildActionButton(
                        context,
                        isDark,
                        "EMERGENCY OFF",
                        Icons.power_off,
                        Colors.redAccent,
                        () {
                          powerData.toggleRelay(1, false);
                          powerData.toggleRelay(2, false);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildActionButton(
                        context,
                        isDark,
                        "REFRESH PMS",
                        Icons.refresh,
                        Colors.orangeAccent,
                        () => powerData.refreshData(),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 40),
                Center(
                  child: Text(
                    "PMS FIRMWARE V1.3 - ESP32 NODE",
                    style: GoogleFonts.shareTechMono(
                      fontSize: 10,
                      color: isDark ? Colors.white12 : Colors.black12,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // --- UI COMPONENTS ---

  Widget _buildSectionTitle(bool isDark, String title) {
    return Text(
      title,
      style: GoogleFonts.orbitron(
        fontSize: 10,
        letterSpacing: 1.5,
        color: isDark ? Colors.white38 : Colors.black38,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildInfoCard(
    BuildContext context,
    bool isDark, {
    required IconData icon,
    required String title,
    required String value,
    required String subValue,
    required Color accent,
  }) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: isDark ? accent : accent.withOpacity(0.8),
            size: 28,
          ),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: isDark ? Colors.white38 : Colors.black45,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                value,
                style: GoogleFonts.shareTechMono(
                  color: isDark ? Colors.white : Colors.black87,
                  fontSize: 14,
                ),
              ),
              Text(
                subValue,
                style: GoogleFonts.shareTechMono(color: accent, fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    bool isDark,
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: () {
        HapticFeedback.vibrate();
        onTap();
      },
      borderRadius: BorderRadius.circular(15),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.orbitron(
                color: color,
                fontSize: 9,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _relayItem(
    BuildContext context,
    PowerProvider powerData,
    String label,
    bool isOn,
    int channel,
    bool isDark,
  ) {
    int remaining =
        (channel == 1)
            ? powerData.remainingSecondsR1
            : powerData.remainingSecondsR2;
    String schedule =
        (channel == 1) ? powerData.scheduleR1 : powerData.scheduleR2;
    Color activeColor = isDark ? Colors.greenAccent : Colors.green[700]!;

    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.shareTechMono(
            color: isDark ? Colors.white : Colors.black87,
            fontSize: 14,
          ),
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
            activeColor: activeColor,
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
              color:
                  remaining > 0
                      ? Colors.orangeAccent
                      : (isDark ? Colors.white24 : Colors.black26),
              fontSize: 10,
            ),
          ),
          Text(
            schedule.isNotEmpty && schedule != "OFF"
                ? "SCH: $schedule"
                : "NO SCH",
            style: GoogleFonts.shareTechMono(
              color:
                  schedule.isNotEmpty && schedule != "OFF"
                      ? (isDark ? Colors.cyanAccent : Colors.cyan[800])
                      : (isDark ? Colors.white12 : Colors.black12),
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
                isDark,
              ),
              const SizedBox(width: 4),
              _timerBtn(
                context,
                "CLOCK",
                () => _selectSchedule(context, powerData, channel),
                isDark,
              ),
              const SizedBox(width: 4),
              _timerBtn(context, "X", () {
                powerData.sendTimerToHardware(channel, 0);
                powerData.sendScheduleToHardware(channel, "OFF");
              }, isDark),
            ],
          ),
        ],
      ],
    );
  }

  Widget _timerBtn(
    BuildContext context,
    String label,
    VoidCallback onTap,
    bool isDark,
  ) {
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color:
              isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.black.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isDark ? Colors.white70 : Colors.black54,
            fontSize: 9,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
