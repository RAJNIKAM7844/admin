import 'package:admin_eggs/drivers/calender_selection_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DriverCollectionScreen extends StatefulWidget {
  const DriverCollectionScreen({super.key});

  @override
  State<DriverCollectionScreen> createState() => _DriverCollectionScreenState();
}

class _DriverCollectionScreenState extends State<DriverCollectionScreen> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> drivers = [];
  List<Map<String, dynamic>> filteredDrivers = [];
  TextEditingController searchController = TextEditingController();
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    fetchDrivers();
  }

  Future<void> fetchDrivers() async {
    setState(() => isLoading = true);
    try {
      final response = await supabase.from('drivers').select('''
            id, driver_name, vehicle_number, delivery_areas!left(area_name)
          ''').order('driver_name', ascending: true);

      setState(() {
        drivers = List<Map<String, dynamic>>.from(response);
        filteredDrivers = List<Map<String, dynamic>>.from(response);
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        drivers = [];
        filteredDrivers = [];
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching drivers: $e')),
      );
    }
  }

  void filterDrivers(String query) {
    final lowerQuery = query.toLowerCase();
    setState(() {
      filteredDrivers = drivers.where((driver) {
        final name = driver['driver_name']?.toLowerCase() ?? '';
        String area = '';
        final deliveryAreas = driver['delivery_areas'];
        if (deliveryAreas != null) {
          if (deliveryAreas is Map && deliveryAreas['area_name'] != null) {
            area = deliveryAreas['area_name'].toLowerCase();
          } else if (deliveryAreas is List &&
              deliveryAreas.isNotEmpty &&
              deliveryAreas[0]['area_name'] != null) {
            area = deliveryAreas[0]['area_name'].toLowerCase();
          }
        }
        return name.contains(lowerQuery) || area.contains(lowerQuery);
      }).toList();
    });
  }

  Widget buildDriverItem(Map<String, dynamic> driver) {
    final areaName = driver['delivery_areas'] is Map &&
            driver['delivery_areas']['area_name'] != null
        ? driver['delivery_areas']['area_name']
        : 'No area assigned';

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
                  builder: (_) => CalendarSelectionScreen(
                    driverId: driver['id'],
                    driverName: driver['driver_name'] ?? 'Unknown',
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
                      child:
                          Icon(Icons.person, color: Colors.black54, size: 22),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          driver['driver_name'] ?? 'Unknown',
                          style: GoogleFonts.roboto(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          areaName,
                          style: GoogleFonts.roboto(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 13,
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
                      'Driver Collections',
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
                    onChanged: filterDrivers,
                    style:
                        GoogleFonts.roboto(color: Colors.white, fontSize: 15),
                    decoration: InputDecoration(
                      hintText: 'Search by name or area',
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
              // Driver List
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
                              'Loading Drivers...',
                              style: GoogleFonts.roboto(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      )
                    : filteredDrivers.isEmpty
                        ? Center(
                            child: Text(
                              'No drivers found.',
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
                            itemCount: filteredDrivers.length,
                            itemBuilder: (context, index) {
                              return buildDriverItem(filteredDrivers[index]);
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
