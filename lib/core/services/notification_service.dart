import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../utils/currency_formatter.dart';
import '../../data/database/app_database.dart';

/// Wraps flutter_local_notifications for instant budget-threshold alerts.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: androidSettings);
    await _plugin.initialize(settings);
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    _initialized = true;
  }

  Future<void> showBudgetAlert({
    required int categoryId,
    required String title,
    required String body,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'budget_alerts',
      'Budget Alerts',
      channelDescription: 'Notifies when a category nears or exceeds its budget',
      importance: Importance.high,
      priority: Priority.high,
    );
    const details = NotificationDetails(android: androidDetails);
    // Stable per-category id so a repeat alert in the same month replaces the last one.
    await _plugin.show(categoryId, title, body, details);
  }

  /// Checks the given category's budget for [year]/[month] against [spent]
  /// and fires an 80%-warning or 100%-exceeded alert if a threshold was just
  /// crossed by this transaction (i.e. [spent] crosses but [previousSpent] did not).
  Future<void> checkBudgetThreshold({
    required AppDatabase db,
    required int categoryId,
    required int year,
    required int month,
    required double previousSpent,
    required double spent,
  }) async {
    final budget = await db.getBudgetForCategory(categoryId, year, month);
    if (budget == null || budget.limitAmount <= 0) return;

    final category = await db.getCategoryById(categoryId);
    final name = category?.name ?? 'category';
    final limit = budget.limitAmount;

    final wasOver = previousSpent > limit;
    final isOver = spent > limit;
    final wasWarning = previousSpent >= limit * 0.8;
    final isWarning = spent >= limit * 0.8;

    if (isOver && !wasOver) {
      await showBudgetAlert(
        categoryId: categoryId,
        title: 'Budget exceeded: $name',
        body:
            'You\'ve spent ${CurrencyFormatter.format(spent)} of your ${CurrencyFormatter.format(limit)} budget.',
      );
    } else if (isWarning && !wasWarning) {
      await showBudgetAlert(
        categoryId: categoryId,
        title: 'Budget warning: $name',
        body:
            'You\'ve used ${(spent / limit * 100).toStringAsFixed(0)}% of your ${CurrencyFormatter.format(limit)} budget.',
      );
    }
  }
}
