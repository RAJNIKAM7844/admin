import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class VipUpdateRatePage extends StatefulWidget {
  const VipUpdateRatePage({super.key});

  @override
  State<VipUpdateRatePage> createState() => _VipUpdateRatePageState();
}

class _VipUpdateRatePageState extends State<VipUpdateRatePage> {
  final supabase = Supabase.instance.client;
  final _rateController = TextEditingController();
  bool isLoading = false;
  String? errorMessage;
  double? currentRate;
  String? currentRateId; // Store the ID of the current rate record

  @override
  void initState() {
    super.initState();
    _fetchCurrentRate();
  }

  Future<void> _fetchCurrentRate() async {
    try {
      final response = await supabase
          .from('wholesale_eggrate')
          .select('id, rate')
          .order('updated_at', ascending: false)
          .limit(1)
          .maybeSingle();
      if (response != null) {
        setState(() {
          currentRateId = response['id']?.toString();
          currentRate = (response['rate'] as num?)?.toDouble();
          _rateController.text = currentRate?.toStringAsFixed(2) ?? '';
        });
      } else {
        setState(() {
          errorMessage = 'No existing rate found.';
        });
      }
    } on PostgrestException catch (e) {
      String message;
      if (e.code == '42P01') {
        message =
            'Table "wholesale_eggrate" does not exist. Verify Supabase schema.';
      } else if (e.code == '42501') {
        message =
            'Permission denied for "wholesale_eggrate". Check RLS policies.';
      } else {
        message = 'Error fetching current rate: ${e.message} (Code: ${e.code})';
      }
      setState(() {
        errorMessage = message;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } catch (e) {
      setState(() {
        errorMessage = 'Unexpected error fetching current rate: $e';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unexpected error fetching current rate: $e')),
      );
    }
  }

  Future<void> _updateRate() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });
    try {
      final newRate = double.tryParse(_rateController.text);
      if (newRate == null || newRate <= 0) {
        throw Exception('Please enter a valid positive rate');
      }
      if (currentRateId == null) {
        throw Exception('No existing rate record found to update');
      }
      // Update the existing record
      await supabase.from('wholesale_eggrate').update({
        'rate': newRate,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', currentRateId!);
      setState(() {
        currentRate = newRate;
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Rate updated successfully')),
      );
    } on PostgrestException catch (e) {
      String message;
      if (e.code == '42P01') {
        message =
            'Table "wholesale_eggrate" does not exist. Verify Supabase schema.';
      } else if (e.code == '42501') {
        message =
            'Permission denied for "wholesale_eggrate". Check RLS policies.';
      } else {
        message = 'Error updating rate: ${e.message} (Code: ${e.code})';
      }
      setState(() {
        errorMessage = message;
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } catch (e) {
      setState(() {
        errorMessage = 'Unexpected error updating rate: $e';
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unexpected error updating rate: $e')),
      );
    }
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
          child: CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                backgroundColor: Colors.transparent,
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(
                    'Update Egg Price',
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
                  icon: const Icon(Icons.arrow_back,
                      color: Colors.white, size: 24),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black,
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
                            'Set Egg Rate',
                            style: GoogleFonts.roboto(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Colors.black,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (currentRate != null)
                            Text(
                              'Current Rate: ₹${currentRate!.toStringAsFixed(2)}',
                              style: GoogleFonts.roboto(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Colors.green,
                              ),
                            ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _rateController,
                            keyboardType: TextInputType.number,
                            style: GoogleFonts.roboto(
                              color: Colors.black,
                              fontSize: 15,
                              letterSpacing: 0.5,
                            ),
                            decoration: InputDecoration(
                              labelText: 'New Rate (₹)',
                              labelStyle: GoogleFonts.roboto(
                                color: Colors.grey,
                                fontSize: 15,
                              ),
                              prefixIcon: const Icon(
                                Icons.attach_money,
                                color: Colors.grey,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: Colors.grey.shade200,
                              contentPadding: const EdgeInsets.symmetric(
                                  vertical: 12, horizontal: 16),
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (errorMessage != null)
                            Text(
                              errorMessage!,
                              style: GoogleFonts.roboto(
                                color: Colors.redAccent,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: isLoading ? null : _updateRate,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors
                                  .transparent, // Transparent button background
                              shadowColor: Colors.transparent, // No shadow
                              padding: EdgeInsets
                                  .zero, // No padding to interfere with the container
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                    12), // Rounded corners
                              ),
                              minimumSize: const Size(
                                  double.infinity, 50), // Full-width button
                            ),
                            child: Ink(
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFFE91E63), // Start color (pink)
                                    Color(0xFF4CAF50), // End color (green)
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(
                                    12), // Match button's border radius
                              ),
                              child: Container(
                                alignment: Alignment.center,
                                constraints: const BoxConstraints(
                                  minHeight:
                                      50, // Ensure the button has a minimum height
                                  minWidth: double
                                      .infinity, // Ensure the button spans full width
                                ),
                                padding: const EdgeInsets.symmetric(
                                    vertical: 12, horizontal: 20),
                                child: isLoading
                                    ? const CircularProgressIndicator(
                                        color: Colors
                                            .white, // Loading spinner color
                                      )
                                    : Text(
                                        'Update Rate',
                                        style: GoogleFonts.roboto(
                                          color: Colors.white, // Text color
                                          fontSize: 15, // Font size
                                          fontWeight: FontWeight.w600, //
                                        ),
                                      ),
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
