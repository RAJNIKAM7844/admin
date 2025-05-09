import 'package:admin_eggs/customers/customer_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class VipCustomersScreen extends StatefulWidget {
  const VipCustomersScreen({super.key});

  @override
  State<VipCustomersScreen> createState() => _VipCustomersScreenState();
}

class _VipCustomersScreenState extends State<VipCustomersScreen> {
  final supabase = Supabase.instance.client;
  List<dynamic> customers = [];
  List<dynamic> filteredCustomers = [];
  TextEditingController searchController = TextEditingController();
  bool isLoading = false;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    fetchCustomers();
  }

  Future<void> fetchCustomers() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });
    try {
      print('Fetching customers from wholesale_users');
      final response = await supabase
          .from('wholesale_users')
          .select('id, full_name, location, phone, profile_image, shop_image')
          .order('full_name');
      print('Fetch successful: ${response.length} customers retrieved');
      setState(() {
        customers = response;
        filteredCustomers = response;
        isLoading = false;
      });
    } on PostgrestException catch (e) {
      String message;
      if (e.code == '42P01') {
        message =
            'Table "wholesale_users" does not exist. Ensure the table is set up in Supabase.';
      } else if (e.code == '42501') {
        message =
            'Permission denied for table "wholesale_users". Verify RLS policies.';
      } else {
        message = 'Error fetching customers: ${e.message} (Code: ${e.code})';
      }
      setState(() {
        customers = [];
        filteredCustomers = [];
        isLoading = false;
        errorMessage = message;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
      print('PostgrestException in fetchCustomers: $e, Details: ${e.details}');
    } catch (e) {
      setState(() {
        customers = [];
        filteredCustomers = [];
        isLoading = false;
        errorMessage = 'Unexpected error fetching customers: $e';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unexpected error fetching customers: $e')),
      );
      print('Unexpected error in fetchCustomers: $e');
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

  Widget buildCustomerItem(dynamic customer) {
    final imageUrl = customer['profile_image'] ?? '';
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AnimatedScale(
        scale: 1.0,
        duration: const Duration(milliseconds: 200),
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
                    name: customer['full_name'] ?? 'Unknown',
                    number: customer['phone'] ?? 'N/A',
                    area: customer['location'] ?? '-',
                    profileImageUrl: imageUrl,
                    shopImageUrl: customer['shop_image'] ?? '',
                    schema: 'public',
                  ),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(12),
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
                      radius: 22,
                      backgroundColor: Colors.grey.shade200,
                      backgroundImage:
                          imageUrl.isNotEmpty ? NetworkImage(imageUrl) : null,
                      child: imageUrl.isEmpty
                          ? Icon(Icons.person, color: Colors.black54, size: 22)
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
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          customer['location'] ?? '-',
                          style: GoogleFonts.roboto(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
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
                    style: GoogleFonts.roboto(
                        color: Colors.white, fontSize: 15, letterSpacing: 0.5),
                    decoration: InputDecoration(
                      hintText: 'Search by name or location',
                      hintStyle: GoogleFonts.roboto(
                          color: Colors.white.withOpacity(0.5), fontSize: 15),
                      border: InputBorder.none,
                      prefixIcon: Icon(Icons.search,
                          color: Colors.white.withOpacity(0.7)),
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 16),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: isLoading
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Loading Customers...',
                              style: GoogleFonts.roboto(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      )
                    : errorMessage != null
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  color: Colors.white.withOpacity(0.7),
                                  size: 40,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  errorMessage!,
                                  style: GoogleFonts.roboto(
                                    color: Colors.white.withOpacity(0.7),
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 12),
                                ElevatedButton(
                                  onPressed: fetchCustomers,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12, horizontal: 20),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      side: BorderSide(
                                          color: Colors.white.withOpacity(0.2)),
                                    ),
                                  ),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0xFFE91E63),
                                          Color(0xFF4CAF50)
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12, horizontal: 20),
                                    child: Text(
                                      'Retry',
                                      style: GoogleFonts.roboto(
                                        color: Colors.white,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : filteredCustomers.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.info_outline,
                                      color: Colors.white.withOpacity(0.7),
                                      size: 40,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'No customers found.',
                                      style: GoogleFonts.roboto(
                                        color: Colors.white.withOpacity(0.7),
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
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
