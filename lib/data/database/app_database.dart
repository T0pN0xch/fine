import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

// ─── Tables ───────────────────────────────────────────────────────────────────

class Accounts extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get icon => text().withDefault(const Constant('💵'))();
  // cash, bank, ewallet, payable, receivable, investment, card
  TextColumn get type => text().withDefault(const Constant('cash'))();
  IntColumn get colorIndex => integer().withDefault(const Constant(0))();
  RealColumn get balance => real().withDefault(const Constant(0.0))();
  TextColumn get currency => text().withDefault(const Constant('MYR'))();
  BoolColumn get isDefault => boolean().withDefault(const Constant(false))();
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  TextColumn get notes => text().nullable()();
}

class Categories extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get icon => text().withDefault(const Constant('📦'))();
  IntColumn get colorIndex => integer().withDefault(const Constant(0))();
  TextColumn get type =>
      text().withDefault(const Constant('expense'))(); // expense, income
  BoolColumn get isDefault => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class Members extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get icon => text().withDefault(const Constant('👤'))();
  BoolColumn get isDefault => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class Transactions extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get type => text()(); // expense, income, transfer
  RealColumn get amount => real()();
  TextColumn get note => text().nullable()();
  IntColumn get categoryId =>
      integer().nullable().references(Categories, #id)();
  @ReferenceName('transactions_from_account')
  IntColumn get accountId => integer().references(Accounts, #id)();
  @ReferenceName('transactions_to_account')
  IntColumn get toAccountId =>
      integer().nullable().references(Accounts, #id)(); // for transfers
  IntColumn get memberId => integer().nullable().references(Members, #id)();
  DateTimeColumn get date => dateTime()();
  TextColumn get currency => text().withDefault(const Constant('MYR'))();
  BoolColumn get isRecurring => boolean().withDefault(const Constant(false))();
  TextColumn get imagePath => text().nullable()(); // receipt image
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class BudgetLimits extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get categoryId => integer().references(Categories, #id)();
  RealColumn get limitAmount => real()();
  TextColumn get period => text()
      .withDefault(const Constant('monthly'))(); // weekly, monthly, yearly
  IntColumn get month => integer().nullable()(); // 1-12
  IntColumn get year => integer().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class Bills extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get icon => text().withDefault(const Constant('📄'))();
  RealColumn get amount => real()();
  TextColumn get repeatInterval => text()(); // Daily, Weekly, Monthly, Yearly
  IntColumn get dayOfMonth => integer().nullable()(); // 1-31 for monthly
  DateTimeColumn get nextDueDate => dateTime()();
  IntColumn get categoryId =>
      integer().nullable().references(Categories, #id)();
  IntColumn get accountId => integer().nullable().references(Accounts, #id)();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  BoolColumn get reminderEnabled =>
      boolean().withDefault(const Constant(true))();
  IntColumn get reminderDaysBefore =>
      integer().withDefault(const Constant(1))();
  TextColumn get currency => text().withDefault(const Constant('MYR'))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class Ledgers extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get icon => text().withDefault(const Constant('📒'))();
  IntColumn get colorIndex => integer().withDefault(const Constant(0))();
  BoolColumn get isDefault => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class Tags extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 50)();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class TransactionTags extends Table {
  IntColumn get transactionId =>
      integer().references(Transactions, #id)();
  IntColumn get tagId => integer().references(Tags, #id)();

  @override
  Set<Column> get primaryKey => {transactionId, tagId};
}

class Goals extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get icon => text().withDefault(const Constant('🎯'))();
  IntColumn get colorIndex => integer().withDefault(const Constant(0))();
  RealColumn get targetAmount => real()();
  RealColumn get savedAmount => real().withDefault(const Constant(0.0))();
  DateTimeColumn get targetDate => dateTime().nullable()();
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  TextColumn get notes => text().nullable()();
}

class GoalTopUps extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get goalId => integer().references(Goals, #id)();
  RealColumn get amount => real()();
  TextColumn get note => text().nullable()();
  DateTimeColumn get date => dateTime().withDefault(currentDateAndTime)();
}

class MonthlyPlans extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get year => integer()();
  IntColumn get month => integer()(); // 1-12
  RealColumn get expectedSalary => real().withDefault(const Constant(0.0))();
  IntColumn get salaryDay =>
      integer().withDefault(const Constant(1))(); // day of month, 1-31
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  List<Set<Column>> get uniqueKeys => [
        {year, month},
      ];
}

class Commitments extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get year => integer()();
  IntColumn get month => integer()(); // 1-12, which month this belongs to
  TextColumn get name => text().withLength(min: 1, max: 100)();
  RealColumn get amount => real()();
  IntColumn get dueDay => integer().nullable()(); // optional reminder, 1-31
  BoolColumn get isPaid => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

// ─── Database ─────────────────────────────────────────────────────────────────

@DriftDatabase(
  tables: [
    Accounts,
    Categories,
    Members,
    Transactions,
    BudgetLimits,
    Bills,
    Ledgers,
    Tags,
    TransactionTags,
    Goals,
    GoalTopUps,
    MonthlyPlans,
    Commitments,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  /// Opens the database with a caller-supplied executor — used for tests
  /// and one-off data-migration tooling.
  AppDatabase.withExecutor(QueryExecutor executor) : super(executor);

  @override
  int get schemaVersion => 7;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          await _seedDefaultData();
        },
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.createTable(tags);
            await m.createTable(transactionTags);
          }
          if (from < 3) {
            await m.addColumn(accounts, accounts.isArchived);
          }
          if (from < 4) {
            await m.createTable(goals);
            await m.createTable(goalTopUps);
          }
          if (from < 5) {
            await m.createTable(monthlyPlans);
            await m.createTable(commitments);
          }
          if (from < 6) {
            await m.addColumn(goals, goals.notes);
          }
          if (from < 7) {
            await m.addColumn(accounts, accounts.notes);
          }
        },
      );

  // ── Seed default data on first launch ──────────────────────────────────────

  Future<void> _seedDefaultData() async {
    // Default ledger
    await into(ledgers).insert(LedgersCompanion.insert(
      name: 'Personal',
      icon: const Value('📒'),
      isDefault: const Value(true),
    ));

    // Default members — used to categorize spending by person
    final defaultMembers = [
      ('Self', '😊', true),
      ('Partner', '💑', false),
      ('Parent', '👨‍👩‍👧', false),
      ('House', '🏠', false),
      ('Friends', '🧑‍🤝‍🧑', false),
      ('Relatives', '👪', false),
    ];
    final memberIds = <String, int>{};
    for (final m in defaultMembers) {
      final id = await into(members).insert(MembersCompanion.insert(
        name: m.$1,
        icon: Value(m.$2),
        isDefault: Value(m.$3),
      ));
      memberIds[m.$1] = id;
    }

    // Default accounts with initial balance
    final defaultAccounts = [
      ('Cash', '💵', 'cash', 1, 'MYR', 500.0),
      ('Bank Account', '🏦', 'bank', 0, 'MYR', 5000.0),
      ('E-Wallet', '📱', 'ewallet', 4, 'MYR', 1500.0),
      ('Owed by Friend', '📥', 'receivable', 5, 'MYR', 300.0),
      ('Owed to Supplier', '📤', 'payable', 2, 'MYR', 200.0),
      ('Stock Portfolio', '📈', 'investment', 6, 'MYR', 2500.0),
      ('Credit Card', '💳', 'card', 8, 'MYR', 1200.0),
    ];

    final accountIds = <String, int>{};
    for (final a in defaultAccounts) {
      final id = await into(accounts).insert(AccountsCompanion.insert(
        name: a.$1,
        icon: Value(a.$2),
        type: Value(a.$3),
        colorIndex: Value(a.$4),
        currency: Value(a.$5),
        balance: Value(a.$6),
        isDefault: Value(a.$1 == 'Cash'),
      ));
      accountIds[a.$1] = id;
    }

    // Example savings goals so the Goals tab has content out of the box
    final goalSeedNow = DateTime.now();
    final defaultGoals = [
      ('New Laptop', '💻', 8, 5000.0, 1800.0, DateTime(goalSeedNow.year, goalSeedNow.month + 3, 1)),
      ('Vacation to Bali', '🏖️', 4, 8000.0, 3200.0, DateTime(goalSeedNow.year, goalSeedNow.month + 6, 1)),
      ('Emergency Fund', '🛡️', 1, 10000.0, 6500.0, null),
      ('New Phone', '📱', 7, 3000.0, 900.0, DateTime(goalSeedNow.year, goalSeedNow.month + 2, 1)),
    ];
    for (final g in defaultGoals) {
      await into(goals).insert(GoalsCompanion.insert(
        name: g.$1,
        icon: Value(g.$2),
        colorIndex: Value(g.$3),
        targetAmount: g.$4,
        savedAmount: Value(g.$5),
        targetDate: Value(g.$6),
      ));
    }

    // Default expense categories (extensive set to minimize setup friction)
    final expenseCategories = [
      ('Food & Drinks', '🍔', 0),
      ('Groceries', '🛒', 6),
      ('Transport', '🚗', 1),
      ('Fuel', '⛽', 7),
      ('Parking & Toll', '🅿️', 9),
      ('Shopping', '🛍️', 3),
      ('Clothing', '👕', 5),
      ('Bills & Utilities', '⚡', 4),
      ('Phone & Internet', '📶', 4),
      ('Rent & Mortgage', '🏠', 8),
      ('Home Maintenance', '🔧', 8),
      ('Health', '💊', 2),
      ('Fitness', '🏋️', 6),
      ('Insurance', '🛡️', 9),
      ('Entertainment', '🎬', 5),
      ('Subscriptions', '📺', 5),
      ('Hobbies', '🎨', 5),
      ('Education', '📚', 6),
      ('Travel', '✈️', 7),
      ('Pets', '🐾', 6),
      ('Family & Kids', '👶', 2),
      ('Personal Care', '💇', 2),
      ('Gifts & Donations', '🎁', 5),
      ('Taxes', '🧾', 9),
      ('Loan & Debt', '💳', 9),
      ('Coffee & Snacks', '☕', 0),
      ('Alcohol & Bars', '🍺', 0),
      ('Electronics', '📱', 3),
      ('Office Supplies', '🖊️', 8),
      ('Others', '📦', 8),
    ];

    final catIds = <String, int>{};
    for (final c in expenseCategories) {
      final id = await into(categories).insert(CategoriesCompanion.insert(
        name: c.$1,
        icon: Value(c.$2),
        colorIndex: Value(c.$3),
        type: Value('expense'),
      ));
      catIds[c.$1] = id;
    }

    // Default income categories
    final incomeCategories = [
      ('Salary', '💼', 1),
      ('Freelance', '💻', 0),
      ('Business', '🏪', 3),
      ('Investment', '📈', 4),
      ('Dividends', '📊', 4),
      ('Rental Income', '🏘️', 8),
      ('Bonus', '🎉', 5),
      ('Gifts', '🎁', 5),
      ('Refunds', '↩️', 9),
      ('Other Income', '💰', 1),
    ];

    for (final c in incomeCategories) {
      final id = await into(categories).insert(CategoriesCompanion.insert(
        name: c.$1,
        icon: Value(c.$2),
        colorIndex: Value(c.$3),
        type: Value('income'),
      ));
      catIds[c.$1] = id;
    }

    // ── Example transactions ─────────────────────────────────────────────
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final exampleTransactions = [
      // account, type, categoryId, amount, note, date, member
      ('Cash', 'expense', catIds['Food & Drinks']!, 45.50, 'Lunch at KFC', today.add(const Duration(hours: 12, minutes: 30)), 'Self'),
      ('Cash', 'expense', catIds['Transport']!, 12.00, 'Grab to office', today.add(const Duration(hours: 8, minutes: 15)), 'Self'),
      ('Cash', 'expense', catIds['Shopping']!, 189.99, 'Jeans from Uniqlo', today.subtract(const Duration(days: 1, hours: 2)), 'Partner'),
      ('Cash', 'expense', catIds['Groceries']!, 67.30, 'Tesco groceries', today.subtract(const Duration(days: 1, hours: 14)), 'House'),
      ('Cash', 'income', catIds['Salary']!, 4500.00, 'Monthly salary', today.subtract(const Duration(days: 2, hours: 1)), 'Self'),
      ('Cash', 'expense', catIds['Bills & Utilities']!, 150.00, 'Internet bill', today.subtract(const Duration(days: 2, hours: 8)), 'House'),
      ('Cash', 'expense', catIds['Entertainment']!, 55.00, 'Movie & snacks', today.subtract(const Duration(days: 5, hours: 10)), 'Partner'),
      ('Cash', 'expense', catIds['Health']!, 38.50, 'Doctor visit', today.subtract(const Duration(days: 5, hours: 15)), 'Parent'),
      ('Cash', 'expense', catIds['Travel']!, 280.00, 'Petrol', today.subtract(const Duration(days: 7, hours: 11)), 'Self'),
      ('Cash', 'income', catIds['Freelance']!, 850.00, 'Web design payment', today.subtract(const Duration(days: 7, hours: 3)), 'Self'),

      // Bank Account — give it a track record too
      ('Bank Account', 'income', catIds['Salary']!, 4500.00, 'Monthly salary', today.subtract(const Duration(days: 30, hours: 1)), 'Self'),
      ('Bank Account', 'expense', catIds['Rent & Mortgage']!, 1200.00, 'Monthly rent', today.subtract(const Duration(days: 28, hours: 9)), 'House'),
      ('Bank Account', 'expense', catIds['Bills & Utilities']!, 95.00, 'Electricity bill', today.subtract(const Duration(days: 20, hours: 7)), 'House'),
      ('Bank Account', 'income', catIds['Salary']!, 4500.00, 'Monthly salary', today.subtract(const Duration(days: 1)), 'Self'),

      // E-Wallet
      ('E-Wallet', 'expense', catIds['Coffee & Snacks']!, 8.50, 'Coffee', today.subtract(const Duration(days: 3, hours: 9)), 'Friends'),
      ('E-Wallet', 'expense', catIds['Transport']!, 6.00, 'E-hailing', today.subtract(const Duration(days: 6, hours: 17)), 'Self'),
      ('E-Wallet', 'income', catIds['Other Income']!, 50.00, 'Cashback reward', today.subtract(const Duration(days: 10, hours: 4)), 'Self'),

      // Owed by Friend (receivable) — track who owes growing/shrinking
      ('Owed by Friend', 'income', catIds['Other Income']!, 100.00, 'Friend repaid part of loan', today.subtract(const Duration(days: 15)), 'Friends'),
      ('Owed by Friend', 'expense', catIds['Other Income']!, 50.00, 'Lent more to friend', today.subtract(const Duration(days: 9)), 'Friends'),

      // Owed to Supplier (payable)
      ('Owed to Supplier', 'expense', catIds['Office Supplies']!, 80.00, 'New invoice from supplier', today.subtract(const Duration(days: 18)), 'Self'),
      ('Owed to Supplier', 'income', catIds['Other Income']!, 30.00, 'Partial payment to supplier', today.subtract(const Duration(days: 4)), 'Self'),

      // Stock Portfolio (investment)
      ('Stock Portfolio', 'income', catIds['Investment']!, 320.00, 'Stock value gain', today.subtract(const Duration(days: 25)), 'Self'),
      ('Stock Portfolio', 'expense', catIds['Investment']!, 100.00, 'Bought more shares', today.subtract(const Duration(days: 14)), 'Self'),
      ('Stock Portfolio', 'income', catIds['Dividends']!, 45.00, 'Dividend payout', today.subtract(const Duration(days: 6)), 'Self'),

      // Credit Card
      ('Credit Card', 'expense', catIds['Shopping']!, 220.00, 'Online shopping', today.subtract(const Duration(days: 12)), 'Partner'),
      ('Credit Card', 'expense', catIds['Entertainment']!, 60.00, 'Concert tickets', today.subtract(const Duration(days: 5)), 'Relatives'),
    ];

    for (final txn in exampleTransactions) {
      final accountName = txn.$1;
      final type = txn.$2;
      final catId = txn.$3;
      final amount = txn.$4;
      final note = txn.$5;
      final date = txn.$6;
      final memberName = txn.$7;
      final accId = accountIds[accountName]!;

      await into(transactions).insert(TransactionsCompanion.insert(
        type: type,
        amount: amount,
        note: Value(note),
        categoryId: Value(catId),
        accountId: accId,
        memberId: Value(memberIds[memberName]),
        date: date,
        currency: const Value('MYR'),
      ));

      // Update account balance
      final acc =
          await (select(accounts)..where((a) => a.id.equals(accId)))
              .getSingle();
      if (type == 'expense') {
        await (update(accounts)..where((a) => a.id.equals(accId)))
            .write(AccountsCompanion(balance: Value(acc.balance - amount)));
      } else if (type == 'income') {
        await (update(accounts)..where((a) => a.id.equals(accId)))
            .write(AccountsCompanion(balance: Value(acc.balance + amount)));
      }
    }

    // ── Example recurring bills ──────────────────────────────────────────
    final defaultBills = [
      ('Netflix', '🎬', 45.00, 'Monthly', 15, catIds['Subscriptions']),
      ('Spotify', '🎵', 19.90, 'Monthly', 3, catIds['Subscriptions']),
      ('Internet Bill', '📶', 150.00, 'Monthly', 10, catIds['Phone & Internet']),
      ('Electricity Bill', '⚡', 120.00, 'Monthly', 18, catIds['Bills & Utilities']),
      ('Gym Membership', '🏋️', 89.00, 'Monthly', 1, catIds['Fitness']),
      ('Car Insurance', '🛡️', 600.00, 'Yearly', null, catIds['Insurance']),
    ];
    for (final b in defaultBills) {
      final dayOfMonth = b.$5;
      final today2 = DateTime.now();
      final nextDue = dayOfMonth != null
          ? (DateTime(today2.year, today2.month, dayOfMonth)
                  .isBefore(today2)
              ? DateTime(today2.year, today2.month + 1, dayOfMonth)
              : DateTime(today2.year, today2.month, dayOfMonth))
          : DateTime(today2.year + 1, today2.month, today2.day);
      await into(bills).insert(BillsCompanion.insert(
        name: b.$1,
        icon: Value(b.$2),
        amount: b.$3,
        repeatInterval: b.$4,
        dayOfMonth: Value(dayOfMonth),
        nextDueDate: nextDue,
        categoryId: Value(b.$6),
        accountId: Value(accountIds['Bank Account']),
      ));
    }

    // ── Example monthly budgets ──────────────────────────────────────────
    final budgetSeedNow = DateTime.now();
    final defaultBudgets = [
      ('Food & Drinks', 600.00),
      ('Groceries', 500.00),
      ('Transport', 250.00),
      ('Shopping', 400.00),
      ('Bills & Utilities', 350.00),
      ('Entertainment', 200.00),
    ];
    for (final b in defaultBudgets) {
      final catId = catIds[b.$1];
      if (catId == null) continue;
      await into(budgetLimits).insert(BudgetLimitsCompanion.insert(
        categoryId: catId,
        limitAmount: b.$2,
        period: const Value('monthly'),
        month: Value(budgetSeedNow.month),
        year: Value(budgetSeedNow.year),
      ));
    }
  }

  // ── Account queries ─────────────────────────────────────────────────────────

  Stream<List<Account>> watchAllAccounts() =>
      (select(accounts)..orderBy([(a) => OrderingTerm.asc(a.createdAt)]))
          .watch();

  Future<List<Account>> getAllAccounts() =>
      (select(accounts)..orderBy([(a) => OrderingTerm.asc(a.createdAt)])).get();

  Future<Account?> getDefaultAccount() =>
      (select(accounts)..where((a) => a.isDefault.equals(true)))
          .getSingleOrNull();

  Future<int> insertAccount(AccountsCompanion entry) =>
      into(accounts).insert(entry);

  Future<bool> updateAccount(AccountsCompanion entry) =>
      update(accounts).replace(entry);

  Future<int> deleteAccount(int id) =>
      (delete(accounts)..where((a) => a.id.equals(id))).go();

  Future<void> archiveAccount(int id, {bool archived = true}) async {
    await (update(accounts)..where((a) => a.id.equals(id)))
        .write(AccountsCompanion(isArchived: Value(archived)));
  }

  static const List<String> spendableTypes = ['cash', 'bank', 'ewallet'];
  static const List<String> assetTypes = [
    'cash',
    'bank',
    'ewallet',
    'receivable',
    'investment',
  ];
  static const List<String> liabilityTypes = ['payable', 'card'];

  /// Total pocket money — spendable accounts only (cash/bank/ewallet).
  Future<double> getTotalBalance() async {
    final allAccounts = await getAllAccounts();
    return allAccounts
        .where((a) => spendableTypes.contains(a.type) && !a.isArchived)
        .fold<double>(0.0, (sum, a) => sum + a.balance);
  }

  Stream<List<Account>> watchAccountsByType(String type,
      {bool includeArchived = false}) {
    final q = select(accounts)
      ..where((a) => a.type.equals(type))
      ..orderBy([(a) => OrderingTerm.asc(a.createdAt)]);
    if (!includeArchived) {
      q.where((a) => a.isArchived.equals(false));
    }
    return q.watch();
  }

  Future<double> getNetWorth() async {
    final allAccounts = await getAllAccounts();
    final active = allAccounts.where((a) => !a.isArchived);
    final assets = active
        .where((a) => assetTypes.contains(a.type))
        .fold<double>(0.0, (sum, a) => sum + a.balance);
    final liabilities = active
        .where((a) => liabilityTypes.contains(a.type))
        .fold<double>(0.0, (sum, a) => sum + a.balance);
    return assets - liabilities;
  }

  Future<Map<String, double>> getNetWorthBreakdown() async {
    final allAccounts = await getAllAccounts();
    final active = allAccounts.where((a) => !a.isArchived);
    final result = <String, double>{};
    for (final type in [...assetTypes, ...liabilityTypes]) {
      result[type] = active
          .where((a) => a.type == type)
          .fold<double>(0.0, (sum, a) => sum + a.balance);
    }
    return result;
  }

  /// Reconstructs net worth at the end of each day from [from] to today by
  /// walking current balances backwards through transaction history.
  Future<List<MapEntry<DateTime, double>>> getNetWorthHistory(
      DateTime from) async {
    final allAccounts = await getAllAccounts();
    final balances = <int, double>{};
    final signs = <int, double>{};
    for (final a in allAccounts) {
      balances[a.id] = a.balance;
      if (assetTypes.contains(a.type)) {
        signs[a.id] = 1;
      } else if (liabilityTypes.contains(a.type)) {
        signs[a.id] = -1;
      } else {
        signs[a.id] = 0;
      }
    }

    final txns = await (select(transactions)
          ..where((t) => t.date.isBiggerOrEqualValue(from))
          ..orderBy([(t) => OrderingTerm.desc(t.date)]))
        .get();

    double netWorthOf(Map<int, double> bal) {
      double total = 0;
      for (final entry in bal.entries) {
        total += (signs[entry.key] ?? 0) * entry.value;
      }
      return total;
    }

    final today = DateTime.now();
    final startDay = DateTime(from.year, from.month, from.day);
    final endDay = DateTime(today.year, today.month, today.day);
    final totalDays = endDay.difference(startDay).inDays;

    final dailyNetWorth = <DateTime, double>{};
    var txnIndex = 0;
    final runningBalances = Map<int, double>.from(balances);

    for (int dayOffset = 0; dayOffset <= totalDays; dayOffset++) {
      final day = endDay.subtract(Duration(days: dayOffset));
      while (txnIndex < txns.length &&
          !txns[txnIndex].date.isBefore(day)) {
        final t = txns[txnIndex];
        if (t.type == 'expense') {
          runningBalances[t.accountId] =
              (runningBalances[t.accountId] ?? 0) + t.amount;
        } else if (t.type == 'income') {
          runningBalances[t.accountId] =
              (runningBalances[t.accountId] ?? 0) - t.amount;
        } else if (t.type == 'transfer') {
          runningBalances[t.accountId] =
              (runningBalances[t.accountId] ?? 0) + t.amount;
          if (t.toAccountId != null) {
            runningBalances[t.toAccountId!] =
                (runningBalances[t.toAccountId!] ?? 0) - t.amount;
          }
        }
        txnIndex++;
      }
      dailyNetWorth[day] = netWorthOf(runningBalances);
    }

    final result = dailyNetWorth.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    return result;
  }

  /// Net worth sampled at the end of each month across [start, end]
  /// (clamped to today for the current/future months), oldest first.
  Future<List<MapEntry<DateTime, double>>> getNetWorthByMonthRange(
      DateTime start, DateTime end) async {
    final daily =
        await getNetWorthHistory(DateTime(start.year, start.month, 1));
    if (daily.isEmpty) return [];
    final dailyMap = {for (final e in daily) e.key: e.value};
    final earliestDay = daily.first.key;
    final today = DateTime.now();

    final result = <MapEntry<DateTime, double>>[];
    var cursor = DateTime(start.year, start.month, 1);
    final last = DateTime(end.year, end.month, 1);
    while (!cursor.isAfter(last)) {
      final monthEnd = DateTime(cursor.year, cursor.month + 1, 0);
      final todayDay = DateTime(today.year, today.month, today.day);
      var probe = monthEnd.isAfter(todayDay) ? todayDay : monthEnd;
      double? value = dailyMap[probe];
      while (value == null && probe.isAfter(earliestDay)) {
        probe = probe.subtract(const Duration(days: 1));
        value = dailyMap[probe];
      }
      result.add(MapEntry(cursor, value ?? 0));
      cursor = DateTime(cursor.year, cursor.month + 1, 1);
    }
    return result;
  }

  // ── Category queries ─────────────────────────────────────────────────────────

  Stream<List<Category>> watchCategoriesByType(String type) =>
      (select(categories)..where((c) => c.type.equals(type))).watch();

  Future<List<Category>> getCategoriesByType(String type) =>
      (select(categories)..where((c) => c.type.equals(type))).get();

  Future<int> insertCategory(CategoriesCompanion entry) =>
      into(categories).insert(entry);

  Future<bool> updateCategory(CategoriesCompanion entry) =>
      update(categories).replace(entry);

  Future<int> deleteCategory(int id) =>
      (delete(categories)..where((c) => c.id.equals(id))).go();

  // ── Transaction queries ──────────────────────────────────────────────────────

  Stream<List<Transaction>> watchTransactionsByMonth(int year, int month) {
    final start = DateTime(year, month, 1);
    final end = DateTime(year, month + 1, 0, 23, 59, 59);
    return (select(transactions)
          ..where((t) => t.date.isBetweenValues(start, end))
          ..orderBy([(t) => OrderingTerm.desc(t.date)]))
        .watch();
  }

  Future<List<Transaction>> getTransactionsByDateRange(
      DateTime start, DateTime end) {
    return (select(transactions)
          ..where((t) => t.date.isBetweenValues(start, end))
          ..orderBy([(t) => OrderingTerm.desc(t.date)]))
        .get();
  }

  Future<List<Transaction>> getTransactionsByCategoryAndRange(
      int categoryId, DateTime start, DateTime end) {
    return (select(transactions)
          ..where((t) =>
              t.categoryId.equals(categoryId) &
              t.date.isBetweenValues(start, end))
          ..orderBy([(t) => OrderingTerm.desc(t.date)]))
        .get();
  }

  Future<List<Transaction>> getRecentTransactions({int limit = 10}) =>
      (select(transactions)
            ..orderBy([(t) => OrderingTerm.desc(t.date)])
            ..limit(limit))
          .get();

  Future<List<Transaction>> getAllTransactions() =>
      (select(transactions)..orderBy([(t) => OrderingTerm.desc(t.date)]))
          .get();

  /// Unfiltered transactions stream — used purely as a change-invalidation
  /// signal by providers whose totals span a range broader than one month.
  Stream<List<Transaction>> watchAllTransactions() =>
      (select(transactions)..orderBy([(t) => OrderingTerm.desc(t.date)]))
          .watch();

  Stream<List<Transaction>> watchTransactionsForAccount(int accountId) {
    return (select(transactions)
          ..where((t) =>
              t.accountId.equals(accountId) | t.toAccountId.equals(accountId))
          ..orderBy([(t) => OrderingTerm.desc(t.date)]))
        .watch();
  }

  Future<int> insertTransaction(TransactionsCompanion entry) =>
      into(transactions).insert(entry);

  Future<bool> updateTransaction(TransactionsCompanion entry) =>
      update(transactions).replace(entry);

  Future<int> deleteTransaction(int id) =>
      (delete(transactions)..where((t) => t.id.equals(id))).go();

  Future<double> getTotalByTypeAndMonth(
      String type, int year, int month) async {
    final start = DateTime(year, month, 1);
    final end = DateTime(year, month + 1, 0, 23, 59, 59);
    final result = await (select(transactions)
          ..where(
              (t) => t.type.equals(type) & t.date.isBetweenValues(start, end)))
        .get();
    return result.fold<double>(0.0, (sum, t) => sum + t.amount);
  }

  // ── Budget queries ────────────────────────────────────────────────────────────

  Future<List<BudgetLimit>> getBudgetsByMonth(int year, int month) =>
      (select(budgetLimits)
            ..where((b) => b.month.equals(month) & b.year.equals(year)))
          .get();

  Stream<List<BudgetLimit>> watchBudgetsByMonth(int year, int month) =>
      (select(budgetLimits)
            ..where((b) => b.month.equals(month) & b.year.equals(year)))
          .watch();

  /// Returns the budget for this category/month, or null if none is set.
  /// Uses the first match rather than [getSingleOrNull] so a stray
  /// duplicate row (e.g. from an older bug) doesn't crash the save flow.
  Future<BudgetLimit?> getBudgetForCategory(
      int categoryId, int year, int month) async {
    final rows = await (select(budgetLimits)
          ..where((b) =>
              b.categoryId.equals(categoryId) &
              b.month.equals(month) &
              b.year.equals(year)))
        .get();
    return rows.isEmpty ? null : rows.first;
  }

  Future<Category?> getCategoryById(int id) =>
      (select(categories)..where((c) => c.id.equals(id))).getSingleOrNull();

  Future<int> insertBudget(BudgetLimitsCompanion entry) =>
      into(budgetLimits).insert(entry);

  Future<bool> updateBudget(BudgetLimitsCompanion entry) =>
      update(budgetLimits).replace(entry);

  Future<int> deleteBudget(int id) =>
      (delete(budgetLimits)..where((b) => b.id.equals(id))).go();

  // ── Bill queries ──────────────────────────────────────────────────────────────

  Stream<List<Bill>> watchActiveBills() => (select(bills)
        ..where((b) => b.isActive.equals(true))
        ..orderBy([(b) => OrderingTerm.asc(b.nextDueDate)]))
      .watch();

  Future<List<Bill>> getUpcomingBills({int daysAhead = 7}) async {
    final now = DateTime.now();
    final future = now.add(Duration(days: daysAhead));
    return (select(bills)
          ..where((b) =>
              b.isActive.equals(true) &
              b.nextDueDate.isBetweenValues(now, future))
          ..orderBy([(b) => OrderingTerm.asc(b.nextDueDate)]))
        .get();
  }

  Future<int> insertBill(BillsCompanion entry) => into(bills).insert(entry);

  Future<bool> updateBill(BillsCompanion entry) => update(bills).replace(entry);

  Future<int> deleteBill(int id) =>
      (delete(bills)..where((b) => b.id.equals(id))).go();

  // ── Member queries ────────────────────────────────────────────────────────────

  Stream<List<Member>> watchAllMembers() => select(members).watch();

  Future<int> insertMember(MembersCompanion entry) =>
      into(members).insert(entry);

  Future<int> deleteMember(int id) =>
      (delete(members)..where((m) => m.id.equals(id))).go();

  // ── Tag queries ────────────────────────────────────────────────────────────────

  Stream<List<Tag>> watchAllTags() =>
      (select(tags)..orderBy([(t) => OrderingTerm.asc(t.name)])).watch();

  Future<Tag> getOrCreateTag(String name) async {
    final trimmed = name.trim();
    final existing = await (select(tags)..where((t) => t.name.equals(trimmed)))
        .getSingleOrNull();
    if (existing != null) return existing;
    final id = await into(tags).insert(TagsCompanion.insert(name: trimmed));
    return (select(tags)..where((t) => t.id.equals(id))).getSingle();
  }

  Future<void> setTransactionTags(int transactionId, List<String> tagNames) async {
    await transaction(() async {
      await (delete(transactionTags)
            ..where((tt) => tt.transactionId.equals(transactionId)))
          .go();
      for (final name in tagNames) {
        final tag = await getOrCreateTag(name);
        await into(transactionTags).insert(
          TransactionTagsCompanion.insert(
              transactionId: transactionId, tagId: tag.id),
          mode: InsertMode.insertOrIgnore,
        );
      }
    });
  }

  Future<List<Tag>> getTagsForTransaction(int transactionId) async {
    final query = select(tags).join([
      innerJoin(transactionTags, transactionTags.tagId.equalsExp(tags.id)),
    ])
      ..where(transactionTags.transactionId.equals(transactionId));
    final rows = await query.get();
    return rows.map((r) => r.readTable(tags)).toList();
  }

  Future<int> deleteTag(int id) =>
      (delete(tags)..where((t) => t.id.equals(id))).go();

  // ── Search ─────────────────────────────────────────────────────────────────────

  Future<List<Transaction>> searchTransactions({
    String? query,
    String? type,
    DateTime? startDate,
    DateTime? endDate,
    double? minAmount,
    double? maxAmount,
  }) async {
    final q = select(transactions);
    final predicates = <Expression<bool>>[];

    if (type != null && type.isNotEmpty) {
      predicates.add(transactions.type.equals(type));
    }
    if (startDate != null && endDate != null) {
      predicates.add(transactions.date.isBetweenValues(startDate, endDate));
    }
    if (minAmount != null) {
      predicates.add(transactions.amount.isBiggerOrEqualValue(minAmount));
    }
    if (maxAmount != null) {
      predicates.add(transactions.amount.isSmallerOrEqualValue(maxAmount));
    }
    if (query != null && query.trim().isNotEmpty) {
      final like = '%${query.trim()}%';
      predicates.add(transactions.note.like(like));
    }

    if (predicates.isNotEmpty) {
      q.where((_) => predicates.reduce((a, b) => a & b));
    }
    q.orderBy([(t) => OrderingTerm.desc(t.date)]);
    final results = await q.get();

    // Also match by amount-as-text and category/account name for richer full-text search
    if (query != null && query.trim().isNotEmpty) {
      final trimmed = query.trim().toLowerCase();
      final allMatching = await (select(transactions)
            ..orderBy([(t) => OrderingTerm.desc(t.date)]))
          .get();
      final catList = await getAllCategories();
      final accList = await getAllAccounts();
      final catMap = {for (final c in catList) c.id: c.name.toLowerCase()};
      final accMap = {for (final a in accList) a.id: a.name.toLowerCase()};

      final extraMatches = allMatching.where((t) {
        final noteMatch = t.note?.toLowerCase().contains(trimmed) ?? false;
        final amountMatch = t.amount.toString().contains(trimmed);
        final categoryMatch =
            t.categoryId != null && (catMap[t.categoryId] ?? '').contains(trimmed);
        final accountMatch = (accMap[t.accountId] ?? '').contains(trimmed);
        final typeMatch = t.type.toLowerCase().contains(trimmed);
        return noteMatch || amountMatch || categoryMatch || accountMatch || typeMatch;
      }).toList();

      final merged = {for (final t in [...results, ...extraMatches]) t.id: t};
      var combined = merged.values.toList()
        ..sort((a, b) => b.date.compareTo(a.date));

      if (type != null && type.isNotEmpty) {
        combined = combined.where((t) => t.type == type).toList();
      }
      if (startDate != null && endDate != null) {
        combined = combined
            .where((t) =>
                t.date.isAfter(startDate.subtract(const Duration(seconds: 1))) &&
                t.date.isBefore(endDate.add(const Duration(seconds: 1))))
            .toList();
      }
      if (minAmount != null) {
        combined = combined.where((t) => t.amount >= minAmount).toList();
      }
      if (maxAmount != null) {
        combined = combined.where((t) => t.amount <= maxAmount).toList();
      }
      return combined;
    }

    return results;
  }

  // ── Extended category queries ─────────────────────────────────────────────────

  Stream<List<Category>> watchAllCategories() =>
      (select(categories)
            ..orderBy([
              (c) => OrderingTerm.asc(c.type),
              (c) => OrderingTerm.asc(c.name),
            ]))
          .watch();

  Future<List<Category>> getAllCategories() => select(categories).get();

  // ── Atomic transaction + balance update ───────────────────────────────────────

  Future<int> insertTransactionWithBalanceUpdate(
      TransactionsCompanion txn) async {
    return await transaction(() async {
      final id = await into(transactions).insert(txn);
      await _applyBalanceDelta(
          txn.accountId.value, txn.type.value, txn.amount.value,
          toAccountId: txn.toAccountId.value);
      return id;
    });
  }

  Future<void> deleteTransactionWithBalanceUpdate(Transaction txn) async {
    await transaction(() async {
      await (delete(transactions)..where((t) => t.id.equals(txn.id))).go();
      await _applyBalanceDelta(txn.accountId, txn.type, txn.amount,
          toAccountId: txn.toAccountId, reverse: true);
    });
  }

  Future<void> updateTransactionWithBalanceUpdate(
      Transaction oldTxn, TransactionsCompanion newTxn) async {
    await transaction(() async {
      // Reverse old effect
      await _applyBalanceDelta(oldTxn.accountId, oldTxn.type, oldTxn.amount,
          toAccountId: oldTxn.toAccountId, reverse: true);
      // Apply new effect
      await _applyBalanceDelta(
          newTxn.accountId.value, newTxn.type.value, newTxn.amount.value,
          toAccountId: newTxn.toAccountId.value);
      // Save updated transaction
      await (update(transactions)..where((t) => t.id.equals(oldTxn.id)))
          .write(newTxn);
    });
  }

  Future<void> _applyBalanceDelta(int accountId, String type, double amount,
      {int? toAccountId, bool reverse = false}) async {
    final sign = reverse ? -1.0 : 1.0;
    final account =
        await (select(accounts)..where((a) => a.id.equals(accountId)))
            .getSingle();

    double delta = 0;
    if (type == 'expense') {
      delta = -amount * sign;
    } else if (type == 'income') {
      delta = amount * sign;
    } else if (type == 'transfer') {
      delta = -amount * sign;
    }

    await (update(accounts)..where((a) => a.id.equals(accountId))).write(
        AccountsCompanion(balance: Value(account.balance + delta)));

    if (type == 'transfer' && toAccountId != null) {
      final toAccount =
          await (select(accounts)..where((a) => a.id.equals(toAccountId)))
              .getSingle();
      await (update(accounts)..where((a) => a.id.equals(toAccountId))).write(
          AccountsCompanion(
              balance: Value(toAccount.balance + amount * sign)));
    }
  }

  // ── Member queries ────────────────────────────────────────────────────────────

  /// Expense total per member within a date range (entries with no member are excluded).
  Future<Map<int, double>> getMemberSpendingByRange(
      DateTime start, DateTime end) async {
    final txns = await (select(transactions)
          ..where((t) =>
              t.type.equals('expense') & t.date.isBetweenValues(start, end)))
        .get();

    final spending = <int, double>{};
    for (final t in txns) {
      if (t.memberId != null) {
        spending[t.memberId!] = (spending[t.memberId!] ?? 0) + t.amount;
      }
    }
    return spending;
  }

  Future<List<Transaction>> getTransactionsByMemberAndRange(
      int memberId, DateTime start, DateTime end) {
    return (select(transactions)
          ..where((t) =>
              t.memberId.equals(memberId) &
              t.date.isBetweenValues(start, end))
          ..orderBy([(t) => OrderingTerm.desc(t.date)]))
        .get();
  }

  // ── Reports queries ───────────────────────────────────────────────────────────

  Future<Map<int, double>> getCategorySpending(int year, int month) async {
    final start = DateTime(year, month, 1);
    final end = DateTime(year, month + 1, 0, 23, 59, 59);
    return getCategorySpendingByRange(start, end);
  }

  Future<Map<int, double>> getCategorySpendingByRange(
      DateTime start, DateTime end) async {
    final txns = await (select(transactions)
          ..where((t) =>
              t.type.equals('expense') & t.date.isBetweenValues(start, end)))
        .get();

    final spending = <int, double>{};
    for (final t in txns) {
      if (t.categoryId != null) {
        spending[t.categoryId!] = (spending[t.categoryId!] ?? 0) + t.amount;
      }
    }
    return spending;
  }

  Future<double> getTotalByTypeAndRange(
      String type, DateTime start, DateTime end) async {
    final result = await (select(transactions)
          ..where(
              (t) => t.type.equals(type) & t.date.isBetweenValues(start, end)))
        .get();
    return result.fold<double>(0.0, (sum, t) => sum + t.amount);
  }

  /// Income/expense totals per day across the given range, oldest first,
  /// zero-filled per day. Used to build the Insights "Overview" bar chart
  /// at day granularity (e.g. for a weekly timeframe).
  Future<List<Map<String, dynamic>>> getIncomeExpenseByDayRange(
      DateTime start, DateTime end) async {
    final startDay = DateTime(start.year, start.month, start.day);
    final endDay = DateTime(end.year, end.month, end.day);
    final txns = await (select(transactions)
          ..where((t) => t.date.isBetweenValues(startDay,
              endDay.add(const Duration(hours: 23, minutes: 59, seconds: 59)))))
        .get();

    final income = <DateTime, double>{};
    final expense = <DateTime, double>{};
    for (var d = startDay; !d.isAfter(endDay); d = d.add(const Duration(days: 1))) {
      income[d] = 0.0;
      expense[d] = 0.0;
    }
    for (final t in txns) {
      final day = DateTime(t.date.year, t.date.month, t.date.day);
      if (!income.containsKey(day)) continue;
      if (t.type == 'income') {
        income[day] = income[day]! + t.amount;
      } else if (t.type == 'expense') {
        expense[day] = expense[day]! + t.amount;
      }
    }
    return income.keys
        .map((d) => {
              'date': d,
              'income': income[d]!,
              'expense': expense[d]!,
            })
        .toList();
  }

  /// Income/expense totals per ISO week across the given range, oldest
  /// first. Used for the Insights "Overview" bar chart at week granularity
  /// (e.g. for a monthly timeframe).
  Future<List<Map<String, dynamic>>> getIncomeExpenseByWeekRange(
      DateTime start, DateTime end) async {
    final startDay = DateTime(start.year, start.month, start.day);
    final endDay = DateTime(end.year, end.month, end.day);
    final txns = await (select(transactions)
          ..where((t) => t.date.isBetweenValues(startDay,
              endDay.add(const Duration(hours: 23, minutes: 59, seconds: 59)))))
        .get();

    final weekStarts = <DateTime>[];
    for (var d = startDay; !d.isAfter(endDay); d = d.add(const Duration(days: 7))) {
      weekStarts.add(d);
    }
    final income = {for (final w in weekStarts) w: 0.0};
    final expense = {for (final w in weekStarts) w: 0.0};
    for (final t in txns) {
      final day = DateTime(t.date.year, t.date.month, t.date.day);
      final offsetDays = day.difference(startDay).inDays;
      final weekIndex = (offsetDays / 7).floor().clamp(0, weekStarts.length - 1);
      final weekStart = weekStarts[weekIndex];
      if (t.type == 'income') {
        income[weekStart] = income[weekStart]! + t.amount;
      } else if (t.type == 'expense') {
        expense[weekStart] = expense[weekStart]! + t.amount;
      }
    }
    return weekStarts
        .map((w) => {
              'date': w,
              'income': income[w]!,
              'expense': expense[w]!,
            })
        .toList();
  }

  /// Income/expense totals per month across the given range, oldest first.
  /// Used for the Insights "Overview" bar chart at month granularity
  /// (e.g. for a yearly timeframe).
  Future<List<Map<String, dynamic>>> getIncomeExpenseByMonthRange(
      DateTime start, DateTime end) async {
    final result = <Map<String, dynamic>>[];
    var cursor = DateTime(start.year, start.month, 1);
    final last = DateTime(end.year, end.month, 1);
    while (!cursor.isAfter(last)) {
      final income =
          await getTotalByTypeAndMonth('income', cursor.year, cursor.month);
      final expense =
          await getTotalByTypeAndMonth('expense', cursor.year, cursor.month);
      result.add({
        'year': cursor.year,
        'month': cursor.month,
        'income': income,
        'expense': expense,
      });
      cursor = DateTime(cursor.year, cursor.month + 1, 1);
    }
    return result;
  }

  /// Daily expense totals across the given range, oldest first, zero-filled per day.
  Future<List<MapEntry<DateTime, double>>> getDailySpendingByRange(
      DateTime start, DateTime end) async {
    final startDay = DateTime(start.year, start.month, start.day);
    final endDay = DateTime(end.year, end.month, end.day);
    final txns = await (select(transactions)
          ..where((t) =>
              t.type.equals('expense') &
              t.date.isBetweenValues(
                  startDay, endDay.add(const Duration(hours: 23, minutes: 59, seconds: 59)))))
        .get();

    final totals = <DateTime, double>{};
    for (var d = startDay;
        !d.isAfter(endDay);
        d = d.add(const Duration(days: 1))) {
      totals[d] = 0.0;
    }
    for (final t in txns) {
      final day = DateTime(t.date.year, t.date.month, t.date.day);
      if (totals.containsKey(day)) {
        totals[day] = totals[day]! + t.amount;
      }
    }
    return totals.entries.toList();
  }

  /// Daily expense totals across the given month, oldest first.
  Future<List<MapEntry<DateTime, double>>> getDailySpendingForMonth(
      int year, int month) async {
    final start = DateTime(year, month, 1);
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final end = DateTime(year, month, daysInMonth, 23, 59, 59);

    final txns = await (select(transactions)
          ..where((t) =>
              t.type.equals('expense') & t.date.isBetweenValues(start, end)))
        .get();

    final totals = <DateTime, double>{
      for (int d = 1; d <= daysInMonth; d++) DateTime(year, month, d): 0.0,
    };
    for (final t in txns) {
      final day = DateTime(t.date.year, t.date.month, t.date.day);
      if (totals.containsKey(day)) {
        totals[day] = totals[day]! + t.amount;
      }
    }
    return totals.entries.toList();
  }

  /// Daily expense totals for the 7 days ending today, oldest first.
  Future<List<MapEntry<DateTime, double>>> getWeeklySpending() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final start = today.subtract(const Duration(days: 6));
    final end = today.add(const Duration(days: 1));

    final txns = await (select(transactions)
          ..where((t) =>
              t.type.equals('expense') & t.date.isBetweenValues(start, end)))
        .get();

    final totals = <DateTime, double>{
      for (int i = 0; i < 7; i++) start.add(Duration(days: i)): 0.0,
    };
    for (final t in txns) {
      final day = DateTime(t.date.year, t.date.month, t.date.day);
      if (totals.containsKey(day)) {
        totals[day] = totals[day]! + t.amount;
      }
    }
    return totals.entries.toList();
  }

  // ── Account balance manual update ─────────────────────────────────────────────

  Future<void> updateAccountBalance(int accountId, double newBalance) async {
    await (update(accounts)..where((a) => a.id.equals(accountId)))
        .write(AccountsCompanion(balance: Value(newBalance)));
  }

  // ── Goals queries ─────────────────────────────────────────────────────────────

  Stream<List<Goal>> watchAllGoals({bool includeArchived = false}) {
    final query = select(goals);
    if (!includeArchived) {
      query.where((g) => g.isArchived.equals(false));
    }
    query.orderBy([(g) => OrderingTerm.desc(g.createdAt)]);
    return query.watch();
  }

  Future<int> insertGoal(GoalsCompanion entry) => into(goals).insert(entry);

  Future<bool> updateGoal(GoalsCompanion entry) =>
      update(goals).replace(entry);

  Future<void> archiveGoal(int id, {bool archived = true}) async {
    await (update(goals)..where((g) => g.id.equals(id)))
        .write(GoalsCompanion(isArchived: Value(archived)));
  }

  Future<int> deleteGoal(int id) async {
    return await transaction(() async {
      await (delete(goalTopUps)..where((t) => t.goalId.equals(id))).go();
      return (delete(goals)..where((g) => g.id.equals(id))).go();
    });
  }

  Stream<List<GoalTopUp>> watchTopUpsForGoal(int goalId) {
    return (select(goalTopUps)
          ..where((t) => t.goalId.equals(goalId))
          ..orderBy([(t) => OrderingTerm.desc(t.date)]))
        .watch();
  }

  Future<int> addGoalTopUp(GoalTopUpsCompanion entry) async {
    return await transaction(() async {
      final id = await into(goalTopUps).insert(entry);
      final goalId = entry.goalId.value;
      final goal =
          await (select(goals)..where((g) => g.id.equals(goalId)))
              .getSingle();
      await (update(goals)..where((g) => g.id.equals(goalId))).write(
          GoalsCompanion(
              savedAmount: Value(goal.savedAmount + entry.amount.value)));
      return id;
    });
  }

  // ── Future Plan & Commitment queries ──────────────────────────────────────────

  Future<MonthlyPlan?> getMonthlyPlan(int year, int month) =>
      (select(monthlyPlans)
            ..where((p) => p.year.equals(year) & p.month.equals(month)))
          .getSingleOrNull();

  Stream<MonthlyPlan?> watchMonthlyPlan(int year, int month) =>
      (select(monthlyPlans)
            ..where((p) => p.year.equals(year) & p.month.equals(month)))
          .watchSingleOrNull();

  Future<int> upsertMonthlyPlan(MonthlyPlansCompanion entry) =>
      into(monthlyPlans).insertOnConflictUpdate(entry);

  Stream<List<Commitment>> watchCommitmentsForMonth(int year, int month) {
    return (select(commitments)
          ..where((c) => c.year.equals(year) & c.month.equals(month))
          ..orderBy([(c) => OrderingTerm.asc(c.createdAt)]))
        .watch();
  }

  Future<int> insertCommitment(CommitmentsCompanion entry) =>
      into(commitments).insert(entry);

  Future<bool> updateCommitment(CommitmentsCompanion entry) =>
      update(commitments).replace(entry);

  Future<int> deleteCommitment(int id) =>
      (delete(commitments)..where((c) => c.id.equals(id))).go();
}

QueryExecutor _openConnection() {
  return driftDatabase(
    name: 'budgetku',
    web: DriftWebOptions(
      sqlite3Wasm: Uri.parse('sqlite3.wasm'),
      driftWorker: Uri.parse('drift_worker.js'),
    ),
  );
}
