import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class CollectionDetailsScreen extends StatefulWidget {
  final int driverId;
  final String driverName;
  final DateTimeRange dateRange;
  final bool isTodayCollection; // Added to differentiate between modes

  const CollectionDetailsScreen({
    super.key,
    required this.driverId,
    required this.driverName,
    required this.dateRange,
    this.isTodayCollection = false, // Default to false
  });

  @override
  State<CollectionDetailsScreen> createState() =>
      _CollectionDetailsScreenState();
}

class _CollectionDetailsScreenState extends State<CollectionDetailsScreen> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> transactions = [];
  double totalCollection = 0.0;
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
        startDate = DateTime.now();
        endDate = startDate;
      } else {
        startDate = widget.dateRange.start;
        endDate = widget.dateRange.end;
      }

      // Step 1: Fetch the driver's area
      final driverAreaResponse = await supabase
          .from('delivery_areas')
          .select('area_name')
          .eq('driver_id', widget.driverId)
          .limit(1)
          .maybeSingle();

      if (driverAreaResponse == null ||
          driverAreaResponse['area_name'] == null) {
        setState(() {
          transactions = [];
          totalCollection = 0.0;
          isLoading = false;
        });
        return;
      }

      final areaName = driverAreaResponse['area_name'];

      // Step 2: Fetch users in the driver's area
      final usersResponse = await supabase
          .from('users')
          .select('id, full_name, location')
          .eq('location', areaName);

      List<Map<String, dynamic>> users =
          List<Map<String, dynamic>>.from(usersResponse);
      print('Users fetched: $users'); // Debug users

      // Step 3: Fetch transactions for the specified date range
      final transactionsResponse = await supabase
          .from('transactions')
          .select('user_id, amount, created_at')
          .gte('created_at', startDate.toIso8601String())
          .lte('created_at', endDate.toIso8601String());

      print(
          'Transactions fetched: $transactionsResponse'); // Debug transactions

      // Step 4: Map transactions to users
      List<Map<String, dynamic>> tempTransactions = [];
      Map<String, double> userAmountMap = {};

      for (var transaction in transactionsResponse) {
        final userId = transaction['user_id'].toString();
        final amount = (transaction['amount'] as num).toDouble();

        // Try to find a matching user
        var matchingUser = users.firstWhere(
          (user) => user['id'].toString() == userId,
          orElse: () => {'full_name': 'Customer $userId'},
        );

        final userName = matchingUser['full_name'];
        userAmountMap[userName] = (userAmountMap[userName] ?? 0.0) + amount;
      }

      // Convert the map to a list of transactions
      tempTransactions = userAmountMap.entries.map((entry) {
        return {
          'user_name': entry.key,
          'amount': entry.value,
        };
      }).toList();

      setState(() {
        transactions = tempTransactions;
        totalCollection = transactions.fold(0.0, (sum, t) => sum + t['amount']);
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        transactions = [];
        totalCollection = 0.0;
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching transactions: $e')),
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
                    const Text(
                      'Collection Today',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const Spacer(),
                  ],
                ),
              ),

              // Date, Driver, and Total Collection
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                child: Column(
                  children: [
                    Text(
                      "Today's Date ${DateFormat('d MMMM yyyy').format(widget.isTodayCollection ? DateTime.now() : widget.dateRange.start)}",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 20),
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
                    Text(
                      '\$${totalCollection.toStringAsFixed(0)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              // Customer List
              Expanded(
                child: isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : transactions.isEmpty
                        ? const Center(
                            child: Text(
                              'No transactions found.',
                              style: TextStyle(
                                  color: Colors.white70, fontSize: 18),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: transactions.length,
                            itemBuilder: (context, index) {
                              final transaction = transactions[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: Material(
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
                                            border: Border.all(
                                                color: Colors.white70,
                                                width: 2),
                                          ),
                                          child: const CircleAvatar(
                                            radius: 26,
                                            backgroundColor: Colors.grey,
                                            child: Icon(Icons.person,
                                                color: Colors.black54,
                                                size: 28),
                                          ),
                                        ),
                                        const SizedBox(width: 20),
                                        Expanded(
                                          child: Text(
                                            transaction['user_name'] ??
                                                'Unknown',
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
