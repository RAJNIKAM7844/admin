import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class VipTotalCollectionScreen extends StatefulWidget {
  const VipTotalCollectionScreen({super.key});

  @override
  State<VipTotalCollectionScreen> createState() =>
      _VipTotalCollectionScreenState();
}

class _VipTotalCollectionScreenState extends State<VipTotalCollectionScreen> {
  final supabase = Supabase.instance.client;
  Map<String, List<Map<String, dynamic>>> transactionsByUser = {};
  Map<String, double> amountTotalsByUser = {};
  double totalAmount = 0.0;
  bool isLoading = false;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    fetchCollections();
    setupRealtimeSubscription();
  }

  Future<void> fetchCollections() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });
    try {
      // Fetch users for full_name mapping
      final usersResponse =
          await supabase.from('wholesale_users').select('id, full_name');
      final users = List<Map<String, dynamic>>.from(usersResponse);
      final userIdToName = {
        for (var user in users) user['id'].toString(): user['full_name']
      };

      // Fetch transactions for today
      final today = DateTime.now();
      final startDate = DateTime(today.year, today.month, today.day);
      final endDate = DateTime(today.year, today.month, today.day, 23, 59, 59);

      final transactionsResponse = await supabase
          .from('wholesale_transaction')
          .select('user_id, paid, credit, mode_of_payment, date')
          .gte('date', startDate.toIso8601String())
          .lte('date', endDate.toIso8601String());

      Map<String, List<Map<String, dynamic>>> tempTransactionsByUser = {};
      Map<String, double> tempAmountTotalsByUser = {};
      double tempTotalAmount = 0.0;

      for (var transaction in transactionsResponse) {
        final userId = transaction['user_id'].toString();
        final paid = (transaction['paid'] as num?)?.toDouble() ?? 0.0;

        // Get user name
        final userName = userIdToName[userId] ?? 'Customer $userId';

        // Initialize data structures
        tempTransactionsByUser[userName] ??= [];
        tempAmountTotalsByUser[userName] ??= 0.0;

        // Add transaction
        tempTransactionsByUser[userName]!.add({
          'paid': paid,
          'credit': (transaction['credit'] as num?)?.toDouble() ?? 0.0,
          'mode_of_payment': transaction['mode_of_payment'] ?? 'N/A',
        });

        // Update totals (based on paid amount)
        tempAmountTotalsByUser[userName] =
            tempAmountTotalsByUser[userName]! + paid;
        tempTotalAmount += paid;
      }

      setState(() {
        transactionsByUser = tempTransactionsByUser;
        amountTotalsByUser = tempAmountTotalsByUser;
        totalAmount = tempTotalAmount;
        isLoading = false;
      });
    } on PostgrestException catch (e) {
      String message;
      if (e.code == '42P01') {
        message =
            'Table "wholesale_users" or "wholesale_transaction" does not exist. Please verify the Supabase schema.';
      } else if (e.code == '42501') {
        message =
            'Permission denied for table(s). Check RLS policies in Supabase.';
      } else {
        message = 'Error fetching collections: ${e.message} (Code: ${e.code})';
      }
      setState(() {
        transactionsByUser = {};
        amountTotalsByUser = {};
        totalAmount = 0.0;
        isLoading = false;
        errorMessage = message;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
      print(
          'PostgrestException in fetchCollections: $e, Details: ${e.details}');
    } catch (e) {
      setState(() {
        transactionsByUser = {};
        amountTotalsByUser = {};
        totalAmount = 0.0;
        isLoading = false;
        errorMessage = 'Unexpected error fetching collections: $e';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unexpected error fetching collections: $e')),
      );
      print('Unexpected error in fetchCollections: $e');
    }
  }

  void setupRealtimeSubscription() {
    try {
      supabase
          .channel('vip_total_collections')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'wholesale_transaction',
            callback: (payload) {
              fetchCollections();
            },
          )
          .subscribe((status, [error]) {
        if (error != null) {
          print('Subscription error: $error');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Realtime subscription failed: $error')),
          );
        }
      });
    } catch (e) {
      print('Error setting up realtime subscription: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to set up realtime updates: $e')),
      );
    }
  }

  @override
  void dispose() {
    supabase.channel('vip_total_collections').unsubscribe();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: const Color(0xFF1A0841),
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'Total Collection',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              titlePadding: const EdgeInsets.only(left: 72, bottom: 16),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          SliverToBoxAdapter(
            child: RefreshIndicator(
              onRefresh: fetchCollections,
              color: Colors.white,
              backgroundColor: const Color(0xFF3B322C),
              child: Container(
                constraints: BoxConstraints(
                  minHeight: MediaQuery.of(context).size.height -
                      kToolbarHeight -
                      MediaQuery.of(context).padding.top,
                ),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF1A0841), Color(0xFF3B322C)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFF5F5F5), Colors.white],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Today\'s Collection',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1A0841),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Date: ${DateFormat('d MMMM yyyy').format(DateTime.now())}',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[700],
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.attach_money,
                                          color: Color(0xFF4CAF50), size: 20),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Total: ₹${totalAmount.toStringAsFixed(0)}',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF4CAF50),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Customer Breakdown',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              shadows: [
                                Shadow(
                                  blurRadius: 4,
                                  color: Colors.black26,
                                  offset: Offset(2, 2),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          isLoading
                              ? const Center(
                                  child: SizedBox(
                                    height: 60,
                                    width: 60,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 6,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.white),
                                    ),
                                  ),
                                )
                              : errorMessage != null
                                  ? Center(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            errorMessage!,
                                            style: const TextStyle(
                                              color: Colors.redAccent,
                                              fontSize: 16,
                                              fontWeight: FontWeight.w500,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                          const SizedBox(height: 16),
                                          ElevatedButton(
                                            onPressed: fetchCollections,
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  const Color(0xFF2196F3),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                            ),
                                            child: const Text(
                                              'Retry',
                                              style: TextStyle(
                                                  color: Colors.white),
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  : transactionsByUser.isEmpty
                                      ? Card(
                                          elevation: 4,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.all(24),
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(
                                                  Icons.info_outline,
                                                  color: Color(0xFF3B322C),
                                                  size: 64,
                                                ),
                                                const SizedBox(height: 16),
                                                Text(
                                                  'No transactions found for today.',
                                                  textAlign: TextAlign.center,
                                                  style: TextStyle(
                                                    color: Colors.grey[700],
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                                const SizedBox(height: 8),
                                                Text(
                                                  'Check back later.',
                                                  textAlign: TextAlign.center,
                                                  style: TextStyle(
                                                    color: Colors.grey[600],
                                                    fontSize: 14,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        )
                                      : ListView.separated(
                                          shrinkWrap: true,
                                          physics:
                                              const NeverScrollableScrollPhysics(),
                                          itemCount: transactionsByUser.length,
                                          separatorBuilder: (_, __) =>
                                              const SizedBox(height: 12),
                                          itemBuilder: (context, index) {
                                            final userName = transactionsByUser
                                                .keys
                                                .toList()[index];
                                            final amountTotal =
                                                amountTotalsByUser[userName]!;
                                            final initials = userName
                                                .split(' ')
                                                .map((e) =>
                                                    e.isNotEmpty ? e[0] : '')
                                                .take(2)
                                                .join();

                                            return Card(
                                              elevation: 4,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: InkWell(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                onTap: () {
                                                  HapticFeedback
                                                      .selectionClick();
                                                  ScaffoldMessenger.of(context)
                                                      .showSnackBar(
                                                    SnackBar(
                                                      content: Text(
                                                          'View details for $userName (Coming soon)'),
                                                    ),
                                                  );
                                                },
                                                child: Padding(
                                                  padding:
                                                      const EdgeInsets.all(16),
                                                  child: Row(
                                                    children: [
                                                      CircleAvatar(
                                                        radius: 24,
                                                        backgroundColor:
                                                            const Color(
                                                                0xFF2196F3),
                                                        child: Text(
                                                          initials,
                                                          style:
                                                              const TextStyle(
                                                            color: Colors.white,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            fontSize: 16,
                                                          ),
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
                                                                fontSize: 16,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                color: Color(
                                                                    0xFF1A0841),
                                                              ),
                                                            ),
                                                            const SizedBox(
                                                                height: 4),
                                                            Text(
                                                              'Total Paid: ₹${amountTotal.toStringAsFixed(2)}',
                                                              style:
                                                                  const TextStyle(
                                                                fontSize: 14,
                                                                color: Color(
                                                                    0xFF4CAF50),
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w500,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: fetchCollections,
        backgroundColor: const Color(0xFF2196F3),
        child: const Icon(Icons.refresh, color: Colors.white),
        tooltip: 'Refresh Collections',
      ),
    );
  }
}
