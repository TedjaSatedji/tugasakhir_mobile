import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../core/constants/app_colors.dart';
import '../../core/extensions/theme_extensions.dart';
import '../../models/transaction_model.dart';
import '../../providers/stats_provider.dart';
import '../../providers/transaction_provider.dart';
import 'transactions_list_screen.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _fmt = NumberFormat('#,##0', 'en_US');

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Feed transactions into StatsProvider reactively
    return Consumer2<TransactionProvider, StatsProvider>(
      builder: (context, txProvider, statsProvider, _) {
        statsProvider.updateTransactions(txProvider.transactions);

        return Scaffold(
          appBar: AppBar(
            title: Text('statsTitle'.tr()),
            bottom: TabBar(
              controller: _tabController,
              labelColor: context.primary,
              unselectedLabelColor: context.textDim,
              indicatorColor: context.primary,
              tabs: [
                Tab(text: 'daily'.tr()),
                Tab(text: 'monthly'.tr()),
                Tab(text: 'categories'.tr()),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _DailyTab(statsProvider: statsProvider, fmt: _fmt),
              _MonthlyTab(statsProvider: statsProvider, fmt: _fmt),
              _CategoryTab(statsProvider: statsProvider, fmt: _fmt),
            ],
          ),
        );
      },
    );
  }
}

// ── Daily Tab ─────────────────────────────────────────────────────────────────
class _DailyTab extends StatelessWidget {
  final StatsProvider statsProvider;
  final NumberFormat fmt;
  const _DailyTab({required this.statsProvider, required this.fmt});

  @override
  Widget build(BuildContext context) {
    final days = statsProvider.last7DaysStats;
    final maxVal = days.fold(0.0, (m, d) => d.income > m ? d.income : m);
    final expMax = days.fold(0.0, (m, d) => d.expense > m ? d.expense : m);
    final chartMax = (maxVal > expMax ? maxVal : expMax) * 1.2;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary cards
          Row(
            children: [
              _SummaryCard(
                label: 'thisMonth'.tr(),
                value: 'Rp${fmt.format(statsProvider.thisMonthIncome)}',
                icon: Icons.arrow_downward_rounded,
                color: AppColors.success,
              ),
              const SizedBox(width: 12),
              _SummaryCard(
                label: 'thisMonthExp'.tr(),
                value: 'Rp${fmt.format(statsProvider.thisMonthExpense)}',
                icon: Icons.arrow_upward_rounded,
                color: AppColors.error,
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Savings rate card
          _SavingsRateCard(
            rate: statsProvider.savingsRate,
            income: statsProvider.thisMonthIncome,
            expense: statsProvider.thisMonthExpense,
            fmt: fmt,
          ),
          const SizedBox(height: 24),
          Text(
            'last7Days'.tr(),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              fontFamily: 'Poppins',
              color: context.text,
            ),
          ),
          const SizedBox(height: 16),
          if (chartMax <= 0)
            _EmptyChart()
          else
            SizedBox(
              height: 220,
              child: BarChart(
                BarChartData(
                  maxY: chartMax,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (_) => FlLine(
                      color: context.textDim.withOpacity(0.15),
                      strokeWidth: 1,
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (val, _) {
                          final idx = val.toInt();
                          if (idx < 0 || idx >= days.length) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              DateFormat('E').format(days[idx].date),
                              style: TextStyle(
                                fontSize: 10,
                                color: context.textDim,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  barGroups: List.generate(days.length, (i) {
                    final d = days[i];
                    return BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: d.income,
                          color: AppColors.success.withOpacity(0.85),
                          width: 10,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(4),
                          ),
                        ),
                        BarChartRodData(
                          toY: d.expense,
                          color: AppColors.error.withOpacity(0.85),
                          width: 10,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(4),
                          ),
                        ),
                      ],
                      barsSpace: 4,
                    );
                  }),
                ),
              ),
            ),
          const SizedBox(height: 12),
          _ChartLegend(),
          const SizedBox(height: 24),
          // Daily list
          Text(
            'dailyBreakdown'.tr(),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              fontFamily: 'Poppins',
              color: context.text,
            ),
          ),
          const SizedBox(height: 12),
          ...days.reversed.map((d) => _DailyRow(day: d, fmt: fmt)),
        ],
      ),
    );
  }
}

// ── Monthly Tab ───────────────────────────────────────────────────────────────
class _MonthlyTab extends StatelessWidget {
  final StatsProvider statsProvider;
  final NumberFormat fmt;
  const _MonthlyTab({required this.statsProvider, required this.fmt});

