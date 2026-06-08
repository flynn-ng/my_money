import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_theme.dart';
import '../../../reports/data/reports_repository.dart';

class MonthlyBarChart extends StatelessWidget {
  final List<MonthlyTotal> data;
  const MonthlyBarChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const SizedBox.shrink();

    final maxY = data.fold<double>(
        0, (m, d) => d.income > m ? d.income : (d.expense > m ? d.expense : m));

    return SizedBox(
      height: 200,
      child: BarChart(
        BarChartData(
          maxY: maxY * 1.2,
          barGroups: data.asMap().entries.map((entry) {
            final i = entry.key;
            final d = entry.value;
            return BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                    toY: d.income, color: AppColors.green, width: 10,
                    borderRadius: BorderRadius.circular(4)),
                BarChartRodData(
                    toY: d.expense, color: AppColors.red, width: 10,
                    borderRadius: BorderRadius.circular(4)),
              ],
              barsSpace: 4,
            );
          }).toList(),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, _) {
                  final i = value.toInt();
                  if (i < 0 || i >= data.length) return const SizedBox.shrink();
                  return Text(
                    DateFormat('MMM', 'vi').format(data[i].month),
                    style: TextStyle(
                        fontSize: 10, color: context.colors.textSecondary),
                  );
                },
              ),
            ),
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: FlGridData(
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) =>
                FlLine(color: context.colors.divider, strokeWidth: 1),
          ),
          borderData: FlBorderData(show: false),
        ),
      ),
    );
  }
}
