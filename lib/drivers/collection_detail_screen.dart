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
    setupRealtimeSubscription();
  }

  Future<void> fetchTransactions() async {
    setState(() {
      isLoading = true;
    });
    try {
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

      final driverResponse = await supabase
          .from('drivers')
          .select('area_id')
          .eq('id', widget.driverId)
          .limit(1)
          .maybeSingle();

      if (driverResponse == null || driverResponse['area_id'] == null) {
        throw Exception('No area assigned to driver ID ${widget.driverId}');
      }
      final areaId = driverResponse['area_id'];

      final areaResponse = await supabase
          .from('delivery_areas')
          .select('area_name')
          .eq('id', areaId)
          .limit(1)
          .maybeSingle();

      if (areaResponse == null || areaResponse['area_name'] == null) {
        throw Exception('Area not found for area ID $areaId');
      }
      final areaName = areaResponse['area_name'];

      final usersResponse = await supabase
          .from('users')
          .select('id, full_name, location')
          .eq('location', areaName);

      List<Map<String, dynamic>> users =
          List<Map<String, dynamic>>.from(usersResponse);

      final transactionsResponse = await supabase
          .from('transactions')
          .select('user_id, credit, paid, date, mode_of_payment')
          .eq('driver_id', widget.driverId)
          .gte('date', startDate.toIso8601String())
          .lte('date', endDate.toIso8601String());

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

        var matchingUser = users.firstWhere(
          (user) => user['id'].toString() == userId,
          orElse: () => {'full_name': 'Customer $userId'},
        );
        final userName = matchingUser['full_name'];

        tempTransactionsByDateAndUser[dateKey] ??= {};
        tempTransactionsByDateAndUser[dateKey]![userName] ??= [];
        tempCreditTotalsByDateAndUser[dateKey] ??= {};
        tempCreditTotalsByDateAndUser[dateKey]![userName] ??= 0.0;
        tempPaidTotalsByDateAndUser[dateKey] ??= {};
        tempPaidTotalsByDateAndUser[dateKey]![userName] ??= 0.0;
        tempDailyCreditTotals[dateKey] ??= 0.0;
        tempDailyPaidTotals[dateKey] ??= 0.0;

        tempTransactionsByDateAndUser[dateKey]![userName]!.add({
          'credit': credit,
          'paid': paid,
          'mode_of_payment': modeOfPayment,
        });

        tempCreditTotalsByDateAndUser[dateKey]![userName] =
            tempCreditTotalsByDateAndUser[dateKey]![userName]! + credit;
        tempPaidTotalsByDateAndUser[dateKey]![userName] =
            tempPaidTotalsByDateAndUser[dateKey]![userName]! + paid;
        tempDailyCreditTotals[dateKey] =
            tempDailyCreditTotals[dateKey]! + credit;
        tempDailyPaidTotals[dateKey] = tempDailyPaidTotals[dateKey]! + paid;
      }

      if (widget.isTodayCollection) {
        final today = DateTime.now();
        final todayKey = DateTime(today.year, today.month, today.day);
        tempTransactionsByDateAndUser.removeWhere((key, _) => key != todayKey);
        tempCreditTotalsByDateAndUser.removeWhere((key, _) => key != todayKey);
        tempPaidTotalsByDateAndUser.removeWhere((key, _) => key != todayKey);
        tempDailyCreditTotals.removeWhere((key, _) => key != todayKey);
        tempDailyPaidTotals.removeWhere((key, _) => key != todayKey);
      }

      setState(() {
        transactionsByDateAndUser = tempTransactionsByDateAndUser;
        creditTotalsByDateAndUser = tempCreditTotalsByDateAndUser;
        paidTotalsByDateAndUser = tempPaidTotalsByDateAndUser;
        dailyCreditTotals = tempDailyCreditTotals;
        dailyPaidTotals = tempDailyPaidTotals;
        isLoading = false;
      });
    } catch (e, stackTrace) {
      print('Error fetching transactions: $e');
      print('Stack trace: $stackTrace');
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
    }
  }

  void setupRealtimeSubscription() {
    supabase
        .channel('driver_${widget.driverId}_collections')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'transactions',
          callback: (payload) {
            fetchTransactions();
          },
        )
        .subscribe();
  }

  @override
  void dispose() {
    supabase.channel('driver_${widget.driverId}_collections').unsubscribe();
    super.dispose();
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
            colors: [Color(0xFF0D0221), Color(0xFF2A1B3D)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: fetchTransactions,
            color: Colors.white,
            backgroundColor: const Color(0xFFE91E63),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back,
                              color: Colors.white, size: 24),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            widget.isTodayCollection
                                ? 'Today\'s Collection'
                                : 'Collection by Date',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Summary Card
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: Colors.black54, width: 1.5),
                                ),
                                child: const CircleAvatar(
                                  radius: 20,
                                  backgroundColor: Colors.grey,
                                  child:
                                      Icon(Icons.person, color: Colors.black54),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  widget.driverName,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            widget.isTodayCollection
                                ? 'Date: ${DateFormat('d MMMM yyyy').format(DateTime.now())}'
                                : 'Date Selected: ${DateFormat('d MMM yyyy').format(widget.dateRange.start)}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.black.withOpacity(0.7),
                            ),
                          ),
                          if (!widget.isTodayCollection) ...[
                            const SizedBox(height: 8),
                            Text(
                              'Grand Total: Credit ₹${grandCredit.toStringAsFixed(0)}, Paid ₹${grandPaid.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Transaction History
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Transaction History',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                        const SizedBox(height: 12),
                        isLoading
                            ? const Center(
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                ),
                              )
                            : transactionsByDateAndUser.isEmpty
                                ? Container(
                                    padding: const EdgeInsets.all(16),
                                    width: double.infinity,
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.info_outline,
                                          color: Colors.white.withOpacity(0.7),
                                          size: 40,
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'No transactions found.',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color:
                                                Colors.white.withOpacity(0.7),
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : ListView.builder(
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    itemCount: transactionsByDateAndUser.length,
                                    itemBuilder: (context, index) {
                                      final date = transactionsByDateAndUser
                                          .keys
                                          .toList()
                                        ..sort((a, b) => b.compareTo(a));
                                      final currentDate = date[index];
                                      final userTransactions =
                                          transactionsByDateAndUser[
                                              currentDate]!;
                                      final dailyCreditTotal =
                                          dailyCreditTotals[currentDate] ?? 0.0;
                                      final dailyPaidTotal =
                                          dailyPaidTotals[currentDate] ?? 0.0;

                                      return Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 12),
                                        child: Container(
                                          padding: const EdgeInsets.all(16),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black
                                                    .withOpacity(0.1),
                                                blurRadius: 6,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  Text(
                                                    DateFormat('d MMMM yyyy')
                                                        .format(currentDate),
                                                    style: const TextStyle(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: Colors.black87,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 8),
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  Text(
                                                    'Total Credit: ₹${dailyCreditTotal.toStringAsFixed(0)}',
                                                    style: const TextStyle(
                                                      fontSize: 14,
                                                      color: Colors.red,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                  Text(
                                                    'Total Paid: ₹${dailyPaidTotal.toStringAsFixed(0)}',
                                                    style: const TextStyle(
                                                      fontSize: 14,
                                                      color: Colors.green,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const Divider(height: 20),
                                              ...userTransactions.entries
                                                  .map((entry) {
                                                final userName = entry.key;
                                                final creditTotal =
                                                    creditTotalsByDateAndUser[
                                                            currentDate]![
                                                        userName]!;
                                                final paidTotal =
                                                    paidTotalsByDateAndUser[
                                                            currentDate]![
                                                        userName]!;

                                                return Padding(
                                                  padding: const EdgeInsets
                                                      .symmetric(vertical: 6),
                                                  child: Row(
                                                    children: [
                                                      Container(
                                                        decoration:
                                                            BoxDecoration(
                                                          shape:
                                                              BoxShape.circle,
                                                          border: Border.all(
                                                              color: Colors
                                                                  .black54,
                                                              width: 1.5),
                                                        ),
                                                        child:
                                                            const CircleAvatar(
                                                          radius: 18,
                                                          backgroundColor:
                                                              Colors.grey,
                                                          child: Icon(
                                                              Icons.person,
                                                              color: Colors
                                                                  .black54,
                                                              size: 18),
                                                        ),
                                                      ),
                                                      const SizedBox(width: 12),
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
                                                                fontSize: 15,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                                color: Colors
                                                                    .black87,
                                                              ),
                                                            ),
                                                            const SizedBox(
                                                                height: 4),
                                                            Text(
                                                              'Credit: ₹${creditTotal.toStringAsFixed(2)}',
                                                              style:
                                                                  const TextStyle(
                                                                fontSize: 13,
                                                                color:
                                                                    Colors.red,
                                                              ),
                                                            ),
                                                            Text(
                                                              'Paid: ₹${paidTotal.toStringAsFixed(2)}',
                                                              style:
                                                                  const TextStyle(
                                                                fontSize: 13,
                                                                color: Colors
                                                                    .green,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                );
                                              }).toList(),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
