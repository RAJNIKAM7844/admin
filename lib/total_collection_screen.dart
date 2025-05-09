import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class TotalCollectionScreen extends StatefulWidget {
  const TotalCollectionScreen({super.key});

  @override
  State<TotalCollectionScreen> createState() => _TotalCollectionScreenState();
}

class _TotalCollectionScreenState extends State<TotalCollectionScreen> {
  final supabase = Supabase.instance.client;
  Map<String, List<Map<String, dynamic>>> transactionsByUser = {};
  Map<String, double> creditTotalsByUser = {};
  Map<String, double> paidTotalsByUser = {};
  double totalCredit = 0.0;
  double totalPaid = 0.0;
  bool isLoading = false;
  List<Map<String, dynamic>> drivers = [];
  String? selectedDriverId;

  @override
  void initState() {
    super.initState();
    fetchDrivers();
    fetchCollections();
    setupRealtimeSubscription();
  }

  Future<void> fetchDrivers() async {
    try {
      final response = await supabase
          .from('drivers')
          .select('id, driver_name')
          .order('driver_name', ascending: true);

      setState(() {
        drivers = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error fetching drivers: $e',
              style: GoogleFonts.roboto(color: Colors.white)),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> fetchCollections() async {
    setState(() {
      isLoading = true;
    });
    try {
      final usersResponse =
          await supabase.from('users').select('id, full_name');
      final users = List<Map<String, dynamic>>.from(usersResponse);
      final userIdToName = {
        for (var user in users) user['id'].toString(): user['full_name']
      };

      final today = DateTime.now();
      final startDate = DateTime(today.year, today.month, today.day);
      final endDate = DateTime(today.year, today.month, today.day, 23, 59, 59);

      var query = supabase
          .from('transactions')
          .select('user_id, credit, paid, date, mode_of_payment, driver_id')
          .gte('date', startDate.toIso8601String())
          .lte('date', endDate.toIso8601String());

      if (selectedDriverId != null && selectedDriverId != 'all') {
        query = query.eq('driver_id', int.parse(selectedDriverId!));
      }

      final transactionsResponse = await query;

      Map<String, List<Map<String, dynamic>>> tempTransactionsByUser = {};
      Map<String, double> tempCreditTotalsByUser = {};
      Map<String, double> tempPaidTotalsByUser = {};
      double tempTotalCredit = 0.0;
      double tempTotalPaid = 0.0;

      for (var transaction in transactionsResponse) {
        final userId = transaction['user_id'].toString();
        final credit = (transaction['credit'] as num?)?.toDouble() ?? 0.0;
        final paid = (transaction['paid'] as num?)?.toDouble() ?? 0.0;
        final modeOfPayment =
            transaction['mode_of_payment']?.toString() ?? 'N/A';

        final userName = userIdToName[userId] ?? 'Customer $userId';

        tempTransactionsByUser[userName] ??= [];
        tempCreditTotalsByUser[userName] ??= 0.0;
        tempPaidTotalsByUser[userName] ??= 0.0;

        tempTransactionsByUser[userName]!.add({
          'credit': credit,
          'paid': paid,
          'mode_of_payment': modeOfPayment,
        });

        tempCreditTotalsByUser[userName] =
            tempCreditTotalsByUser[userName]! + credit;
        tempPaidTotalsByUser[userName] = tempPaidTotalsByUser[userName]! + paid;
        tempTotalCredit += credit;
        tempTotalPaid += paid;
      }

      setState(() {
        transactionsByUser = tempTransactionsByUser;
        creditTotalsByUser = tempCreditTotalsByUser;
        paidTotalsByUser = tempPaidTotalsByUser;
        totalCredit = tempTotalCredit;
        totalPaid = tempTotalPaid;
        isLoading = false;
      });
    } catch (e, stackTrace) {
      print('Error fetching collections: $e');
      print('Stack trace: $stackTrace');
      setState(() {
        transactionsByUser = {};
        creditTotalsByUser = {};
        paidTotalsByUser = {};
        totalCredit = 0.0;
        totalPaid = 0.0;
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load collections: $e',
              style: GoogleFonts.roboto(color: Colors.white)),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void setupRealtimeSubscription() {
    supabase
        .channel('total_collections')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'transactions',
          filter: selectedDriverId != null && selectedDriverId != 'all'
              ? PostgresChangeFilter(
                  type: PostgresChangeFilterType.eq,
                  column: 'driver_id',
                  value: int.parse(selectedDriverId!),
                )
              : null,
          callback: (payload) {
            fetchCollections();
          },
        )
        .subscribe();
  }

  @override
  void dispose() {
    supabase.channel('total_collections').unsubscribe();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0D0221), Color(0xFF2A1B3D)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              backgroundColor: Colors.transparent,
              flexibleSpace: FlexibleSpaceBar(
                title: Text(
                  'Total Collection',
                  style: GoogleFonts.roboto(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
                titlePadding: const EdgeInsets.only(left: 72, bottom: 16),
              ),
              leading: IconButton(
                icon:
                    const Icon(Icons.arrow_back, color: Colors.white, size: 24),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            SliverToBoxAdapter(
              child: RefreshIndicator(
                onRefresh: fetchCollections,
                color: Colors.white,
                backgroundColor: Colors.black.withOpacity(0.5),
                child: Container(
                  constraints: BoxConstraints(
                    minHeight: MediaQuery.of(context).size.height -
                        kToolbarHeight -
                        MediaQuery.of(context).padding.top,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Card(
                          elevation: 0,
                          color: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                                color: Colors.white.withOpacity(0.2)),
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: DropdownButtonFormField<String>(
                              value: selectedDriverId,
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                labelText: 'Filter by Driver',
                                labelStyle: GoogleFonts.roboto(
                                    color: Colors.white.withOpacity(0.7),
                                    fontSize: 15,
                                    fontWeight: FontWeight.w400),
                                prefixIcon: Icon(Icons.filter_list,
                                    color: Colors.white.withOpacity(0.7),
                                    size: 20),
                              ),
                              style: GoogleFonts.roboto(
                                  color: Colors.white, fontSize: 15),
                              dropdownColor: Colors.black.withOpacity(0.9),
                              items: [
                                DropdownMenuItem<String>(
                                  value: 'all',
                                  child: Text('All Drivers',
                                      style: GoogleFonts.roboto(
                                          color: Colors.white, fontSize: 15)),
                                ),
                                ...drivers.map((driver) {
                                  return DropdownMenuItem<String>(
                                    value: driver['id'].toString(),
                                    child: Text(
                                        driver['driver_name'] ?? 'Unknown',
                                        style: GoogleFonts.roboto(
                                            color: Colors.white, fontSize: 15)),
                                  );
                                }).toList(),
                              ],
                              onChanged: (value) {
                                HapticFeedback.lightImpact();
                                setState(() {
                                  selectedDriverId = value;
                                });
                                fetchCollections();
                                supabase
                                    .channel('total_collections')
                                    .unsubscribe();
                                setupRealtimeSubscription();
                              },
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Card(
                          elevation: 0,
                          color: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                                color: Colors.white.withOpacity(0.2)),
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  selectedDriverId == null ||
                                          selectedDriverId == 'all'
                                      ? 'Today\'s Total Collection'
                                      : 'Collection for ${drivers.firstWhere((d) => d['id'].toString() == selectedDriverId, orElse: () => {
                                            'driver_name': 'Unknown'
                                          })['driver_name']}',
                                  style: GoogleFonts.roboto(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Date: ${DateFormat('d MMMM yyyy').format(DateTime.now())}',
                                  style: GoogleFonts.roboto(
                                    fontSize: 14,
                                    color: Colors.white.withOpacity(0.7),
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(Icons.credit_card,
                                            color: Colors.green, size: 20),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Credit: ₹${totalCredit.toStringAsFixed(0)}',
                                          style: GoogleFonts.roboto(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.green,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        const Icon(Icons.check_circle,
                                            color: Colors.white, size: 20),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Paid: ₹${totalPaid.toStringAsFixed(0)}',
                                          style: GoogleFonts.roboto(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
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
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Customer Breakdown',
                              style: GoogleFonts.roboto(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 12),
                            isLoading
                                ? Center(
                                    child: Column(
                                      children: [
                                        const CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 4,
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          'Loading transactions...',
                                          style: GoogleFonts.roboto(
                                            color:
                                                Colors.white.withOpacity(0.7),
                                            fontSize: 15,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : transactionsByUser.isEmpty
                                    ? Card(
                                        elevation: 0,
                                        color: Colors.transparent,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          side: BorderSide(
                                              color: Colors.white
                                                  .withOpacity(0.2)),
                                        ),
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color:
                                                Colors.white.withOpacity(0.1),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black
                                                    .withOpacity(0.2),
                                                blurRadius: 6,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          padding: const EdgeInsets.all(16),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.info_outline,
                                                color: Colors.white
                                                    .withOpacity(0.7),
                                                size: 40,
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                'No transactions found for today.',
                                                textAlign: TextAlign.center,
                                                style: GoogleFonts.roboto(
                                                  color: Colors.white
                                                      .withOpacity(0.7),
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                'Try selecting another driver or check back later.',
                                                textAlign: TextAlign.center,
                                                style: GoogleFonts.roboto(
                                                  color: Colors.white
                                                      .withOpacity(0.7),
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w400,
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
                                          final creditTotal =
                                              creditTotalsByUser[userName]!;
                                          final paidTotal =
                                              paidTotalsByUser[userName]!;
                                          final initials = userName
                                              .split(' ')
                                              .map((e) =>
                                                  e.isNotEmpty ? e[0] : '')
                                              .take(2)
                                              .join();

                                          return Card(
                                            elevation: 0,
                                            color: Colors.transparent,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              side: BorderSide(
                                                  color: Colors.white
                                                      .withOpacity(0.2)),
                                            ),
                                            child: InkWell(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              splashColor:
                                                  Colors.white.withOpacity(0.3),
                                              onTap: () {
                                                HapticFeedback.selectionClick();
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                        'View details for $userName (Coming soon)',
                                                        style:
                                                            GoogleFonts.roboto(
                                                                color: Colors
                                                                    .white)),
                                                    backgroundColor: Colors.red,
                                                  ),
                                                );
                                              },
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  color: Colors.white
                                                      .withOpacity(0.1),
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Colors.black
                                                          .withOpacity(0.2),
                                                      blurRadius: 6,
                                                      offset:
                                                          const Offset(0, 2),
                                                    ),
                                                  ],
                                                ),
                                                padding:
                                                    const EdgeInsets.all(12),
                                                child: Row(
                                                  children: [
                                                    CircleAvatar(
                                                      radius: 22,
                                                      backgroundColor:
                                                          Colors.grey.shade200,
                                                      child: Text(
                                                        initials,
                                                        style:
                                                            GoogleFonts.roboto(
                                                          color: Colors.black54,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          fontSize: 16,
                                                        ),
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
                                                            style: GoogleFonts
                                                                .roboto(
                                                              fontSize: 16,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                              color:
                                                                  Colors.white,
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                              height: 4),
                                                          Text(
                                                            'Credit: ₹${creditTotal.toStringAsFixed(2)}',
                                                            style: GoogleFonts
                                                                .roboto(
                                                              fontSize: 14,
                                                              color:
                                                                  Colors.green,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w500,
                                                            ),
                                                          ),
                                                          Text(
                                                            'Paid: ₹${paidTotal.toStringAsFixed(2)}',
                                                            style: GoogleFonts
                                                                .roboto(
                                                              fontSize: 14,
                                                              color:
                                                                  Colors.white,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w500,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    Icon(
                                                        Icons.arrow_forward_ios,
                                                        size: 16,
                                                        color: Colors.white
                                                            .withOpacity(0.7)),
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
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: fetchCollections,
        backgroundColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.white.withOpacity(0.2)),
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFE91E63), Color(0xFF4CAF50)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.refresh, color: Colors.white, size: 24),
        ),
        tooltip: 'Refresh Collections',
      ),
    );
  }
}
