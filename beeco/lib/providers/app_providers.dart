import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import '../data/dao.dart';

// 当前账本ID
final currentLedgerIdProvider = StateProvider<int>((ref) => 1);

// 账本列表
final ledgersProvider = FutureProvider<List<Ledger>>((ref) async {
  final dao = LedgerDao();
  return await dao.getAll();
});

// 当前账本
final currentLedgerProvider = FutureProvider<Ledger?>((ref) async {
  final ledgerId = ref.watch(currentLedgerIdProvider);
  final dao = LedgerDao();
  return await dao.getById(ledgerId);
});

// 账本账户列表
final accountsProvider = FutureProvider<List<Account>>((ref) async {
  final ledgerId = ref.watch(currentLedgerIdProvider);
  final dao = AccountDao();
  return await dao.getByLedgerId(ledgerId);
});

// 账本分类列表
final categoriesProvider = FutureProvider<List<Category>>((ref) async {
  final ledgerId = ref.watch(currentLedgerIdProvider);
  final dao = CategoryDao();
  return await dao.getByLedgerId(ledgerId);
});

// 支出分类
final expenseCategoriesProvider = FutureProvider<List<Category>>((ref) async {
  final ledgerId = ref.watch(currentLedgerIdProvider);
  final dao = CategoryDao();
  return await dao.getByType(ledgerId, 'expense');
});

// 收入分类
final incomeCategoriesProvider = FutureProvider<List<Category>>((ref) async {
  final ledgerId = ref.watch(currentLedgerIdProvider);
  final dao = CategoryDao();
  return await dao.getByType(ledgerId, 'income');
});

// 交易记录
final transactionsProvider = StateNotifierProvider<TransactionsNotifier, AsyncValue<List<Transaction>>>((ref) {
  return TransactionsNotifier(ref);
});

class TransactionsNotifier extends StateNotifier<AsyncValue<List<Transaction>>> {
  final Ref ref;
  
  TransactionsNotifier(this.ref) : super(const AsyncValue.loading()) {
    loadTransactions();
  }

  Future<void> loadTransactions() async {
    try {
      final ledgerId = ref.read(currentLedgerIdProvider);
      final dao = TransactionDao();
      final transactions = await dao.getByLedgerId(ledgerId, limit: 100);
      state = AsyncValue.data(transactions);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> refresh() async {
    await loadTransactions();
  }

  Future<void> addTransaction(Transaction transaction) async {
    try {
      final dao = TransactionDao();
      final accountDao = AccountDao();
      
      // 插入交易
      await dao.insert(transaction);
      
      // 更新账户余额
      if (transaction.type == 'expense' && transaction.accountId != null) {
        await accountDao.updateBalance(transaction.accountId!, -transaction.amount);
      } else if (transaction.type == 'income' && transaction.accountId != null) {
        await accountDao.updateBalance(transaction.accountId!, transaction.amount);
      } else if (transaction.type == 'transfer' && transaction.accountId != null && transaction.toAccountId != null) {
        await accountDao.updateBalance(transaction.accountId!, -transaction.amount);
        await accountDao.updateBalance(transaction.toAccountId!, transaction.amount);
      }
      
      await loadTransactions();
      ref.invalidate(accountsProvider);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateTransaction(Transaction transaction) async {
    try {
      final dao = TransactionDao();
      await dao.update(transaction);
      await loadTransactions();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteTransaction(int id) async {
    try {
      final dao = TransactionDao();
      await dao.delete(id);
      await loadTransactions();
    } catch (e) {
      rethrow;
    }
  }
}

// 月度统计
final monthlyStatsProvider = FutureProvider.family<Map<String, double>, DateTime>((ref, date) async {
  final ledgerId = ref.watch(currentLedgerIdProvider);
  final dao = TransactionDao();
  return await dao.getMonthlyStats(ledgerId, date.year, date.month);
});

// 分类统计
final categoryStatsProvider = FutureProvider.family<List<Map<String, dynamic>>, Map<String, dynamic>>((ref, params) async {
  final ledgerId = ref.watch(currentLedgerIdProvider);
  final dao = TransactionDao();
  return await dao.getCategoryStats(
    ledgerId,
    params['year'],
    params['month'],
    params['type'],
  );
});

// 主题模式
final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier();
});

enum ThemeMode { light, dark, system }

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(ThemeMode.system) {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final themeIndex = prefs.getInt('theme_mode') ?? 2;
    state = ThemeMode.values[themeIndex];
  }

  Future<void> setTheme(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('theme_mode', mode.index);
    state = mode;
  }
}

// 主色调
final primaryColorProvider = StateNotifierProvider<PrimaryColorNotifier, int>((ref) {
  return PrimaryColorNotifier();
});

class PrimaryColorNotifier extends StateNotifier<int> {
  static const int defaultColor = 0xFFFFB300; // Amber
  
  PrimaryColorNotifier() : super(defaultColor) {
    _loadColor();
  }

  Future<void> _loadColor() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getInt('primary_color') ?? defaultColor;
  }

  Future<void> setColor(int color) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('primary_color', color);
    state = color;
  }
}

// 选中月份
final selectedMonthProvider = StateProvider<DateTime>((ref) => DateTime.now());

// 预算列表
final budgetsProvider = FutureProvider<List<Budget>>((ref) async {
  final ledgerId = ref.watch(currentLedgerIdProvider);
  final dao = BudgetDao();
  return await dao.getByLedgerId(ledgerId);
});