  @override
  Widget build(BuildContext context) {
    final months = statsProvider.last6MonthsStats;
    final maxIncome = months.fold(0.0, (m, s) => s.income > m ? s.income : m);
    final maxExpense = months.fold(0.0, (m, s) => s.expense > m ? s.expense : m);
    final chartMax = (maxIncome > maxExpense ? maxIncome : maxExpense) * 1.2;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'last6Months'.tr(),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              fontFamily: 'Poppins',
              color: context.text,
            ),
          ),
          const SizedBox(height: 16),
          if (chartMax <= 0)
            _EmptyChart()
          else
            SizedBox(
              height: 220,
              child: LineChart(
                LineChartData(
                  maxY: chartMax,
                  minY: 0,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (_) => FlLine(
                      color: context.textDim.withOpacity(0.15),
                      strokeWidth: 1,
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (val, _) {
                          final idx = val.toInt();
                          if (idx < 0 || idx >= months.length) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              months[idx].label,
                              style: TextStyle(
                                fontSize: 10,
                                color: context.textDim,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: List.generate(months.length,
                          (i) => FlSpot(i.toDouble(), months[i].income)),
                      isCurved: true,
                      color: AppColors.success,
                      barWidth: 3,
                      dotData: FlDotData(
                        getDotPainter: (_, __, ___, ____) =>
                            FlDotCirclePainter(
                          radius: 4,
                          color: AppColors.success,
                          strokeWidth: 2,
                          strokeColor: Colors.white,
                        ),
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        color: AppColors.success.withOpacity(0.12),
                      ),
                    ),
                    LineChartBarData(
                      spots: List.generate(months.length,
                          (i) => FlSpot(i.toDouble(), months[i].expense)),
                      isCurved: true,
                      color: AppColors.error,
                      barWidth: 3,
                      dotData: FlDotData(
                        getDotPainter: (_, __, ___, ____) =>
                            FlDotCirclePainter(
                          radius: 4,
                          color: AppColors.error,
                          strokeWidth: 2,
                          strokeColor: Colors.white,
                        ),
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        color: AppColors.error.withOpacity(0.10),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 12),
          _ChartLegend(),
          const SizedBox(height: 24),
          Text(
            'monthlyBreakdown'.tr(),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              fontFamily: 'Poppins',
              color: context.text,
            ),
          ),
          const SizedBox(height: 12),
          ...months.reversed.map((m) => _MonthlyRow(month: m, fmt: fmt)),
        ],
      ),
    );
  }
}

// ── Category Tab ──────────────────────────────────────────────────────────────
class _CategoryTab extends StatelessWidget {
  final StatsProvider statsProvider;
  final NumberFormat fmt;
  const _CategoryTab({required this.statsProvider, required this.fmt});

  static const _categoryColors = [
    Color(0xFF6366F1),
    Color(0xFFF59E0B),
    Color(0xFF10B981),
    Color(0xFFEF4444),
    Color(0xFF3B82F6),
    Color(0xFFD500F9),
    Color(0xFFFB923C),
    Color(0xFF14B8A6),
  ];

  static const _categoryIcons = {
    ExpenseCategory.food: Icons.restaurant,
    ExpenseCategory.fashion: Icons.shopping_bag,
    ExpenseCategory.hobby: Icons.sports_esports,
    ExpenseCategory.transport: Icons.directions_car,
    ExpenseCategory.health: Icons.health_and_safety,
    ExpenseCategory.education: Icons.school,
    ExpenseCategory.entertainment: Icons.movie,
    ExpenseCategory.other: Icons.more_horiz,
  };

  @override
  Widget build(BuildContext context) {
    final cats = statsProvider.categoryBreakdown;
    final total = cats.fold(0.0, (s, c) => s + c.total);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'expenseByCategory'.tr(),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              fontFamily: 'Poppins',
              color: context.text,
            ),
          ),
          const SizedBox(height: 20),
          if (cats.isEmpty)
            _EmptyChart()
          else ...[
            SizedBox(
              height: 220,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 3,
                  centerSpaceRadius: 55,
                  sections: List.generate(cats.length, (i) {
                    final pct = total > 0 ? cats[i].total / total * 100 : 0.0;
                    return PieChartSectionData(
                      value: cats[i].total,
                      color: _categoryColors[i % _categoryColors.length],
                      title: '${pct.toStringAsFixed(0)}%',
                      radius: 60,
                      titleStyle: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontFamily: 'Poppins',
                      ),
                    );
                  }),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'breakdown'.tr(),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                fontFamily: 'Poppins',
                color: context.text,
              ),
            ),
            const SizedBox(height: 12),
            ...List.generate(cats.length, (i) {
              final c = cats[i];
              final pct = total > 0 ? c.total / total : 0.0;
              final color = _categoryColors[i % _categoryColors.length];
              final icon = _categoryIcons[c.category] ?? Icons.more_horiz;
              return _CategoryRow(
                icon: icon,
                label: c.category.name,
                amount: fmt.format(c.total),
                pct: pct,
                color: color,
              );
            }),
          ],
        ],
      ),
    );
  }
}

