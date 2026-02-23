// 账本模型
class Ledger {
  final int? id;
  final String name;
  final String currency;
  final String icon;
  final DateTime createdAt;
  final DateTime updatedAt;

  Ledger({
    this.id,
    required this.name,
    this.currency = 'CNY',
    this.icon = 'account_balance_wallet',
    required this.createdAt,
    required this.updatedAt,
  });

  factory Ledger.fromMap(Map<String, dynamic> map) {
    return Ledger(
      id: map['id'],
      name: map['name'],
      currency: map['currency'],
      icon: map['icon'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at']),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'currency': currency,
      'icon': icon,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
    };
  }

  Ledger copyWith({
    int? id,
    String? name,
    String? currency,
    String? icon,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Ledger(
      id: id ?? this.id,
      name: name ?? this.name,
      currency: currency ?? this.currency,
      icon: icon ?? this.icon,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

// 账户模型
class Account {
  final int? id;
  final int ledgerId;
  final String name;
  final String type;
  final String currency;
  final double initialBalance;
  final double currentBalance;
  final String icon;
  final String color;
  final DateTime createdAt;
  final DateTime updatedAt;

  Account({
    this.id,
    required this.ledgerId,
    required this.name,
    this.type = 'cash',
    this.currency = 'CNY',
    this.initialBalance = 0.0,
    this.currentBalance = 0.0,
    this.icon = 'account_balance',
    this.color = '#FF6B6B',
    required this.createdAt,
    required this.updatedAt,
  });

  factory Account.fromMap(Map<String, dynamic> map) {
    return Account(
      id: map['id'],
      ledgerId: map['ledger_id'],
      name: map['name'],
      type: map['type'],
      currency: map['currency'],
      initialBalance: map['initial_balance'],
      currentBalance: map['current_balance'],
      icon: map['icon'],
      color: map['color'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at']),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'ledger_id': ledgerId,
      'name': name,
      'type': type,
      'currency': currency,
      'initial_balance': initialBalance,
      'current_balance': currentBalance,
      'icon': icon,
      'color': color,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
    };
  }

  Account copyWith({
    int? id,
    int? ledgerId,
    String? name,
    String? type,
    String? currency,
    double? initialBalance,
    double? currentBalance,
    String? icon,
    String? color,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Account(
      id: id ?? this.id,
      ledgerId: ledgerId ?? this.ledgerId,
      name: name ?? this.name,
      type: type ?? this.type,
      currency: currency ?? this.currency,
      initialBalance: initialBalance ?? this.initialBalance,
      currentBalance: currentBalance ?? this.currentBalance,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

// 分类模型
class Category {
  final int? id;
  final int ledgerId;
  final String name;
  final String type; // expense, income
  final String icon;
  final String color;
  final int? parentId;
  final int level;
  final int sortOrder;
  final DateTime createdAt;

  Category({
    this.id,
    required this.ledgerId,
    required this.name,
    required this.type,
    this.icon = 'category',
    this.color = '#4CAF50',
    this.parentId,
    this.level = 1,
    this.sortOrder = 0,
    required this.createdAt,
  });

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'],
      ledgerId: map['ledger_id'],
      name: map['name'],
      type: map['type'],
      icon: map['icon'],
      color: map['color'],
      parentId: map['parent_id'],
      level: map['level'],
      sortOrder: map['sort_order'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'ledger_id': ledgerId,
      'name': name,
      'type': type,
      'icon': icon,
      'color': color,
      'parent_id': parentId,
      'level': level,
      'sort_order': sortOrder,
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }

  Category copyWith({
    int? id,
    int? ledgerId,
    String? name,
    String? type,
    String? icon,
    String? color,
    int? parentId,
    int? level,
    int? sortOrder,
    DateTime? createdAt,
  }) {
    return Category(
      id: id ?? this.id,
      ledgerId: ledgerId ?? this.ledgerId,
      name: name ?? this.name,
      type: type ?? this.type,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      parentId: parentId ?? this.parentId,
      level: level ?? this.level,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

// 交易记录模型
class Transaction {
  final int? id;
  final int ledgerId;
  final String type; // expense, income, transfer
  final double amount;
  final int? categoryId;
  final int? accountId;
  final int? toAccountId;
  final DateTime happenedAt;
  final String? note;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // 关联数据（非数据库字段）
  final Category? category;
  final Account? account;
  final Account? toAccount;

  Transaction({
    this.id,
    required this.ledgerId,
    required this.type,
    required this.amount,
    this.categoryId,
    this.accountId,
    this.toAccountId,
    required this.happenedAt,
    this.note,
    required this.createdAt,
    required this.updatedAt,
    this.category,
    this.account,
    this.toAccount,
  });

  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      id: map['id'],
      ledgerId: map['ledger_id'],
      type: map['type'],
      amount: map['amount'],
      categoryId: map['category_id'],
      accountId: map['account_id'],
      toAccountId: map['to_account_id'],
      happenedAt: DateTime.fromMillisecondsSinceEpoch(map['happened_at']),
      note: map['note'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at']),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'ledger_id': ledgerId,
      'type': type,
      'amount': amount,
      'category_id': categoryId,
      'account_id': accountId,
      'to_account_id': toAccountId,
      'happened_at': happenedAt.millisecondsSinceEpoch,
      'note': note,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
    };
  }

  Transaction copyWith({
    int? id,
    int? ledgerId,
    String? type,
    double? amount,
    int? categoryId,
    int? accountId,
    int? toAccountId,
    DateTime? happenedAt,
    String? note,
    DateTime? createdAt,
    DateTime? updatedAt,
    Category? category,
    Account? account,
    Account? toAccount,
  }) {
    return Transaction(
      id: id ?? this.id,
      ledgerId: ledgerId ?? this.ledgerId,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      categoryId: categoryId ?? this.categoryId,
      accountId: accountId ?? this.accountId,
      toAccountId: toAccountId ?? this.toAccountId,
      happenedAt: happenedAt ?? this.happenedAt,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      category: category ?? this.category,
      account: account ?? this.account,
      toAccount: toAccount ?? this.toAccount,
    );
  }
}

// 预算模型
class Budget {
  final int? id;
  final int ledgerId;
  final String type; // total, category
  final int? categoryId;
  final double amount;
  final String period; // monthly, weekly, yearly
  final int startDay;
  final bool enabled;
  final DateTime createdAt;
  final DateTime updatedAt;

  Budget({
    this.id,
    required this.ledgerId,
    this.type = 'total',
    this.categoryId,
    required this.amount,
    this.period = 'monthly',
    this.startDay = 1,
    this.enabled = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Budget.fromMap(Map<String, dynamic> map) {
    return Budget(
      id: map['id'],
      ledgerId: map['ledger_id'],
      type: map['type'],
      categoryId: map['category_id'],
      amount: map['amount'],
      period: map['period'],
      startDay: map['start_day'],
      enabled: map['enabled'] == 1,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at']),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'ledger_id': ledgerId,
      'type': type,
      'category_id': categoryId,
      'amount': amount,
      'period': period,
      'start_day': startDay,
      'enabled': enabled ? 1 : 0,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
    };
  }

  Budget copyWith({
    int? id,
    int? ledgerId,
    String? type,
    int? categoryId,
    double? amount,
    String? period,
    int? startDay,
    bool? enabled,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Budget(
      id: id ?? this.id,
      ledgerId: ledgerId ?? this.ledgerId,
      type: type ?? this.type,
      categoryId: categoryId ?? this.categoryId,
      amount: amount ?? this.amount,
      period: period ?? this.period,
      startDay: startDay ?? this.startDay,
      enabled: enabled ?? this.enabled,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
