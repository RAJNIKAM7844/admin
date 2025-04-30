import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class CollectionDetailsScreen extends StatefulWidget {
  final int driverId;
  final String driverName;
  final DateTimeRange dateRange;
  final bool isTodayCollection;

  const CollectionDetailsScreen({
    super.key,
    required this.driverId,
    required this.driverName,
    required this.dateRange,
    this.isTodayCollection = false,
  });

  @override
  State<CollectionDetailsScreen> createState() =>
      _CollectionDetailsScreenState();
}

class _CollectionDetailsScreenState extends State<CollectionDetailsScreen> {
  final supabase = Supabase.instance.client;
  Map<DateTime, Map<String, List<Map<String, dynamic>>>>
      transactionsByDateAndUser = {};
  Map<DateTime, Map<String, double>> creditTotalsByDateAndUser = {};
  Map<DateTime, Map<String, double>> paidTotalsByDateAndUser = {};
  Map<DateTime, double> dailyCreditTotals = {};
  Map<DateTime, double> dailyPaidTotals = {};
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    fetchTransactions();
  }

  Future<void> fetchTransactions() async {
    setState(() {
      isLoading = true;
    });
    try {
      // Determine the date range for fetching transactions
      DateTime startDate;
      DateTime endDate;
      if (widget.isTodayCollection) {
        final today = DateTime.now();
        startDate = DateTime(today.year, today.month, today.day);
        endDate = DateTime(today.year, today.month, today.day, 23, 59, 59);
      } else {
        startDate = DateTime(widget.dateRange.start.year,
            widget.dateRange.start.month, widget.dateRange.start.day);
        endDate = DateTime(widget.dateRange.end.year,
            widget.dateRange.end.month, widget.dateRange.end.day, 23, 59, 59);
      }

      print('Fetching transactions from $startDate to $endDate');

      // Step 1: Fetch the driver's area_id from drivers table
      final driverResponse = await supabase
          .from('drivers')
          .select('area_id')
          .eq('id', widget.driverId)
          .limit(1)
          .maybeSingle();

      if (driverResponse == null || driverResponse['area_id'] == null) {
        setState(() {
          transactionsByDateAndUser = {};
          creditTotalsByDateAndUser = {};
          paidTotalsByDateAndUser = {};
          dailyCreditTotals = {};
          dailyPaidTotals = {};
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No area assigned to this driver')),
        );
        return;
      }

      final areaId = driverResponse['area_id'];

      // Step 2: Fetch the area_name from delivery_areas using area_id
      final areaResponse = await supabase
          .from('delivery_areas')
          .select('area_name')
          .eq('id', areaId)
          .limit(1)
          .maybeSingle();

      if (areaResponse == null || areaResponse['area_name'] == null) {
        setState(() {
          transactionsByDateAndUser = {};
          creditTotalsByDateAndUser = {};
          paidTotalsByDateAndUser = {};
          dailyCreditTotals = {};
          dailyPaidTotals = {};
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Area not found')),
        );
        return;
      }

      final areaName = areaResponse['area_name'];
      print('Area name: $areaName');

      // Step 3: Fetch users in the driver's area
      final usersResponse = await supabase
          .from('users')
          .select('id, full_name, location')
          .eq('location', areaName);

      List<Map<String, dynamic>> users =
          List<Map<String, dynamic>>.from(usersResponse);
      print('Users fetched: $users');

      // Step 4: Fetch transactions for the specified date range
      final transactionsResponse = await supabase
          .from('transactions')
          .select('user_id, credit, paid, date, mode_of_payment')
          .gte('date', startDate.toIso8601String())
          .lte('date', endDate.toIso8601String());

      print('Transactions fetched: $transactionsResponse');

      // Step 5: Group transactions by date and user
      Map<DateTime, Map<String, List<Map<String, dynamic>>>>
          tempTransactionsByDateAndUser = {};
      Map<DateTime, Map<String, double>> tempCreditTotalsByDateAndUser = {};
      Map<DateTime, Map<String, double>> tempPaidTotalsByDateAndUser = {};
      Map<DateTime, double> tempDailyCreditTotals = {};
      Map<DateTime, double> tempDailyPaidTotals = {};

      for (var transaction in transactionsResponse) {
        final userId = transaction['user_id'].toString();
        final credit = (transaction['credit'] as num?)?.toDouble() ?? 0.0;
        final paid = (transaction['paid'] as num?)?.toDouble() ?? 0.0;
        final modeOfPayment =
            transaction['mode_of_payment']?.toString() ?? 'N/A';
        final transactionDate = DateTime.parse(transaction['date']).toLocal();
        final dateKey = DateTime(
            transactionDate.year, transactionDate.month, transactionDate.day);

        // Find matching user
        var matchingUser = users.firstWhere(
          (user) => user['id'].toString() == userId,
          orElse: () => {'full_name': 'Customer $userId'},
        );

        final userName = matchingUser['full_name'];

        // Initialize data structures
        tempTransactionsByDateAndUser[dateKey] ??= {};
        tempTransactionsByDateAndUser[dateKey]![userName] ??= [];
        tempCreditTotalsByDateAndUser[dateKey] ??= {};
        tempCreditTotalsByDateAndUser[dateKey]![userName] ??= 0.0;
        tempPaidTotalsByDateAndUser[dateKey] ??= {};
        tempPaidTotalsByDateAndUser[dateKey]![userName] ??= 0.0;
        tempDailyCreditTotals[dateKey] ??= 0.0;
        tempDailyPaidTotals[dateKey] ??= 0.0;

        // Add transaction to the user’s list for the date
        tempTransactionsByDateAndUser[dateKey]![userName]!.add({
          'credit': credit,
          'paid': paid,
          'mode_of_payment': modeOfPayment,
        });

        // Update totals
        tempCreditTotalsByDateAndUser[dateKey]![userName] =
            tempCreditTotalsByDateAndUser[dateKey]![userName]! + credit;
        tempPaidTotalsByDateAndUser[dateKey]![userName] =
            tempPaidTotalsByDateAndUser[dateKey]![userName]! + paid;
        tempDailyCreditTotals[dateKey] =
            tempDailyCreditTotals[dateKey]! + credit;
        tempDailyPaidTotals[dateKey] = tempDailyPaidTotals[dateKey]! + paid;
      }

      // For "Today Collection", ensure only today's transactions are shown
      if (widget.isTodayCollection) {
        final today = DateTime.now();
        final todayKey = DateTime(today.year, today.month, today.day);
        tempTransactionsByDateAndUser.removeWhere((key, _) => key != todayKey);
        tempCreditTotalsByDateAndUser.removeWhere((key, _) => key != todayKey);
        tempPaidTotalsByDateAndUser.removeWhere((key, _) => key != todayKey);
        tempDailyCreditTotals.removeWhere((key, _) => key != todayKey);
        tempDailyPaidTotals.removeWhere((key, _) => key != todayKey);
        print('Filtered for today ($todayKey): $tempTransactionsByDateAndUser');
      }

      setState(() {
        transactionsByDateAndUser = tempTransactionsByDateAndUser;
        creditTotalsByDateAndUser = tempCreditTotalsByDateAndUser;
        paidTotalsByDateAndUser = tempPaidTotalsByDateAndUser;
        dailyCreditTotals = tempDailyCreditTotals;
        dailyPaidTotals = tempDailyPaidTotals;
        isLoading = false;
      });

      print('Transactions by date and user: $tempTransactionsByDateAndUser');
      print('Credit totals: $tempCreditTotalsByDateAndUser');
      print('Paid totals: $tempPaidTotalsByDateAndUser');
      print('Daily credit totals: $tempDailyCreditTotals');
      print('Daily paid totals: $tempDailyPaidTotals');
    } catch (e) {
      setState(() {
        transactionsByDateAndUser = {};
        creditTotalsByDateAndUser = {};
        paidTotalsByDateAndUser = {};
        dailyCreditTotals = {};
        dailyPaidTotals = {};
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching transactions: $e')),
      );
      print('Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final grandCredit =
        dailyCreditTotals.values.fold(0.0, (sum, total) => sum + total);
    final grandPaid =
        dailyPaidTotals.values.fold(0.0, (sum, total) => sum + total);

    return Scaffold(
      body: Container(
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF1A0841),
              Color(0xFF3B322C),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      widget.isTodayCollection
                          ? 'Today\'s Collection'
                          : 'Collection by Date',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.refresh, color: Colors.white),
                      onPressed: fetchTransactions,
                    ),
                  ],
                ),
              ),
              // Driver Info and Grand Totals
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                child: Column(
                  children: [
                    Material(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 12, horizontal: 16),
                        child: Row(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border:
                                    Border.all(color: Colors.white70, width: 2),
                              ),
                              child: const CircleAvatar(
                                radius: 26,
                                backgroundColor: Colors.grey,
                                child: Icon(Icons.person,
                                    color: Colors.black54, size: 28),
                              ),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: Text(
                                widget.driverName,
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (!widget.isTodayCollection) ...[
                      Text(
                        'Date Range: ${DateFormat('d MMM yyyy').format(widget.dateRange.start)} - ${DateFormat('d MMM yyyy').format(widget.dateRange.end)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Grand Total: Credit ₹${grandCredit.toStringAsFixed(0)}, Paid ₹${grandPaid.toStringAsFixed(0)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                    if (widget.isTodayCollection)
                      Text(
                        'Date: ${DateFormat('d MMMM yyyy').format(DateTime.now())}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                  ],
                ),
              ),
              // Transactions List
              Expanded(
                child: isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : transactionsByDateAndUser.isEmpty
                        ? const Center(
                            child: Text(
                              'No transactions found.',
                              style: TextStyle(
                                  color: Colors.white70, fontSize: 18),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: transactionsByDateAndUser.length,
                            itemBuilder: (context, index) {
                              final date = transactionsByDateAndUser.keys
                                  .toList()
                                ..sort((a, b) =>
                                    b.compareTo(a)); // Sort descending
                              final currentDate = date[index];
                              final userTransactions =
                                  transactionsByDateAndUser[currentDate]!;
                              final dailyCreditTotal =
                                  dailyCreditTotals[currentDate] ?? 0.0;
                              final dailyPaidTotal =
                                  dailyPaidTotals[currentDate] ?? 0.0;

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: Material(
                                  color: Colors.grey[300],
                                  borderRadius: BorderRadius.circular(16),
                                  child: Container(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // Date and Daily Totals
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              DateFormat('d MMMM yyyy')
                                                  .format(currentDate),
                                              style: const TextStyle(
                                                color: Colors.black,
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              'Total Credit: ₹${dailyCreditTotal.toStringAsFixed(0)}',
                                              style: const TextStyle(
                                                color: Colors.black,
                                                fontSize: 16,
                                              ),
                                            ),
                                            Text(
                                              'Total Paid: ₹${dailyPaidTotal.toStringAsFixed(0)}',
                                              style: const TextStyle(
                                                color: Colors.black,
                                                fontSize: 16,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const Divider(),
                                        // Customer List for the Date
                                        ...userTransactions.entries
                                            .map((entry) {
                                          final userName = entry.key;
                                          final transactions = entry.value;
                                          final creditTotal =
                                              creditTotalsByDateAndUser[
                                                      currentDate]![userName] ??
                                                  0.0;
                                          final paidTotal =
                                              paidTotalsByDateAndUser[
                                                      currentDate]![userName] ??
                                                  0.0;

                                          return Padding(
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 8),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Container(
                                                      decoration: BoxDecoration(
                                                        shape: BoxShape.circle,
                                                        border: Border.all(
                                                            color:
                                                                Colors.black54,
                                                            width: 2),
                                                      ),
                                                      child: const CircleAvatar(
                                                        radius: 20,
                                                        backgroundColor:
                                                            Colors.grey,
                                                        child: Icon(
                                                            Icons.person,
                                                            color:
                                                                Colors.black54,
                                                            size: 22),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 16),
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          Text(
                                                            userName,
                                                            style:
                                                                const TextStyle(
                                                              color:
                                                                  Colors.black,
                                                              fontSize: 16,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                            ),
                                                          ),
                                                          Text(
                                                            'Credit: ₹${creditTotal.toStringAsFixed(2)}',
                                                            style:
                                                                const TextStyle(
                                                              color: Colors
                                                                  .black54,
                                                              fontSize: 14,
                                                            ),
                                                          ),
                                                          Text(
                                                            'Paid: ₹${paidTotal.toStringAsFixed(2)}',
                                                            style:
                                                                const TextStyle(
                                                              color: Colors
                                                                  .black54,
                                                              fontSize: 14,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 8),
                                                // Transaction Details
                                                ...transactions
                                                    .map((transaction) {
                                                  final credit =
                                                      transaction['credit']
                                                          as double;
                                                  final paid =
                                                      transaction['paid']
                                                          as double;
                                                  final modeOfPayment =
                                                      transaction[
                                                              'mode_of_payment']
                                                          as String;
                                                  return Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                            left: 56,
                                                            bottom: 4),
                                                    child: Text(
                                                      'Credit: ₹${credit.toStringAsFixed(2)}, Paid: ₹${paid.toStringAsFixed(2)}, Mode: $modeOfPayment',
                                                      style: const TextStyle(
                                                        color: Colors.black54,
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                  );
                                                }).toList(),
                                              ],
                                            ),
                                          );
                                        }).toList(),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
