import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/power_provider.dart';

class AcMonitorSection extends StatelessWidget {
  final PowerProvider powerData;
  final bool isDark;

  // FIX WARNING: Pake super parameter bawaan Dart modern
  const AcMonitorSection({
    super.key,
    required this.powerData,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    // FIX WARNING: Pake withValues() biar engine render baru gak ngeluh drop presisi
    final cardColor =
        isDark
            ? Colors.white.withValues(alpha: 0.02)
            : Colors.black.withValues(alpha: 0.02);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.bolt, color: Colors.blueAccent, size: 18),
              const SizedBox(width: 8),
              Text(
                "AC PARAMETERS (PLN / INVERTER)",
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
              // FIX BUG: Teks label dinamis biar gak ilang pas light mode
              color: isDark ? Colors.white54 : Colors.black54,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.shareTechMono(
              color: color,
              fontSize:
                  30, // Dikit dikompakin dari 34 ke 30 biar aman di layar HP 5.5 inch
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
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
