import 'package:flutter/material.dart';

class MonthlyTransactionCalendar extends StatelessWidget {
  final Map<int, Map<String, double>> dailyStats;
  final int year;
  final int month;

  const MonthlyTransactionCalendar({
    super.key,
    required this.dailyStats,
    required this.year,
    required this.month,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final firstDayOfMonth = DateTime(year, month, 1);
    final lastDayOfMonth = DateTime(year, month + 1, 0).day;
    
    // Weekday offset
    final startOffset = firstDayOfMonth.weekday - 1;

    // --- AESTHETIC CONTROLS (GRID) ---
    const double horizontalPadding = 40.0; // 👈 Larger boxes! (Reduced from 110)
    const double gridSpacing = 4.0;         // 👈 Slightly more air
    const double boxShape = 1.0;            // 👈 Perfect square

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 8),
      child: Column(
        children: [
          // Days of week header
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: ['M', 'T', 'W', 'T', 'F', 'S', 'S']
                  .map((d) => Text(d, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Colors.grey)))
                  .toList(),
            ),
          ),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: gridSpacing,
              crossAxisSpacing: gridSpacing,
              childAspectRatio: boxShape,
            ),
            itemCount: startOffset + lastDayOfMonth,
            itemBuilder: (context, index) {
              if (index < startOffset) {
                return const SizedBox();
              }

              final day = index - startOffset + 1;
              final stats = dailyStats[day];
              
              bool isFuture = false;
              if (year > now.year) {
                isFuture = true;
              } else if (year == now.year && month > now.month) {
                isFuture = true;
              } else if (year == now.year && month == now.month && day > now.day) {
                isFuture = true;
              }

              return _CalendarCell(
                day: day,
                income: stats?['income'] ?? 0.0,
                expense: stats?['expense'] ?? 0.0,
                isFuture: isFuture,
              );
            },
          ),
        ],
      ),
    );
  }
}

class _CalendarCell extends StatelessWidget {
  final int day;
  final double income;
  final double expense;
  final bool isFuture;

  const _CalendarCell({
    required this.day,
    required this.income,
    required this.expense,
    required this.isFuture,
  });

  @override
  Widget build(BuildContext context) {
    final total = income + expense;
    double incomePercent = total > 0 ? (income / total) : 0.0;
    double expensePercent = total > 0 ? (expense / total) : 0.0;

    final bool isEmptyPast = !isFuture && total == 0;
    final bool isHeatmap = !isFuture && total > 0;

    // --- AESTHETIC CONTROLS (CELLS) ---
    const double dayTextSize = 13.0;       // 👈 Adjusted for better fit in larger boxes
    const double cornerRadius = 6.0;      // 👈 Roundness of corners
    const double colorIntensity = 0.9;    // 👈 0.0 to 1.0 (vibrancy of fills)

    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

    final Color heatmapTextColor = isDark ? Colors.black : Colors.white;
    final Color otherTextColor = isDark ? Colors.grey : Colors.black87;

    return Container(
      decoration: BoxDecoration(
        color: isHeatmap 
            ? null 
            : isEmptyPast 
                ? Colors.grey.withValues(alpha: 0.12) 
                : isFuture 
                    ? Colors.grey.withValues(alpha: 0.06) 
                    : Colors.white.withValues(alpha: isDark ? 0.05 : 1.0),
        borderRadius: BorderRadius.circular(cornerRadius),
        border: Border.all(
          color: isHeatmap ? Colors.black.withValues(alpha: 0.1) : Colors.transparent,
          width: 0.5,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          if (isHeatmap)
            Column(
              children: [
                Expanded(
                  flex: (incomePercent * 100).toInt(),
                  child: Container(color: Colors.green.withValues(alpha: colorIntensity)),
                ),
                Expanded(
                  flex: (expensePercent * 100).toInt(),
                  child: Container(color: Colors.red.withValues(alpha: colorIntensity)),
                ),
              ],
            ),
          Center(
            child: Text(
              day.toString(),
              style: TextStyle(
                fontSize: dayTextSize,
                fontWeight: FontWeight.bold,
                color: isHeatmap ? heatmapTextColor : otherTextColor,
                shadows: isHeatmap && !isDark ? [const Shadow(color: Colors.black26, blurRadius: 1)] : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