// ── Reusable Widgets ──────────────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _SummaryCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: context.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 16),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      color: context.textDim,
                      fontFamily: 'Poppins',
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
                fontFamily: 'Poppins',
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _SavingsRateCard extends StatelessWidget {
  final double rate;
  final double income;
  final double expense;
  final NumberFormat fmt;
  const _SavingsRateCard({
    required this.rate,
    required this.income,
    required this.expense,
    required this.fmt,
  });

  @override
  Widget build(BuildContext context) {
    final saved = income - expense;
    final color = rate >= 20
        ? AppColors.success
        : rate >= 10
            ? AppColors.warning
            : AppColors.error;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.15), color.withOpacity(0.05)],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'savingsRate'.tr(),
                style: TextStyle(
                  fontSize: 13,
                  color: context.textDim,
                  fontFamily: 'Poppins',
                ),
              ),
              Text(
                '${rate.toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: color,
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: rate / 100,
              backgroundColor: context.textDim.withOpacity(0.15),
              color: color,
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            saved >= 0
                ? '${'saved'.tr()}: Rp${fmt.format(saved)}'
                : '${'overspent'.tr()}: Rp${fmt.format(saved.abs())}',
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _DailyRow extends StatelessWidget {
  final DailyStats day;
  final NumberFormat fmt;
  const _DailyRow({required this.day, required this.fmt});

  @override
  Widget build(BuildContext context) {
    final isToday = DateUtils.isSameDay(day.date, DateTime.now());
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TransactionsListScreen(
              title: DateFormat('EEE, d MMM yyyy').format(day.date),
              filterDay: day.date,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: context.card,
          borderRadius: BorderRadius.circular(12),
          border: isToday
              ? Border.all(color: context.primary.withOpacity(0.5))
              : null,
        ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                DateFormat('EEE, d MMM').format(day.date),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Poppins',
                  color: isToday ? context.primary : context.text,
                ),
              ),
              if (isToday)
                Text(
                  'today'.tr(),
                  style: TextStyle(
                    fontSize: 10,
                    color: context.primary,
                    fontFamily: 'Poppins',
                  ),
                ),
            ],
          ),
          const Spacer(),
          if (day.income > 0)
            Text(
              '+Rp${fmt.format(day.income)}',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.success,
                fontWeight: FontWeight.w600,
                fontFamily: 'Poppins',
              ),
            ),
          if (day.income > 0 && day.expense > 0)
            const SizedBox(width: 10),
          if (day.expense > 0)
            Text(
              '-Rp${fmt.format(day.expense)}',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.error,
                fontWeight: FontWeight.w600,
                fontFamily: 'Poppins',
              ),
            ),
          if (day.income == 0 && day.expense == 0)
            Text(
              'noActivity'.tr(),
              style: TextStyle(
                fontSize: 12,
                color: context.textDim,
                fontFamily: 'Poppins',
              ),
            ),
        ],
      ),
    ),
    );
  }
}

class _MonthlyRow extends StatelessWidget {
  final MonthlyStats month;
  final NumberFormat fmt;
  const _MonthlyRow({required this.month, required this.fmt});

  @override
  Widget build(BuildContext context) {
    final net = month.net;
    final netColor = net >= 0 ? AppColors.success : AppColors.error;
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TransactionsListScreen(
              title: '${month.label} ${month.year}',
              filterMonth: month.month,
              filterYear: month.year,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: context.card,
          borderRadius: BorderRadius.circular(12),
        ),
      child: Row(
        children: [
          Text(
            '${month.label} ${month.year}',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              fontFamily: 'Poppins',
              color: context.text,
            ),
          ),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Rp${fmt.format(month.income)}',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.success,
                  fontFamily: 'Poppins',
                ),
              ),
              Text(
                'Rp${fmt.format(month.expense)}',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.error,
                  fontFamily: 'Poppins',
                ),
              ),
              Text(
                '${net >= 0 ? '+' : ''}Rp${fmt.format(net)}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: netColor,
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
        ],
      ),
    ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String amount;
  final double pct;
  final Color color;
  const _CategoryRow({
    required this.icon,
    required this.label,
    required this.amount,
    required this.pct,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: context.card,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Poppins',
                    color: context.text,
                  ),
                ),
              ),
              Text(
                'Rp$amount',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: color,
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              backgroundColor: context.textDim.withOpacity(0.15),
              color: color,
              minHeight: 5,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChartLegend extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _LegendDot(color: AppColors.success, label: 'income'.tr()),
        const SizedBox(width: 16),
        _LegendDot(color: AppColors.error, label: 'expense'.tr()),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: context.textDim,
            fontFamily: 'Poppins',
          ),
        ),
      ],
    );
  }
}

class _EmptyChart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 140,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: context.card,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bar_chart, color: context.textDim, size: 40),
          const SizedBox(height: 8),
          Text(
            'noDataYet'.tr(),
            style: TextStyle(
              color: context.textDim,
              fontFamily: 'Poppins',
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
