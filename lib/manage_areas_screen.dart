import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ManageAreasScreen extends StatefulWidget {
  const ManageAreasScreen({Key? key}) : super(key: key);

  @override
  State<ManageAreasScreen> createState() => _ManageAreasScreenState();
}

class _ManageAreasScreenState extends State<ManageAreasScreen> {
  final supabase = Supabase.instance.client;

  List<Map<String, dynamic>> areas = [];
  List<Map<String, dynamic>> driversPerArea = [];
  bool isLoading = false;

  final TextEditingController areaNameController = TextEditingController();
  int? editingAreaId;

  @override
  void initState() {
    super.initState();
    fetchAreas();
  }

  Future<void> fetchAreas() async {
    setState(() {
      isLoading = true;
    });

    try {
      final areaResponse = await supabase
          .from('delivery_areas')
          .select('id, area_name')
          .order('area_name');

      if (areaResponse != null && areaResponse is List) {
        final List<Map<String, dynamic>> fetchedAreas =
            List<Map<String, dynamic>>.from(areaResponse);

        final List<Map<String, dynamic>> driversList = [];
        for (var area in fetchedAreas) {
          final driversResponse = await supabase
              .from('drivers')
              .select('id, driver_name, vehicle_number')
              .eq('area_id', area['id']);

          driversList.add({
            'area_id': area['id'],
            'drivers': driversResponse,
          });
        }

        setState(() {
          areas = fetchedAreas;
          driversPerArea = driversList;
          isLoading = false;
        });
      } else {
        setState(() {
          areas = [];
          driversPerArea = [];
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        areas = [];
        driversPerArea = [];
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error fetching areas: $e',
              style: GoogleFonts.roboto(color: Colors.white)),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> addArea(String areaName) async {
    try {
      await supabase.from('delivery_areas').insert({
        'area_name': areaName,
      });
      await fetchAreas();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to add area: $e',
              style: GoogleFonts.roboto(color: Colors.white)),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> updateArea(int id, String areaName) async {
    try {
      await supabase
          .from('delivery_areas')
          .update({'area_name': areaName}).eq('id', id);
      await fetchAreas();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update area: $e',
              style: GoogleFonts.roboto(color: Colors.white)),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> deleteArea(int id) async {
    try {
      final driversInArea =
          await supabase.from('drivers').select('id').eq('area_id', id);

      if (driversInArea.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Cannot delete area: Drivers are assigned to it',
                style: GoogleFonts.roboto(color: Colors.white)),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      await supabase.from('delivery_areas').delete().eq('id', id);
      await fetchAreas();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete area: $e',
              style: GoogleFonts.roboto(color: Colors.white)),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void showAreaDialog({Map<String, dynamic>? area}) {
    if (area != null) {
      editingAreaId = area['id'] as int?;
      areaNameController.text = area['area_name'] ?? '';
    } else {
      editingAreaId = null;
      areaNameController.clear();
    }

    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
            boxShadow: [
              BoxShadow(
                color: Colors.black,
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                area == null ? 'Add Area' : 'Edit Area',
                style: GoogleFonts.roboto(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              Container(
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
                child: TextField(
                  controller: areaNameController,
                  style: GoogleFonts.roboto(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Area Name',
                    labelStyle: GoogleFonts.roboto(
                        color: Colors.white.withOpacity(0.7), fontSize: 15),
                    prefixIcon: Icon(Icons.location_on,
                        color: Colors.white.withOpacity(0.7), size: 20),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Text(
                      'Cancel',
                      style: GoogleFonts.roboto(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () async {
                      final areaName = areaNameController.text.trim();
                      if (areaName.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Area name cannot be empty',
                                style: GoogleFonts.roboto(color: Colors.white)),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }

                      if (editingAreaId == null) {
                        await addArea(areaName);
                      } else {
                        await updateArea(editingAreaId!, areaName);
                      }
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.transparent),
                      ),
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: Text(
                        'Save',
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
            ],
          ),
        ),
      ),
    );
  }

  void showDeleteConfirmation(int id) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Colors.transparent,
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
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Confirm Delete',
                style: GoogleFonts.roboto(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Are you sure you want to delete this area?',
                style: GoogleFonts.roboto(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.7),
                  fontWeight: FontWeight.w400,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Text(
                      'Cancel',
                      style: GoogleFonts.roboto(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () async {
                      await deleteArea(id);
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Delete',
                      style: GoogleFonts.roboto(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    areaNameController.dispose();
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
                  'Manage Areas',
                  style: GoogleFonts.roboto(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
                titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
              ),
              expandedHeight: 100.0,
              leading: IconButton(
                icon:
                    const Icon(Icons.arrow_back, color: Colors.white, size: 24),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            SliverToBoxAdapter(
              child: RefreshIndicator(
                onRefresh: fetchAreas,
                color: Colors.white,
                backgroundColor: Colors.black.withOpacity(0.5),
                child: Container(
                  constraints: BoxConstraints(
                    minHeight: MediaQuery.of(context).size.height -
                        kToolbarHeight -
                        MediaQuery.of(context).padding.top,
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Delivery Areas',
                        style: GoogleFonts.roboto(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
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
                                    'Loading areas...',
                                    style: GoogleFonts.roboto(
                                      color: Colors.white.withOpacity(0.7),
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : areas.isEmpty
                              ? Card(
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
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.info_outline,
                                          color: Colors.white.withOpacity(0.7),
                                          size: 40,
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'No areas found.',
                                          textAlign: TextAlign.center,
                                          style: GoogleFonts.roboto(
                                            color:
                                                Colors.white.withOpacity(0.7),
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Add a new area using the button below.',
                                          textAlign: TextAlign.center,
                                          style: GoogleFonts.roboto(
                                            color:
                                                Colors.white.withOpacity(0.7),
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
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: areas.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(height: 12),
                                  itemBuilder: (context, index) {
                                    final area = areas[index];
                                    final areaId = area['id'] as int;
                                    final areaName = area['area_name'] ?? 'N/A';
                                    final drivers = driversPerArea.firstWhere(
                                      (d) => d['area_id'] == areaId,
                                      orElse: () => {
                                        'drivers': [],
                                      },
                                    )['drivers'] as List<dynamic>;

                                    return Card(
                                      elevation: 0,
                                      color: Colors.transparent,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        side: BorderSide(
                                            color:
                                                Colors.white.withOpacity(0.2)),
                                      ),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          boxShadow: [
                                            BoxShadow(
                                              color:
                                                  Colors.black.withOpacity(0.2),
                                              blurRadius: 6,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        padding: const EdgeInsets.all(12),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    areaName,
                                                    style: GoogleFonts.roboto(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ),
                                                Row(
                                                  children: [
                                                    IconButton(
                                                      icon: const Icon(
                                                          Icons.edit,
                                                          color: Colors.white,
                                                          size: 20),
                                                      onPressed: () {
                                                        HapticFeedback
                                                            .lightImpact();
                                                        showAreaDialog(
                                                            area: area);
                                                      },
                                                    ),
                                                    IconButton(
                                                      icon: const Icon(
                                                          Icons.delete,
                                                          color: Colors.red,
                                                          size: 20),
                                                      onPressed: () {
                                                        HapticFeedback
                                                            .lightImpact();
                                                        showDeleteConfirmation(
                                                            areaId);
                                                      },
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                            if (drivers.isNotEmpty) ...[
                                              const SizedBox(height: 8),
                                              Text(
                                                'Assigned Drivers:',
                                                style: GoogleFonts.roboto(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w500,
                                                  color: Colors.white
                                                      .withOpacity(0.7),
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              ...drivers.map((driver) {
                                                final driverName =
                                                    driver['driver_name'] ??
                                                        'N/A';
                                                final vehicleNumber =
                                                    driver['vehicle_number'] ??
                                                        'N/A';
                                                return Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          top: 4),
                                                  child: Text(
                                                    '$driverName ($vehicleNumber)',
                                                    style: GoogleFonts.roboto(
                                                      fontSize: 13,
                                                      fontWeight:
                                                          FontWeight.w400,
                                                      color: Colors.white
                                                          .withOpacity(0.7),
                                                    ),
                                                  ),
                                                );
                                              }).toList(),
                                            ],
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
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          HapticFeedback.lightImpact();
          showAreaDialog();
        },
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
          child: const Icon(Icons.add, color: Colors.white, size: 24),
        ),
        tooltip: 'Add Area',
      ),
    );
  }
}
