import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class CustomerDetailScreen extends StatefulWidget {
  final String name;
  final String number;
  final String area;
  final String profileImageUrl;
  final String shopImageUrl;
  final int? driverId;
  final String userId; // Made userId required
  final String schema;

  const CustomerDetailScreen({
    super.key,
    required this.name,
    required this.number,
    required this.area,
    required this.profileImageUrl,
    required this.shopImageUrl,
    required this.userId,
    this.driverId,
    this.schema = 'public',
  });

  @override
  State<CustomerDetailScreen> createState() => _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends State<CustomerDetailScreen> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> transactions = [];
  bool isLoading = false;
  double creditBalance = 0.0;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
    _setupRealtimeSubscription();
  }

  Future<void> _loadTransactions() async {
    setState(() => isLoading = true);
    try {
      final userId = widget.userId;
      final transactionTable = widget.schema == 'public'
          ? 'transactions'
          : 'wholesale_users.wholesale_transactions';
      final query = supabase.from(transactionTable).select(
          widget.schema == 'public'
              ? 'credit, paid, date, mode_of_payment, drivers!left(driver_name)'
              : 'amount, created_at');

      final transactionsResponse = await query
          .eq(widget.schema == 'public' ? 'user_id' : 'wholesale_user_id',
              userId)
          // Uncomment below to filter by driver_id if driver-specific transactions are needed
          // .eq('driver_id', widget.driverId!)
          .order(widget.schema == 'public' ? 'date' : 'created_at',
              ascending: false);

      setState(() {
        transactions = transactionsResponse.map((t) {
          String dateStr = widget.schema == 'public'
              ? (t['date']?.toString() ?? DateTime.now().toIso8601String())
              : (t['created_at']?.toString() ??
                  DateTime.now().toIso8601String());
          DateTime parsedDate;
          try {
            parsedDate = DateTime.parse(dateStr);
          } catch (e) {
            try {
              parsedDate = DateFormat('MMM dd').parse(dateStr);
              parsedDate = DateTime(
                  DateTime.now().year, parsedDate.month, parsedDate.day);
            } catch (e) {
              print('Error parsing date $dateStr: $e');
              parsedDate = DateTime.now();
            }
          }
          if (widget.schema == 'public') {
            return {
              'date': parsedDate,
              'credit': (t['credit'] as num?)?.toDouble() ?? 0.0,
              'paid': (t['paid'] as num?)?.toDouble() ?? 0.0,
              'mode_of_payment': t['mode_of_payment']?.toString() ?? 'N/A',
              'driver_name':
                  t['drivers']?['driver_name']?.toString() ?? 'Paid by User',
            };
          } else {
            return {
              'date': parsedDate,
              'amount': (t['amount'] as num?)?.toDouble() ?? 0.0,
              'mode_of_payment': 'N/A',
              'driver_name': 'N/A',
            };
          }
        }).toList();

        if (widget.schema == 'public') {
          creditBalance =
              transactions.fold(0.0, (sum, t) => sum + t['credit']) -
                  transactions.fold(0.0, (sum, t) => sum + t['paid']);
        } else {
          creditBalance = transactions.fold(0.0, (sum, t) => sum + t['amount']);
        }
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching transactions: $e');
      setState(() {
        transactions = [];
        creditBalance = 0.0;
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load transactions: $e')),
      );
    }
  }

  void _setupRealtimeSubscription() {
    final transactionTable =
        widget.schema == 'public' ? 'transactions' : 'wholesale_transactions';
    final channelName =
        'customer_transactions_${widget.userId}_${widget.schema}';
    supabase
        .channel(channelName)
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: widget.schema,
          table: transactionTable,
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: widget.schema == 'public' ? 'user_id' : 'wholesale_user_id',
            value: widget.userId,
          ),
          callback: (payload) {
            print('Real-time transaction update for customer: $payload');
            _loadTransactions();
          },
        )
        .subscribe();
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
        .channel('customer_transactions_${widget.userId}_${widget.schema}')
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
                    Text(
                      widget.schema == 'public'
                          ? 'Customer Details'
                          : 'VIP Customer Details',
                      style: const TextStyle(
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
                Text(
                  widget.schema == 'public' && widget.driverId != null
                      ? 'Driver-Specific Transactions'
                      : widget.schema == 'public'
                          ? 'All Transactions'
                          : 'VIP Transactions',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                if (isLoading)
                  const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
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
          Text(
            widget.schema == 'public' ? 'Credit Balance:' : 'Total Collection:',
            style: const TextStyle(
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
              color: creditBalance >= 0 ? Colors.red : Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionCard(Map<String, dynamic> transaction) {
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
                'Source: ${transaction['driver_name']}',
                style: const TextStyle(color: Colors.black54, fontSize: 14),
              ),
              const SizedBox(height: 4),
              if (widget.schema == 'public') ...[
                Text(
                  'Credit: ₹${transaction['credit'].toStringAsFixed(2)}',
                  style: const TextStyle(color: Colors.red, fontSize: 14),
                ),
                Text(
                  'Paid: ₹${transaction['paid'].toStringAsFixed(2)}',
                  style: const TextStyle(color: Colors.green, fontSize: 14),
                ),
              ] else
                Text(
                  'Amount: ₹${transaction['amount'].toStringAsFixed(2)}',
                  style: const TextStyle(color: Colors.red, fontSize: 14),
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
