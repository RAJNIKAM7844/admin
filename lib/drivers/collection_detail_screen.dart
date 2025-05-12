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
    required this.isTodayCollection,
  });

  @override
  State<CollectionDetailsScreen> createState() =>
      _CollectionDetailsScreenState();
}

class _CollectionDetailsScreenState extends State<CollectionDetailsScreen> {
  final supabase = Supabase.instance.client;
  double creditTotal = 0.0;
  double paidTotal = 0.0;
  List<Map<String, dynamic>> transactions = [];
  bool isLoading = true;
  Map<String, String> userIdToName = {};

  @override
  void initState() {
    super.initState();
    print(
        'Initializing CollectionDetailsScreen with driverId: ${widget.driverId}, dateRange: ${widget.dateRange.start} to ${widget.dateRange.end}');
    fetchCollections();
  }

  Future<void> fetchCollections() async {
    setState(() {
      isLoading = true;
    });
    try {
      print(
          'Fetching collections for driver ID: ${widget.driverId}, Date range: ${widget.dateRange.start} to ${widget.dateRange.end}');

      // Fetch users (without area filtering to simplify)
      final usersResponse = await supabase
          .from('users')
          .select('id, full_name')
          .eq('role', 'customer');
      print('Users response: $usersResponse');

      userIdToName.clear();
      for (var user in usersResponse) {
        userIdToName[user['id'].toString()] = user['full_name'];
      }
      print('User ID to Name mapping: $userIdToName');

      // Fetch transactions for the date range
      final startDate = widget.dateRange.start;
      final endDate = DateTime(
        widget.dateRange.end.year,
        widget.dateRange.end.month,
        widget.dateRange.end.day,
        23,
        59,
        59,
      );
      print('Querying transactions from $startDate to $endDate');

      final transactionsResponse = await supabase
          .from('transactions')
          .select('user_id, credit, paid, date, mode_of_payment')
          .eq('driver_id', widget.driverId)
          .gte('date', startDate.toIso8601String())
          .lte('date', endDate.toIso8601String());
      print('Transactions response: $transactionsResponse');

      double tempCreditTotal = 0.0;
      double tempPaidTotal = 0.0;
      List<Map<String, dynamic>> tempTransactions = [];

      for (var transaction in transactionsResponse) {
        final userId = transaction['user_id'].toString();
        final credit = (transaction['credit'] as num?)?.toDouble() ?? 0.0;
        final paid = (transaction['paid'] as num?)?.toDouble() ?? 0.0;
        final date = transaction['date'] != null
            ? DateTime.parse(transaction['date']).toLocal()
            : DateTime.now();
        final modeOfPayment =
            transaction['mode_of_payment']?.toString() ?? 'N/A';

        final userName = userIdToName[userId] ?? 'Customer $userId';
        print(
            'Processing transaction for user $userId ($userName): Credit $credit, Paid $paid');

        tempCreditTotal += credit;
        tempPaidTotal += paid;
        tempTransactions.add({
          'user_name': userName,
          'credit': credit,
          'paid': paid,
          'date': date,
          'mode_of_payment': modeOfPayment,
        });
      }

      setState(() {
        creditTotal = tempCreditTotal;
        paidTotal = tempPaidTotal;
        transactions = tempTransactions;
        isLoading = false;
      });
      print('Transactions: $transactions');
      print('Total Credit: $creditTotal, Total Paid: $paidTotal');
    } catch (e, stackTrace) {
      print('Error fetching collections: $e');
      print('Stack trace: $stackTrace');
      setState(() {
        creditTotal = 0.0;
        paidTotal = 0.0;
        transactions = [];
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load collections: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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
          child: Column(
            children: [
              // Header
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                            ? '${widget.driverName}\'s Today Collection'
                            : '${widget.driverName}\'s Collection',
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
              // Collection Summary
              Expanded(
                child: RefreshIndicator(
                  onRefresh: fetchCollections,
                  color: Colors.white,
                  backgroundColor: const Color(0xFFE91E63),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
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
                              children: [
                                Text(
                                  widget.isTodayCollection
                                      ? 'Today\'s Collection'
                                      : 'Collection Details',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  widget.isTodayCollection
                                      ? 'Date: ${DateFormat('d MMMM yyyy').format(DateTime.now())}'
                                      : 'Date: ${DateFormat('d MMMM yyyy').format(widget.dateRange.start)}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.black.withOpacity(0.7),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Total Credit:',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black.withOpacity(0.8),
                                      ),
                                    ),
                                    Text(
                                      '₹${creditTotal.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.red,
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
                                      'Total Paid:',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black.withOpacity(0.8),
                                      ),
                                    ),
                                    Text(
                                      '₹${paidTotal.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.green,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Transaction Details',
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
                              : transactions.isEmpty
                                  ? Center(
                                      child: Text(
                                        'No transactions found for this date.',
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.7),
                                          fontSize: 15,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    )
                                  : ListView.builder(
                                      shrinkWrap: true,
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      itemCount: transactions.length,
                                      itemBuilder: (context, index) {
                                        final transaction = transactions[index];
                                        return Card(
                                          margin: const EdgeInsets.symmetric(
                                              vertical: 6),
                                          elevation: 3,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: ListTile(
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                                    horizontal: 16,
                                                    vertical: 8),
                                            leading: Container(
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                    color: Colors.black54,
                                                    width: 1.5),
                                              ),
                                              child: CircleAvatar(
                                                radius: 18,
                                                backgroundColor:
                                                    Colors.grey.shade200,
                                                child: Icon(Icons.person,
                                                    color: Colors.black54,
                                                    size: 18),
                                              ),
                                            ),
                                            title: Text(
                                              transaction['user_name'],
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 15,
                                                color: Colors.black87,
                                              ),
                                            ),
                                            subtitle: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                const SizedBox(height: 6),
                                                Text(
                                                  'Credit: ₹${transaction['credit'].toStringAsFixed(2)}',
                                                  style: const TextStyle(
                                                      fontSize: 13,
                                                      color: Colors.red),
                                                ),
                                                Text(
                                                  'Paid: ₹${transaction['paid'].toStringAsFixed(2)}',
                                                  style: const TextStyle(
                                                      fontSize: 13,
                                                      color: Colors.green),
                                                ),
                                                Text(
                                                  'Mode: ${transaction['mode_of_payment']}',
                                                  style: TextStyle(
                                                      fontSize: 13,
                                                      color: Colors.black
                                                          .withOpacity(0.6)),
                                                ),
                                                Text(
                                                  'Time: ${DateFormat('h:mm a').format(transaction['date'])}',
                                                  style: TextStyle(
                                                      fontSize: 13,
                                                      color: Colors.black
                                                          .withOpacity(0.6)),
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
