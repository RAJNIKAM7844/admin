import 'package:admin_eggs/customers/customer_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DriverCustomersScreen extends StatefulWidget {
  final int driverId;
  final String areaName;
  final String driverName;

  const DriverCustomersScreen({
    super.key,
    required this.driverId,
    required this.areaName,
    required this.driverName,
  });

  @override
  State<DriverCustomersScreen> createState() => _DriverCustomersScreenState();
}

class _DriverCustomersScreenState extends State<DriverCustomersScreen> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> customers = [];
  List<Map<String, dynamic>> filteredCustomers = [];
  TextEditingController searchController = TextEditingController();
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    fetchCustomers();
  }

  Future<void> fetchCustomers() async {
    setState(() {
      isLoading = true;
    });
    try {
      print('Fetching customers for area: ${widget.areaName}');
      // Fetch customer data with role = 'customer'
      final response = await supabase
          .from('users')
          .select('id, full_name, location, phone, profile_image, shop_image')
          .eq('location', widget.areaName)
          .eq('role', 'customer') // Added role filter
          .order('full_name');

      // Fetch transactions and calculate credit balance for each customer
      List<Map<String, dynamic>> customerList = [];
      for (var user in response) {
        final userId = user['id'].toString();
        double creditBalance = 0.0;

        // Fetch transactions for the user and driver
        final transactionsResponse = await supabase
            .from('transactions')
            .select('credit, paid')
            .eq('user_id', userId)
            .eq('driver_id', widget.driverId);

        // Calculate credit balance: sum(credit) - sum(paid)
        creditBalance = transactionsResponse.fold(0.0,
                (sum, t) => sum + (t['credit'] as num? ?? 0.0).toDouble()) -
            transactionsResponse.fold(
                0.0, (sum, t) => sum + (t['paid'] as num? ?? 0.0).toDouble());

        // Add credit balance to customer data
        customerList.add({
          ...user,
          'credit_balance': creditBalance,
        });
      }

      setState(() {
        customers = customerList;
        filteredCustomers = customerList;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        customers = [];
        filteredCustomers = [];
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching customers: $e')),
      );
    }
  }

  void filterCustomers(String query) {
    final lowerQuery = query.toLowerCase();
    setState(() {
      filteredCustomers = customers.where((user) {
        final name = user['full_name']?.toLowerCase() ?? '';
        final area = user['location']?.toLowerCase() ?? '';
        return name.contains(lowerQuery) || area.contains(lowerQuery);
      }).toList();
    });
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
              Padding(
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
                        '${widget.driverName} - ${widget.areaName}',
                        style: GoogleFonts.roboto(
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
              // Search Bar
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.2)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: searchController,
                    onChanged: filterCustomers,
                    style:
                        GoogleFonts.roboto(color: Colors.white, fontSize: 15),
                    decoration: InputDecoration(
                      hintText: 'Search by name or location',
                      hintStyle: GoogleFonts.roboto(
                          color: Colors.white.withOpacity(0.5)),
                      border: InputBorder.none,
                      prefixIcon: Icon(Icons.search,
                          color: Colors.white.withOpacity(0.7)),
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 16),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Customer List
              Expanded(
                child: isLoading
                    ? Center(
                        child: CircularProgressIndicator(
                          valueColor:
                              const AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : filteredCustomers.isEmpty
                        ? Center(
                            child: Text(
                              widget.areaName == 'No area assigned'
                                  ? 'No area assigned to this driver.'
                                  : 'No customers found in this area.',
                              style: GoogleFonts.roboto(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: filteredCustomers.length,
                            itemBuilder: (context, index) {
                              final customer = filteredCustomers[index];
                              final imageUrl = customer['profile_image'] ?? '';
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(12),
                                    splashColor: Colors.white.withOpacity(0.3),
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => CustomerDetailScreen(
                                            name: customer['full_name'] ??
                                                'Unknown',
                                            number: customer['phone'] ?? 'N/A',
                                            area: customer['location'] ?? '-',
                                            profileImageUrl: imageUrl,
                                            shopImageUrl:
                                                customer['shop_image'] ?? '',
                                            driverId: widget.driverId,
                                            userId: customer['id'].toString(),
                                          ),
                                        ),
                                      );
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                            color:
                                                Colors.white.withOpacity(0.2)),
                                        boxShadow: [
                                          BoxShadow(
                                            color:
                                                Colors.black.withOpacity(0.2),
                                            blurRadius: 6,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                  color: Colors.white,
                                                  width: 1.5),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black
                                                      .withOpacity(0.3),
                                                  blurRadius: 6,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ],
                                            ),
                                            child: CircleAvatar(
                                              radius: 22,
                                              backgroundColor:
                                                  Colors.grey.shade200,
                                              backgroundImage:
                                                  imageUrl.isNotEmpty
                                                      ? NetworkImage(imageUrl)
                                                      : null,
                                              child: imageUrl.isEmpty
                                                  ? const Icon(Icons.person,
                                                      color: Colors.black54,
                                                      size: 22)
                                                  : null,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  customer['full_name'] ??
                                                      'Unknown',
                                                  style: GoogleFonts.roboto(
                                                    color: Colors.white,
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                                const SizedBox(height: 6),
                                                Text(
                                                  customer['location'] ?? '-',
                                                  style: GoogleFonts.roboto(
                                                    color: Colors.white
                                                        .withOpacity(0.7),
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w400,
                                                  ),
                                                ),
                                                const SizedBox(height: 6),
                                                Text(
                                                  'Credit Balance: ₹${(customer['credit_balance'] as double).toStringAsFixed(2)}',
                                                  style: GoogleFonts.roboto(
                                                    color: Colors.redAccent,
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Icon(
                                            Icons.arrow_forward_ios,
                                            color:
                                                Colors.white.withOpacity(0.7),
                                            size: 16,
                                          ),
                                        ],
                                      ),
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
