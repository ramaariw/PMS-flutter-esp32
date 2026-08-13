import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../providers/power_provider.dart';

class EnergyAnalyticsSection extends StatefulWidget {
  final PowerProvider powerData;
  final bool isDark;

  // FIX WARNING: Pakai super parameter (Bantai Warning Baris 10)
  const EnergyAnalyticsSection({
    super.key,
    required this.powerData,
    required this.isDark,
  });

  @override
  State<EnergyAnalyticsSection> createState() => _EnergyAnalyticsSectionState();
}

class _EnergyAnalyticsSectionState extends State<EnergyAnalyticsSection> {
  String _selectedTimeFilter = "5 Min";
  final TextEditingController _tarifController = TextEditingController();

  void _showTarifDialog(BuildContext context, PowerProvider powerData) {
    _tarifController.text = powerData.customTarif.toStringAsFixed(2);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor:
              widget.isDark ? const Color(0xFF1E1E1E) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: Text(
            "SET CUSTOM TARIF PLN",
            style: GoogleFonts.orbitron(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: widget.isDark ? Colors.white : Colors.black87,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Masukkan tarif dasar listrik per kWh yang ter-update:",
                style: TextStyle(fontSize: 12, color: Colors.white54),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _tarifController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                style: GoogleFonts.shareTechMono(fontSize: 18),
                decoration: InputDecoration(
                  prefixText: "Rp ",
                  suffixText: "/kWh",
                  filled: true,
                  fillColor: widget.isDark ? Colors.white10 : Colors.black12,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("CANCEL", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
              ),
              onPressed: () {
                double? parsedTarif = double.tryParse(_tarifController.text);
                if (parsedTarif != null && parsedTarif > 0) {
                  powerData.updateTarif(parsedTarif);
                }
                Navigator.pop(context);
              },
              child: const Text(
                "SAVE",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _tarifController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final powerData = widget.powerData;

    String currentWattLabel = "${powerData.watt.toStringAsFixed(1)} W";

    double maxInHistory = powerData.wattHistory.reduce(
      (curr, next) => curr > next ? curr : next,
    );

    // FIX WARNING: Bungkus if logic pake kurung kurawal {} biar linter anteng (Baris 265 & 273)
    double calculatedMaxY = maxInHistory > 0 ? maxInHistory * 1.2 : 10.0;
    if (calculatedMaxY > 900.0) {
      calculatedMaxY = 900.0;
    }

    double estimasiBiayaRupiah = powerData.kwh * powerData.customTarif;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        // FIX WARNING: Pake withValues() gantiin withOpacity() baris 131 & 132
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
                Icons.analytics_outlined,
                color: Colors.redAccent,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                "ENERGY ANALYTICS & MANAGEMENT",
                style: GoogleFonts.orbitron(
                  color: isDark ? Colors.white70 : Colors.black87,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // FILTER TIMELINE
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Row(
              children:
                  [
                    "5 Min",
                    "15 Min",
                    "30 Min",
                    "1 Hour",
                    "6 Hour",
                    "12 Hour",
                    "24 Hour",
                  ].map((time) {
                    bool isSelected = _selectedTimeFilter == time;
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _selectedTimeFilter = time;
                          });
                          powerData.setSelectedTimeFilter(time);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color:
                                isSelected
                                    ? Colors.redAccent
                                    : (isDark
                                        ? Colors.white10
                                        : Colors.black12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            time,
                            style: TextStyle(
                              color:
                                  isSelected
                                      ? Colors.white
                                      : (isDark
                                          ? Colors.white70
                                          : Colors.black87),
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
            ),
          ),

          // WATT LINE CHART
          Container(
            height: 160,
            padding: const EdgeInsets.fromLTRB(5, 10, 10, 5),
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine:
                      (value) => FlLine(
                        color: isDark ? Colors.white10 : Colors.black12,
                        strokeWidth: 1,
                        dashArray: [5, 5],
                      ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 45,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          "${value.toInt()}W",
                          style: TextStyle(
                            color: isDark ? Colors.white30 : Colors.black38,
                            fontSize: 9,
                            fontFamily: 'monospace',
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      getTitlesWidget: (value, meta) {
                        if (value == 0) {
                          return Text(
                            "PAST",
                            style: TextStyle(
                              color: isDark ? Colors.white24 : Colors.black26,
                              fontSize: 8,
                            ),
                          );
                        }
                        if (value == 9) {
                          return Text(
                            "NOW",
                            style: TextStyle(
                              // FIX WARNING: Pake withValues() gantiin withOpacity() baris 276
                              color: Colors.redAccent.withValues(alpha: 0.7),
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        }
                        return const Text("");
                      },
                    ),
                  ),
                ),
                minX: 0,
                maxX: 9,
                minY: 0,
                maxY: calculatedMaxY,
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
                      // FIX WARNING: Pake withValues() gantiin withOpacity() baris 304
                      color: Colors.redAccent.withValues(alpha: 0.12),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Divider(color: Colors.white10, height: 1),
          ),

          // AREA KEUANGAN
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          "ACCUMULATED COST (EST.)",
                          style: GoogleFonts.orbitron(
                            color: isDark ? Colors.white30 : Colors.black38,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 4),
                        InkWell(
                          onTap: () => _showTarifDialog(context, powerData),
                          borderRadius: BorderRadius.circular(5),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Icon(
                              Icons.settings,
                              color: isDark ? Colors.white30 : Colors.black38,
                              size: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "Rp ${estimasiBiayaRupiah.toStringAsFixed(2)}",
                      style: GoogleFonts.shareTechMono(
                        color: isDark ? Colors.tealAccent : Colors.teal[700]!,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "@ Rp ${powerData.customTarif.toStringAsFixed(1)}/kWh",
                      style: TextStyle(
                        color: isDark ? Colors.white30 : Colors.black38,
                        fontSize: 9,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      "CURRENT LOAD",
                      style: GoogleFonts.orbitron(
                        color: isDark ? Colors.white38 : Colors.black38,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      currentWattLabel,
                      style: GoogleFonts.shareTechMono(
                        color: Colors.redAccent,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
