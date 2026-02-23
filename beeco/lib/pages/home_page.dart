import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/app_providers.dart';
import '../theme/app_theme.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedMonth = ref.watch(selectedMonthProvider);
    final monthlyStats = ref.watch(monthlyStatsProvider(selectedMonth));
    final transactions = ref.watch(transactionsProvider);
    final primaryColor = Color(ref.watch(primaryColorProvider));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // 顶部统计卡片
          SliverToBoxAdapter(
            child: _buildHeader(context, ref, selectedMonth, monthlyStats, primaryColor, isDark),
          ),
          
          // 快捷操作
          SliverToBoxAdapter(
            child: _buildQuickActions(context, ref, primaryColor),
          ),

          // 最近交易标题
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '最近交易',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      // TODO: 查看全部
                    },
                    child: const Text('查看全部'),
                  ),
                ],
              ),
            ),
          ),

          // 交易列表
          transactions.when(
            data: (txList) {
              if (txList.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.receipt_long_outlined,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '暂无交易记录',
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final tx = txList[index];
                    return _buildTransactionItem(context, tx, primaryColor);
                  },
                  childCount: txList.length > 10 ? 10 : txList.length,
                ),
              );
            },
            loading: () => const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (error, stack) => SliverFillRemaining(
              child: Center(
                child: Text('加载失败: $error'),
              ),
            ),
          ),

          const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
        ],
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    WidgetRef ref,
    DateTime selectedMonth,
    AsyncValue<Map<String, double>> monthlyStats,
    Color primaryColor,
    bool isDark,
  ) {
    final dateFormat = DateFormat('yyyy年MM月');
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            primaryColor,
            primaryColor.withOpacity(0.8),
          ],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // 月份选择器
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left, color: Colors.white),
                    onPressed: () {
                      ref.read(selectedMonthProvider.notifier).state =
                          DateTime(selectedMonth.year, selectedMonth.month - 1);
                    },
                  ),
                  GestureDetector(
                    onTap: () => _showMonthPicker(context, ref),
                    child: Row(
                      children: [
                        Text(
                          dateFormat.format(selectedMonth),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Icon(
                          Icons.arrow_drop_down,
                          color: Colors.white,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right, color: Colors.white),
                    onPressed: () {
                      ref.read(selectedMonthProvider.notifier).state =
                          DateTime(selectedMonth.year, selectedMonth.month + 1);
                    },
                  ),
                ],
              ),
              
              const SizedBox(height: 20),
              
              // 收支统计
              monthlyStats.when(
                data: (stats) {
                  final income = stats['income'] ?? 0;
                  final expense = stats['expense'] ?? 0;
                  final balance = income - expense;

                  return Row(
                    children: [
                      Expanded(
                        child: _buildStatCard('收入', income, Colors.green.shade400),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard('支出', expense, Colors.red.shade400),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard('结余', balance, Colors.white),
                      ),
                    ],
                  );
                },
                loading: () => const Row(
                  children: [
                    Expanded(child: _buildSkeletonCard()),
                    SizedBox(width: 12),
                    Expanded(child: _buildSkeletonCard()),
                    SizedBox(width: 12),
                    Expanded(child: _buildSkeletonCard()),
                  ],
                ),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, double amount, Color textColor) {
    final currencyFormat = NumberFormat.currency(locale: 'zh_CN', symbol: '¥');
    
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              color: textColor.withOpacity(0.9),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            currencyFormat.format(amount),
            style: TextStyle(
              color: textColor,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, WidgetRef ref, Color primaryColor) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _buildActionButton(
              context,
              '记支出',
              Icons.arrow_upward,
              Colors.red.shade400,
              () {},
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildActionButton(
              context,
              '记收入',
              Icons.arrow_downward,
              Colors.green.shade400,
              () {},
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildActionButton(
              context,
              '转账',
              Icons.swap_horiz,
              Colors.blue.shade400,
              () {},
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Material(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionItem(BuildContext context, dynamic tx, Color primaryColor) {
    final dateFormat = DateFormat('MM-dd');
    final currencyFormat = NumberFormat.currency(locale: 'zh_CN', symbol: '¥');
    
    final bool isExpense = tx.type == 'expense';
    final Color amountColor = isExpense ? Colors.red.shade400 : Colors.green.shade400;
    final String sign = isExpense ? '-' : '+';

    return ListTile(
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          isExpense ? Icons.shopping_bag_outlined : Icons.work_outline,
          color: primaryColor,
        ),
      ),
      title: Text(
        tx.category?.name ?? '未分类',
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        '${dateFormat.format(tx.happenedAt)} · ${tx.note ?? ''}',
        style: TextStyle(
          color: Colors.grey.shade500,
          fontSize: 13,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Text(
        '$sign${currencyFormat.format(tx.amount).replaceAll('¥', '')}',
        style: TextStyle(
          color: amountColor,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
      onTap: () {
        // TODO: 查看交易详情
      },
    );
  }

  void _showMonthPicker(BuildContext context, WidgetRef ref) {
    final selectedMonth = ref.read(selectedMonthProvider);
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('选择月份'),
          content: SizedBox(
            width: double.maxFinite,
            height: 300,
            child: YearPicker(
              firstDate: DateTime(2020),
              lastDate: DateTime(2030),
              selectedDate: selectedMonth,
              onChanged: (date) {
                Navigator.pop(context);
                _showMonthGrid(context, ref, date.year);
              },
            ),
          ),
        );
      },
    );
  }

  void _showMonthGrid(BuildContext context, WidgetRef ref, int year) {
    final months = List.generate(12, (index) => index + 1);
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('$year年'),
          content: SizedBox(
            width: double.maxFinite,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: months.map((month) {
                return InkWell(
                  onTap: () {
                    ref.read(selectedMonthProvider.notifier).state = 
                        DateTime(year, month);
                    Navigator.pop(context);
                  },
                  child: Container(
                    width: 60,
                    height: 48,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('$month月'),
                  ),
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }
}

class _buildSkeletonCard extends StatelessWidget {
  const _buildSkeletonCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Column(
        children: [
          SizedBox(height: 14, width: 40),
          SizedBox(height: 8),
          SizedBox(height: 16, width: 80),
        ],
      ),
    );
  }
}
