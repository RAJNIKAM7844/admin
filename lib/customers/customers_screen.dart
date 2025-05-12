import 'package:admin_eggs/customers/customer_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> customers = [];
  List<Map<String, dynamic>> filteredCustomers = [];
  TextEditingController searchController = TextEditingController();
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    print('Initializing CustomersScreen');
    fetchCustomers();
  }

  Future<void> fetchCustomers() async {
    setState(() => isLoading = true);
    try {
      print('Fetching customers from users table');
      final userResponse = await supabase
          .from('users')
          .select('id, full_name, location, phone, profile_image, shop_image')
          .eq('role', 'customer')
          .order('full_name');

      print('User response: $userResponse');

      List<Map<String, dynamic>> customerList = [];
      for (var user in userResponse) {
        final userId = user['id'].toString();
        double creditBalance = 0.0;

        print('Fetching transactions for userId: $userId');
        final transactionsResponse = await supabase
            .from('transactions')
            .select('credit, paid')
            .eq('user_id', userId);

        print('Transactions for userId $userId: $transactionsResponse');

        creditBalance = transactionsResponse.fold(0.0,
                (sum, t) => sum + (t['credit'] as num? ?? 0.0).toDouble()) -
            transactionsResponse.fold(
                0.0, (sum, t) => sum + (t['paid'] as num? ?? 0.0).toDouble());

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
      print('Fetched ${customers.length} customers');
    } catch (e) {
      print('Error fetching customers: $e');
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
    print('Filtered customers: ${filteredCustomers.length} for query: $query');
  }

  Widget buildCustomerItem(Map<String, dynamic> customer) {
    final imageUrl = customer['profile_image'] ?? '';
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AnimatedScale(
        scale: 1.0,
        duration: const Duration(milliseconds: 200),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            splashColor: Colors.white.withOpacity(0.3),
            onTap: () {
              print(
                  'Navigating to CustomerDetailScreen for userId: ${customer['id']}');
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CustomerDetailScreen(
                    name: customer['full_name'] ?? 'Unknown',
                    number: customer['phone'] ?? 'N/A',
                    area: customer['location'] ?? '-',
                    profileImageUrl: imageUrl,
                    shopImageUrl: customer['shop_image'] ?? '',
                    userId: customer['id'].toString(), // Pass correct userId
                  ),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.2)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 24,
                      backgroundColor: Colors.grey.shade200,
                      backgroundImage:
                          imageUrl.isNotEmpty ? NetworkImage(imageUrl) : null,
                      child: imageUrl.isEmpty
                          ? Icon(Icons.person, color: Colors.black54, size: 24)
                          : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          customer['full_name'] ?? 'Unknown',
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
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Credit Balance: ₹${(customer['credit_balance'] as double).toStringAsFixed(2)}',
                          style: GoogleFonts.roboto(
                            color: customer['credit_balance'] >= 0
                                ? Colors.redAccent
                                : Colors.green,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.white.withOpacity(0.7),
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
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
                    Text(
                      'Customer Details',
                      style: GoogleFonts.roboto(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
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

              // Customer List
              Expanded(
                child: isLoading
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                  Colors.white),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Loading Customers...',
                              style: GoogleFonts.roboto(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      )
                    : filteredCustomers.isEmpty
                        ? Center(
                            child: Text(
                              'No customers found.',
                              style: GoogleFonts.roboto(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            itemCount: filteredCustomers.length,
                            itemBuilder: (context, index) {
                              return buildCustomerItem(
                                  filteredCustomers[index]);
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
