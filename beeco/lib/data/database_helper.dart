import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('beeco.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final Directory documentsDirectory = await getApplicationDocumentsDirectory();
    final String path = join(documentsDirectory.path, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    // 账本表
    await db.execute('''
      CREATE TABLE ledgers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        currency TEXT NOT NULL DEFAULT 'CNY',
        icon TEXT DEFAULT 'account_balance_wallet',
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');

    // 账户表
    await db.execute('''
      CREATE TABLE accounts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        ledger_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        type TEXT NOT NULL DEFAULT 'cash',
        currency TEXT NOT NULL DEFAULT 'CNY',
        initial_balance REAL NOT NULL DEFAULT 0.0,
        current_balance REAL NOT NULL DEFAULT 0.0,
        icon TEXT DEFAULT 'account_balance',
        color TEXT DEFAULT '#FF6B6B',
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        FOREIGN KEY (ledger_id) REFERENCES ledgers (id) ON DELETE CASCADE
      )
    ''');

    // 分类表
    await db.execute('''
      CREATE TABLE categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        ledger_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        icon TEXT DEFAULT 'category',
        color TEXT DEFAULT '#4CAF50',
        parent_id INTEGER,
        level INTEGER NOT NULL DEFAULT 1,
        sort_order INTEGER NOT NULL DEFAULT 0,
        created_at INTEGER NOT NULL,
        FOREIGN KEY (ledger_id) REFERENCES ledgers (id) ON DELETE CASCADE,
        FOREIGN KEY (parent_id) REFERENCES categories (id) ON DELETE SET NULL
      )
    ''');

    // 交易记录表
    await db.execute('''
      CREATE TABLE transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        ledger_id INTEGER NOT NULL,
        type TEXT NOT NULL,
        amount REAL NOT NULL,
        category_id INTEGER,
        account_id INTEGER,
        to_account_id INTEGER,
        happened_at INTEGER NOT NULL,
        note TEXT,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        FOREIGN KEY (ledger_id) REFERENCES ledgers (id) ON DELETE CASCADE,
        FOREIGN KEY (category_id) REFERENCES categories (id) ON DELETE SET NULL,
        FOREIGN KEY (account_id) REFERENCES accounts (id) ON DELETE SET NULL,
        FOREIGN KEY (to_account_id) REFERENCES accounts (id) ON DELETE SET NULL
      )
    ''');

    // 预算表
    await db.execute('''
      CREATE TABLE budgets (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        ledger_id INTEGER NOT NULL,
        type TEXT NOT NULL DEFAULT 'total',
        category_id INTEGER,
        amount REAL NOT NULL,
        period TEXT NOT NULL DEFAULT 'monthly',
        start_day INTEGER NOT NULL DEFAULT 1,
        enabled INTEGER NOT NULL DEFAULT 1,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        FOREIGN KEY (ledger_id) REFERENCES ledgers (id) ON DELETE CASCADE,
        FOREIGN KEY (category_id) REFERENCES categories (id) ON DELETE SET NULL
      )
    ''');

    // 创建索引
    await db.execute('CREATE INDEX idx_transactions_ledger ON transactions(ledger_id)');
    await db.execute('CREATE INDEX idx_transactions_type ON transactions(type)');
    await db.execute('CREATE INDEX idx_transactions_date ON transactions(happened_at)');
    await db.execute('CREATE INDEX idx_accounts_ledger ON accounts(ledger_id)');
    await db.execute('CREATE INDEX idx_categories_ledger ON categories(ledger_id)');

    // 插入默认账本
    final now = DateTime.now().millisecondsSinceEpoch;
    await db.insert('ledgers', {
      'name': '默认账本',
      'currency': 'CNY',
      'icon': 'account_balance_wallet',
      'created_at': now,
      'updated_at': now,
    });

    // 插入默认账户
    await db.insert('accounts', {
      'ledger_id': 1,
      'name': '现金',
      'type': 'cash',
      'currency': 'CNY',
      'initial_balance': 0.0,
      'current_balance': 0.0,
      'icon': 'payments',
      'color': '#4CAF50',
      'created_at': now,
      'updated_at': now,
    });

    // 插入默认支出分类
    final expenseCategories = [
      {'name': '餐饮', 'icon': 'restaurant', 'color': '#FF6B6B'},
      {'name': '交通', 'icon': 'directions_car', 'color': '#4ECDC4'},
      {'name': '购物', 'icon': 'shopping_cart', 'color': '#45B7D1'},
      {'name': '娱乐', 'icon': 'movie', 'color': '#96CEB4'},
      {'name': '医疗', 'icon': 'local_hospital', 'color': '#FFEAA7'},
      {'name': '教育', 'icon': 'school', 'color': '#DDA0DD'},
      {'name': '居住', 'icon': 'home', 'color': '#98D8C8'},
      {'name': '其他', 'icon': 'more_horiz', 'color': '#F7DC6F'},
    ];

    for (int i = 0; i < expenseCategories.length; i++) {
      await db.insert('categories', {
        'ledger_id': 1,
        'name': expenseCategories[i]['name'],
        'type': 'expense',
        'icon': expenseCategories[i]['icon'],
        'color': expenseCategories[i]['color'],
        'level': 1,
        'sort_order': i,
        'created_at': now,
      });
    }

    // 插入默认收入分类
    final incomeCategories = [
      {'name': '工资', 'icon': 'work', 'color': '#4CAF50'},
      {'name': '奖金', 'icon': 'card_giftcard', 'color': '#FF9800'},
      {'name': '投资', 'icon': 'trending_up', 'color': '#2196F3'},
      {'name': '兼职', 'icon': 'timer', 'color': '#9C27B0'},
      {'name': '其他', 'icon': 'more_horiz', 'color': '#607D8B'},
    ];

    for (int i = 0; i < incomeCategories.length; i++) {
      await db.insert('categories', {
        'ledger_id': 1,
        'name': incomeCategories[i]['name'],
        'type': 'income',
        'icon': incomeCategories[i]['icon'],
        'color': incomeCategories[i]['color'],
        'level': 1,
        'sort_order': i,
        'created_at': now,
      });
    }
  }

  // 关闭数据库
  Future<void> close() async {
    final db = await instance.database;
    db.close();
    _database = null;
  }
}
