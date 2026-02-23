import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../providers/app_providers.dart';

class StatsPage extends ConsumerWidget {
  const StatsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedMonth = ref.watch(selectedMonthProvider);
    final monthlyStats = ref.watch(monthlyStatsProvider(selectedMonth));
    final expenseStats = ref.watch(categoryStatsProvider({
      'year': selectedMonth.year,
      'month': selectedMonth.month,
      'type': 'expense',
    }));
    final primaryColor = Color(ref.watch(primaryColorProvider));

    return Scaffold(
      appBar: AppBar(
        title: const Text('收支统计'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 月份选择
            _buildMonthSelector(context, ref, selectedMonth),
            
            const SizedBox(height: 24),
            
            // 收支概览
            monthlyStats.when(
              data: (stats) => _buildOverviewCard(stats, primaryColor),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const Text('加载失败'),
            ),
            
            const SizedBox(height: 24),
            
            // 支出分类饼图
            expenseStats.when(
              data: (stats) {
                if (stats.isEmpty) {
                  return const _EmptyStatsWidget();
                }
                return _buildExpenseChart(stats, primaryColor);
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const Text('加载失败'),
            ),
            
            const SizedBox(height: 24),
            
            // 分类排行
            expenseStats.when(
              data: (stats) {
                if (stats.isEmpty) return const SizedBox.shrink();
                return _buildCategoryRanking(stats);
              },
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthSelector(BuildContext context, WidgetRef ref, DateTime selectedMonth) {
    final dateFormat = DateFormat('yyyy年MM月');
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () {
              ref.read(selectedMonthProvider.notifier).state =
                  DateTime(selectedMonth.year, selectedMonth.month - 1);
            },
          ),
          Text(
            dateFormat.format(selectedMonth),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () {
              ref.read(selectedMonthProvider.notifier).state =
                  DateTime(selectedMonth.year, selectedMonth.month + 1);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewCard(Map<String, double> stats, Color primaryColor) {
    final currencyFormat = NumberFormat.currency(locale: 'zh_CN', symbol: '¥');
    final income = stats['income'] ?? 0;
    final expense = stats['expense'] ?? 0;
    final balance = income - expense;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            primaryColor,
            primaryColor.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            '本月结余',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            currencyFormat.format(balance),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildMiniStat('收入', income, Icons.arrow_downward, Colors.green.shade300),
              ),
              Container(
                width: 1,
                height: 40,
                color: Colors.white24,
              ),
              Expanded(
                child: _buildMiniStat('支出', expense, Icons.arrow_upward, Colors.red.shade300),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, double amount, IconData icon, Color color) {
    final currencyFormat = NumberFormat.currency(locale: 'zh_CN', symbol: '¥');
    
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          currencyFormat.format(amount),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildExpenseChart(List<Map<String, dynamic>> stats, Color primaryColor) {
    if (stats.isEmpty) return const SizedBox.shrink();

    final total = stats.fold<double>(0, (sum, item) => sum + (item['total'] as num).toDouble());
    
    final sections = stats.asMap().entries.map((entry) {
      final index = entry.key;
      final item = entry.value;
      final value = (item['total'] as num).toDouble();
      final percentage = total > 0 ? (value / total * 100) : 0;
      final color = _getChartColor(index);

      return PieChartSectionData(
        color: color,
        value: value,
        title: '${percentage.toStringAsFixed(1)}%',
        radius: 80,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        badgeWidget: Icon(
          _getIconData(item['icon'] as String?),
          color: Colors.white,
          size: 16,
        ),
        badgePositionPercentageOffset: 1.2,
      );
    }).toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '支出构成',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sections: sections,
                sectionsSpace: 2,
                centerSpaceRadius: 40,
                pieTouchData: PieTouchData(enabled: false),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryRanking(List<Map<String, dynamic>> stats) {
    final currencyFormat = NumberFormat.currency(locale: 'zh_CN', symbol: '¥');
    final total = stats.fold<double>(0, (sum, item) => sum + (item['total'] as num).toDouble());
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '分类排行',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...stats.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            final value = (item['total'] as num).toDouble();
            final percentage = total > 0 ? (value / total) : 0;
            final color = _getChartColor(index);

            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          _getIconData(item['icon'] as String?),
                          color: color,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['name'] as String,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${(percentage * 100).toStringAsFixed(1)}%',
                              style: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        currencyFormat.format(value),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: percentage,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                    minHeight: 6,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Color _getChartColor(int index) {
    final colors = [
      Colors.red.shade400,
      Colors.orange.shade400,
      Colors.amber.shade600,
      Colors.green.shade400,
      Colors.blue.shade400,
      Colors.indigo.shade400,
      Colors.purple.shade400,
      Colors.pink.shade400,
    ];
    return colors[index % colors.length];
  }

  IconData _getIconData(String? iconName) {
    final iconMap = {
      'restaurant': Icons.restaurant,
      'directions_car': Icons.directions_car,
      'shopping_cart': Icons.shopping_cart,
      'movie': Icons.movie,
      'local_hospital': Icons.local_hospital,
      'school': Icons.school,
      'home': Icons.home,
      'more_horiz': Icons.more_horiz,
      'work': Icons.work,
      'card_giftcard': Icons.card_giftcard,
      'trending_up': Icons.trending_up,
      'timer': Icons.timer,
      'payments': Icons.payments,
      'account_balance': Icons.account_balance,
      'credit_card': Icons.credit_card,
    };
    return iconMap[iconName] ?? Icons.category;
  }
}

class _EmptyStatsWidget extends StatelessWidget {
  const _EmptyStatsWidget();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Icon(
            Icons.pie_chart_outline,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            '暂无支出数据',
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}
