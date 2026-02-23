import 'package:sqflite/sqflite.dart';
import '../data/database_helper.dart';
import '../models/models.dart';

class LedgerDao {
  final DatabaseHelper _db = DatabaseHelper.instance;

  Future<List<Ledger>> getAll() async {
    final db = await _db.database;
    final List<Map<String, dynamic>> maps = await db.query('ledgers', orderBy: 'created_at DESC');
    return List.generate(maps.length, (i) => Ledger.fromMap(maps[i]));
  }

  Future<Ledger?> getById(int id) async {
    final db = await _db.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'ledgers',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return Ledger.fromMap(maps.first);
  }

  Future<int> insert(Ledger ledger) async {
    final db = await _db.database;
    return await db.insert('ledgers', ledger.toMap());
  }

  Future<int> update(Ledger ledger) async {
    final db = await _db.database;
    return await db.update(
      'ledgers',
      ledger.toMap(),
      where: 'id = ?',
      whereArgs: [ledger.id],
    );
  }

  Future<int> delete(int id) async {
    final db = await _db.database;
    return await db.delete(
      'ledgers',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}

class AccountDao {
  final DatabaseHelper _db = DatabaseHelper.instance;

  Future<List<Account>> getByLedgerId(int ledgerId) async {
    final db = await _db.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'accounts',
      where: 'ledger_id = ?',
      whereArgs: [ledgerId],
      orderBy: 'created_at ASC',
    );
    return List.generate(maps.length, (i) => Account.fromMap(maps[i]));
  }

  Future<Account?> getById(int id) async {
    final db = await _db.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'accounts',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return Account.fromMap(maps.first);
  }

  Future<int> insert(Account account) async {
    final db = await _db.database;
    return await db.insert('accounts', account.toMap());
  }

  Future<int> update(Account account) async {
    final db = await _db.database;
    return await db.update(
      'accounts',
      account.toMap(),
      where: 'id = ?',
      whereArgs: [account.id],
    );
  }

  Future<int> delete(int id) async {
    final db = await _db.database;
    return await db.delete(
      'accounts',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> updateBalance(int accountId, double amount) async {
    final db = await _db.database;
    await db.rawUpdate(
      'UPDATE accounts SET current_balance = current_balance + ? WHERE id = ?',
      [amount, accountId],
    );
  }
}

class CategoryDao {
  final DatabaseHelper _db = DatabaseHelper.instance;

  Future<List<Category>> getByLedgerId(int ledgerId) async {
    final db = await _db.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'categories',
      where: 'ledger_id = ?',
      whereArgs: [ledgerId],
      orderBy: 'sort_order ASC',
    );
    return List.generate(maps.length, (i) => Category.fromMap(maps[i]));
  }

  Future<List<Category>> getByType(int ledgerId, String type) async {
    final db = await _db.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'categories',
      where: 'ledger_id = ? AND type = ?',
      whereArgs: [ledgerId, type],
      orderBy: 'sort_order ASC',
    );
    return List.generate(maps.length, (i) => Category.fromMap(maps[i]));
  }

  Future<Category?> getById(int id) async {
    final db = await _db.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'categories',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return Category.fromMap(maps.first);
  }

  Future<int> insert(Category category) async {
    final db = await _db.database;
    return await db.insert('categories', category.toMap());
  }

  Future<int> update(Category category) async {
    final db = await _db.database;
    return await db.update(
      'categories',
      category.toMap(),
      where: 'id = ?',
      whereArgs: [category.id],
    );
  }

  Future<int> delete(int id) async {
    final db = await _db.database;
    return await db.delete(
      'categories',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}

class TransactionDao {
  final DatabaseHelper _db = DatabaseHelper.instance;

  Future<List<Transaction>> getByLedgerId(
    int ledgerId, {
    DateTime? startDate,
    DateTime? endDate,
    String? type,
    int limit = 100,
    int offset = 0,
  }) async {
    final db = await _db.database;
    
    String whereClause = 'ledger_id = ?';
    List<dynamic> whereArgs = [ledgerId];

    if (startDate != null) {
      whereClause += ' AND happened_at >= ?';
      whereArgs.add(startDate.millisecondsSinceEpoch);
    }

    if (endDate != null) {
      whereClause += ' AND happened_at <= ?';
      whereArgs.add(endDate.millisecondsSinceEpoch);
    }

    if (type != null) {
      whereClause += ' AND type = ?';
      whereArgs.add(type);
    }

    final List<Map<String, dynamic>> maps = await db.query(
      'transactions',
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'happened_at DESC, id DESC',
      limit: limit,
      offset: offset,
    );

    return List.generate(maps.length, (i) => Transaction.fromMap(maps[i]));
  }

  Future<Transaction?> getById(int id) async {
    final db = await _db.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'transactions',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return Transaction.fromMap(maps.first);
  }

  Future<int> insert(Transaction transaction) async {
    final db = await _db.database;
    return await db.insert('transactions', transaction.toMap());
  }

  Future<int> update(Transaction transaction) async {
    final db = await _db.database;
    return await db.update(
      'transactions',
      transaction.toMap(),
      where: 'id = ?',
      whereArgs: [transaction.id],
    );
  }

  Future<int> delete(int id) async {
    final db = await _db.database;
    return await db.delete(
      'transactions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<Map<String, double>> getMonthlyStats(int ledgerId, int year, int month) async {
    final db = await _db.database;
    
    final startDate = DateTime(year, month, 1);
    final endDate = DateTime(year, month + 1, 0, 23, 59, 59);

    final List<Map<String, dynamic>> result = await db.rawQuery('''
      SELECT 
        COALESCE(SUM(CASE WHEN type = 'income' THEN amount ELSE 0 END), 0) as income,
        COALESCE(SUM(CASE WHEN type = 'expense' THEN amount ELSE 0 END), 0) as expense
      FROM transactions
      WHERE ledger_id = ? AND happened_at >= ? AND happened_at <= ?
    ''', [ledgerId, startDate.millisecondsSinceEpoch, endDate.millisecondsSinceEpoch]);

    return {
      'income': (result.first['income'] as num).toDouble(),
      'expense': (result.first['expense'] as num).toDouble(),
    };
  }

  Future<List<Map<String, dynamic>>> getCategoryStats(
    int ledgerId,
    int year,
    int month,
    String type,
  ) async {
    final db = await _db.database;
    
    final startDate = DateTime(year, month, 1);
    final endDate = DateTime(year, month + 1, 0, 23, 59, 59);

    final List<Map<String, dynamic>> result = await db.rawQuery('''
      SELECT 
        c.id,
        c.name,
        c.icon,
        c.color,
        COALESCE(SUM(t.amount), 0) as total
      FROM categories c
      LEFT JOIN transactions t ON c.id = t.category_id 
        AND t.happened_at >= ? AND t.happened_at <= ? AND t.type = ?
      WHERE c.ledger_id = ? AND c.type = ?
      GROUP BY c.id
      HAVING total > 0
      ORDER BY total DESC
    ''', [
      startDate.millisecondsSinceEpoch,
      endDate.millisecondsSinceEpoch,
      type,
      ledgerId,
      type,
    ]);

    return result;
  }
}

class BudgetDao {
  final DatabaseHelper _db = DatabaseHelper.instance;

  Future<List<Budget>> getByLedgerId(int ledgerId) async {
    final db = await _db.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'budgets',
      where: 'ledger_id = ?',
      whereArgs: [ledgerId],
    );
    return List.generate(maps.length, (i) => Budget.fromMap(maps[i]));
  }

  Future<int> insert(Budget budget) async {
    final db = await _db.database;
    return await db.insert('budgets', budget.toMap());
  }

  Future<int> update(Budget budget) async {
    final db = await _db.database;
    return await db.update(
      'budgets',
      budget.toMap(),
      where: 'id = ?',
      whereArgs: [budget.id],
    );
  }

  Future<int> delete(int id) async {
    final db = await _db.database;
    return await db.delete(
      'budgets',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
