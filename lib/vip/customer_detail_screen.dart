import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class VipCustomerDetailScreen extends StatefulWidget {
  final String name;
  final String number;
  final String area;
  final String profileImageUrl;
  final String shopImageUrl;
  final String userId; // UUID string for filtering transactions

  const VipCustomerDetailScreen({
    super.key,
    required this.name,
    required this.number,
    required this.area,
    required this.profileImageUrl,
    required this.shopImageUrl,
    required this.userId,
  });

  @override
  State<VipCustomerDetailScreen> createState() =>
      _VipCustomerDetailScreenState();
}

class _VipCustomerDetailScreenState extends State<VipCustomerDetailScreen> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> transactions = [];
  bool isLoading = false;
  String? errorMessage;
  double creditBalance = 0.0;
  double eggRate = 10.0; // Default, updated via _fetchEggRate

  @override
  void initState() {
    super.initState();
    _fetchEggRate();
    _loadTransactions();
    _setupRealtimeSubscription();
  }

  Future<void> _fetchEggRate() async {
    try {
      final response = await supabase
          .from('wholesale_eggrate')
          .select('rate')
          .order('updated_at', ascending: false)
          .limit(1)
          .maybeSingle();
      if (response != null) {
        setState(() {
          eggRate = (response['rate'] as num?)?.toDouble() ?? 10.0;
        });
      }
    } catch (e) {
      print('Error fetching egg rate: $e');
    }
  }

  Future<void> _loadTransactions() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });
    try {
      final transactionsResponse = await supabase
          .from('wholesale_transaction')
          .select('id, user_id, date, credit, paid, balance, mode_of_payment')
          .eq('user_id', widget.userId)
          .order('date', ascending: false);

      setState(() {
        transactions = transactionsResponse.map((t) {
          final parsedDate = DateTime.parse(t['date']);
          return {
            'date': parsedDate,
            'credit': (t['credit'] as num?)?.toDouble() ?? 0.0,
            'paid': (t['paid'] as num?)?.toDouble() ?? 0.0,
            'balance': (t['balance'] as num?)?.toDouble() ?? 0.0,
            'mode_of_payment': t['mode_of_payment']?.toString() ?? 'None',
            'trays':
                ((t['credit'] as num?)?.toDouble() ?? 0.0) / (eggRate * 30),
          };
        }).toList();

        creditBalance = transactions.fold(0.0, (sum, t) => sum + t['credit']) -
            transactions.fold(0.0, (sum, t) => sum + t['paid']);
        isLoading = false;
      });
    } on PostgrestException catch (e) {
      String message;
      if (e.code == '42P01') {
        message =
            'Table "wholesale_transaction" does not exist. Verify schema.';
      } else if (e.code == '42501') {
        message = 'Permission denied for "wholesale_transaction". Check RLS.';
      } else {
        message = 'Error fetching transactions: ${e.message} (Code: ${e.code})';
      }
      setState(() {
        errorMessage = message;
        transactions = [];
        creditBalance = 0.0;
        isLoading = false;
      });
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
      print(
          'PostgrestException in _loadTransactions: $e, Details: ${e.details}');
    } catch (e) {
      setState(() {
        errorMessage = 'Unexpected error fetching transactions: $e';
        transactions = [];
        creditBalance = 0.0;
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Unexpected error fetching transactions: $e')));
      print('Unexpected error in _loadTransactions: $e');
    }
  }

  void _setupRealtimeSubscription() {
    try {
      supabase
          .channel('vip_customer_transactions_${widget.userId}')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'wholesale_transaction',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'user_id',
              value: widget.userId,
            ),
            callback: (payload) {
              print(
                  'Real-time transaction update for user_id: ${widget.userId}');
              _loadTransactions();
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

  void _showImageDialog(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: InteractiveViewer(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.network(imageUrl, fit: BoxFit.contain),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    supabase
        .channel('vip_customer_transactions_${widget.userId}')
        .unsubscribe();
    super.dispose();
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
          child: RefreshIndicator(
            onRefresh: _loadTransactions,
            color: Colors.white,
            backgroundColor: const Color(0xFF3B322C),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'VIP Customer Details',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildImageAvatar(widget.profileImageUrl, 'Profile'),
                        const SizedBox(width: 16),
                        _buildImageAvatar(widget.shopImageUrl, 'Shop'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  _infoCard(
                    icon: Icons.person_outline,
                    label: 'Name',
                    value: widget.name,
                  ),
                  const SizedBox(height: 16),
                  _infoCard(
                    icon: Icons.phone_outlined,
                    label: 'Phone',
                    value: widget.number,
                  ),
                  const SizedBox(height: 16),
                  _infoCard(
                    icon: Icons.location_on_outlined,
                    label: 'Area',
                    value: widget.area,
                  ),
                  const SizedBox(height: 32),
                  _buildBalanceCard(),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'VIP Transactions',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        '${transactions.length} transactions',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (isLoading)
                    const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  else if (errorMessage != null)
                    Center(
                      child: Column(
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
                            onPressed: _loadTransactions,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2196F3),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Retry',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    )
                  else if (transactions.isEmpty)
                    const Center(
                      child: Text(
                        'No transactions found.',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: transactions.length,
                      itemBuilder: (context, index) {
                        final transaction = transactions[index];
                        return _buildTransactionCard(transaction);
                      },
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImageAvatar(String imageUrl, String type) {
    return GestureDetector(
      onTap: () => _showImageDialog(context, imageUrl),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: CircleAvatar(
          radius: 50,
          backgroundImage: NetworkImage(imageUrl),
          backgroundColor: Colors.grey.shade200,
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: 100,
              padding: const EdgeInsets.symmetric(vertical: 4),
              color: Colors.black54,
              child: Text(
                type,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _infoCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white70, size: 24),
          const SizedBox(width: 12),
          Text(
            '$label:',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: Colors.white70,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Credit Balance:',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          Text(
            '₹${creditBalance.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: creditBalance > 0 ? Colors.red : Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionCard(Map<String, dynamic> transaction) {
    final trays = (transaction['trays'] as num).round();
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Text(
          'Date: ${DateFormat('MMM dd, yyyy').format(transaction['date'])}',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: Colors.black87,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Trays: $trays',
                style: const TextStyle(
                  color: Color(0xFF4CAF50),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'Credit: ₹${transaction['credit'].toStringAsFixed(2)}',
                style: const TextStyle(color: Colors.red, fontSize: 14),
              ),
              Text(
                'Paid: ₹${transaction['paid'].toStringAsFixed(2)}',
                style: const TextStyle(color: Colors.green, fontSize: 14),
              ),
              Text(
                'Balance: ₹${transaction['balance'].toStringAsFixed(2)}',
                style: TextStyle(
                  color: transaction['balance'] > 0 ? Colors.red : Colors.green,
                  fontSize: 14,
                ),
              ),
              Text(
                'Mode: ${transaction['mode_of_payment']}',
                style: const TextStyle(color: Colors.black54, fontSize: 14),
              ),
            ],
          ),
        ),
        trailing: const Icon(Icons.receipt, color: Colors.blueGrey),
      ),
    );
  }
}
