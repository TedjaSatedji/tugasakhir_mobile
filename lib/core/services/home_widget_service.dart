import 'package:home_widget/home_widget.dart';
import 'package:intl/intl.dart';
import '../../providers/transaction_provider.dart';

class HomeWidgetService {
  static const String _androidWidgetName = 'QuestifyWidgetProvider';

  static Future<void> updateFromTransactions(
    TransactionProvider provider,
  ) async {
    final formatter = NumberFormat('#,##0', 'en_US');
    await HomeWidget.saveWidgetData(
      'balance',
      'Rp${formatter.format(provider.balance)}',
    );
    await HomeWidget.saveWidgetData(
      'income',
      'Rp${formatter.format(provider.totalIncome)}',
    );
    await HomeWidget.saveWidgetData(
      'expense',
      'Rp${formatter.format(provider.totalExpense)}',
    );
    await HomeWidget.updateWidget(androidName: _androidWidgetName);
  }
}
