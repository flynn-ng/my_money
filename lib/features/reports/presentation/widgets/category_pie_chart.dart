import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/l10n/app_strings.dart';
import '../../../../core/extensions/currency_ext.dart';
import '../../../reports/data/reports_repository.dart';

class CategoryPieChart extends StatefulWidget {
  final List<CategorySpending> data;
  const CategoryPieChart({super.key, required this.data});

  @override
  State<CategoryPieChart> createState() => _CategoryPieChartState();
}

class _CategoryPieChartState extends State<CategoryPieChart> {
  int _touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    if (widget.data.isEmpty) {
      return Center(
        child: Text(S.noSpendingData,
            style: const TextStyle(color: AppColors.textSecondary)),
      );
    }

    final total = widget.data.fold<double>(0, (s, d) => s + d.amount);

    return Column(
      children: [
        SizedBox(
          height: 220,
          child: PieChart(
            PieChartData(
              pieTouchData: PieTouchData(
                touchCallback: (event, response) {
                  setState(() {
                    _touchedIndex = response?.touchedSection?.touchedSectionIndex ?? -1;
                  });
                },
              ),
              sections: widget.data.asMap().entries.map((entry) {
                final i = entry.key;
                final d = entry.value;
                final isTouched = i == _touchedIndex;
                final color = AppColors.fromHex(d.categoryColor);
                return PieChartSectionData(
                  color: color,
                  value: d.amount,
                  radius: isTouched ? 60 : 50,
                  title: isTouched
                      ? '${(d.amount / total * 100).toStringAsFixed(0)}%'
                      : '',
                  titleStyle: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 13),
                );
              }).toList(),
              centerSpaceRadius: 50,
              sectionsSpace: 2,
            ),
          ),
        ),
        if (_touchedIndex >= 0 && _touchedIndex < widget.data.length) ...[
          const SizedBox(height: 8),
          Text(
            '${widget.data[_touchedIndex].categoryIcon} ${widget.data[_touchedIndex].categoryName}: ${widget.data[_touchedIndex].amount.asCurrency}',
            style: AppTextStyles.bodyLarge,
          ),
        ],
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: widget.data.map((d) {
            final color = AppColors.fromHex(d.categoryColor);
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                    width: 10,
                    height: 10,
                    decoration:
                        BoxDecoration(color: color, shape: BoxShape.circle)),
                const SizedBox(width: 4),
                Text('${d.categoryIcon} ${d.categoryName}',
                    style: AppTextStyles.labelSmall),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }

}
