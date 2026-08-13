import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/power_provider.dart';

class DcMonitorSection extends StatelessWidget {
  final PowerProvider powerData;
  final bool isDark;

  // UPGRADE: Pake Super Parameter (Bantai Warning Key)
  const DcMonitorSection({
    super.key,
    required this.powerData,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    Color batColor =
        powerData.batStatus > 60
            ? (isDark ? Colors.greenAccent : Colors.green[700]!)
            : (powerData.batStatus > 20
                ? Colors.orangeAccent
                : Colors.redAccent);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        // UPGRADE: Pake withValues() biar linter modern seneng
        color:
            isDark
                ? Colors.white.withValues(alpha: 0.02)
                : Colors.black.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.battery_charging_full,
                color: Colors.orangeAccent,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                "DC PARAMETERS & BATTERY STATUS",
                style: GoogleFonts.orbitron(
                  color: isDark ? Colors.white38 : Colors.black38,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.2,
            children: [
              _buildDataCard(
                context,
                "DC VOLTAGE",
                powerData.voltageDC.toStringAsFixed(2),
                "V",
                Colors.orangeAccent,
              ),
              _buildDataCard(
                context,
                "DC CURRENT",
                powerData.currentDC.toStringAsFixed(3),
                "A",
                Colors.greenAccent,
              ),
              _buildDataCard(
                context,
                "DC POWER",
                powerData.powerDC.toStringAsFixed(2),
                "W",
                Colors.cyanAccent,
              ),
              _buildDataCard(
                context,
                "BATTERY",
                "${powerData.batStatus}",
                "%",
                batColor,
              ),
            ],
          ),
        ],
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
                    color: Colors.black.withValues(alpha: 0.05),
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
              color: isDark ? Colors.white54 : Colors.black54,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.shareTechMono(
              // FIX CRITICAL BUG: Colors.whiteAccent dihapus, diganti check aman murni
              color:
                  isDark
                      ? color
                      : (color == Colors.white ? Colors.black87 : color),
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            unit,
            style: TextStyle(
              color:
                  isDark
                      ? color.withValues(alpha: 0.8)
                      : color.withValues(alpha: 1.0),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
