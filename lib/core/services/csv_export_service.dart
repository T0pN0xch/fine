import 'dart:io';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import '../../data/database/app_database.dart';

/// Exports all transactions to a CSV file and opens the OS share sheet.
class CsvExportService {
  static Future<void> exportTransactions(AppDatabase db) async {
    final transactions = await db.getAllTransactions();
    final accounts = await db.getAllAccounts();
    final categories = await db.watchAllCategories().first;

    final accountNames = {for (final a in accounts) a.id: a.name};
    final categoryNames = {for (final c in categories) c.id: c.name};

    final rows = <List<String>>[
      ['Date', 'Type', 'Category', 'Account', 'To Account', 'Amount', 'Currency', 'Note'],
      for (final t in transactions)
        [
          DateFormat('yyyy-MM-dd HH:mm').format(t.date),
          t.type,
          t.categoryId != null ? (categoryNames[t.categoryId] ?? '') : '',
          accountNames[t.accountId] ?? '',
          t.toAccountId != null ? (accountNames[t.toAccountId] ?? '') : '',
          t.amount.toStringAsFixed(2),
          t.currency,
          t.note ?? '',
        ],
    ];

    final csv = const ListToCsvConverter().convert(rows);

    final dir = await getTemporaryDirectory();
    final fileName =
        'fine_transactions_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.csv';
    final file = File('${dir.path}/$fileName');
    await file.writeAsString(csv);

    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'Fine transaction export',
    );
  }
}
