import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class VipUpdateTransactionScreen extends StatefulWidget {
  const VipUpdateTransactionScreen({super.key});

  @override
  State<VipUpdateTransactionScreen> createState() =>
      _VipUpdateTransactionScreenState();
}

class _VipUpdateTransactionScreenState
    extends State<VipUpdateTransactionScreen> {
  final supabase = Supabase.instance.client;
  final _traysController = TextEditingController();
  final _paidController = TextEditingController();
  List<Map<String, dynamic>> users = [];
  List<Map<String, dynamic>> transactions = [];
  String? selectedUserId;
  String? editingTransactionId; // Changed from int? to String?
  DateTime? startDate;
  DateTime? endDate;
  String? selectedModeOfPayment;
  String? selectedPaymentMode;
  bool sortAscending = false;
  bool isLoadingUsers = false;
  bool isLoadingTransactions = false;
  String? errorMessage;
  double? calculatedCredit;
  double eggRate = 10.0; // Default egg rate

  @override
  void initState() {
    super.initState();
    _fetchUsers();
    _fetchTransactions();
    _fetchEggRate();
    _traysController.addListener(_calculateCredit);
  }

  Future<void> _fetchUsers() async {
    setState(() {
      isLoadingUsers = true;
      errorMessage = null;
    });
    try {
      final response = await supabase
          .from('wholesale_users')
          .select('id, full_name')
          .order('full_name');
      setState(() {
        users = List<Map<String, dynamic>>.from(response);
        isLoadingUsers = false;
      });
    } on PostgrestException catch (e) {
      String message;
      if (e.code == '42P01') {
        message =
            'Table "wholesale_users" does not exist. Verify Supabase schema.';
      } else if (e.code == '42501') {
        message =
            'Permission denied for "wholesale_users". Check RLS policies.';
      } else {
        message = 'Error fetching users: ${e.message} (Code: ${e.code})';
      }
      setState(() {
        errorMessage = message;
        isLoadingUsers = false;
      });
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      setState(() {
        errorMessage = 'Unexpected error fetching users: $e';
        isLoadingUsers = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unexpected error fetching users: $e')));
    }
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
      } else {
        setState(() {
          errorMessage = 'No egg rate found, using default rate ₹10.0';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('No egg rate found, using default rate ₹10.0')),
        );
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
        message = 'Error fetching egg rate: ${e.message} (Code: ${e.code})';
      }
      setState(() {
        errorMessage = message;
      });
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      setState(() {
        errorMessage = 'Unexpected error fetching egg rate: $e';
      });
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unexpected error fetching egg rate: $e')));
    }
  }

  void _calculateCredit() {
    final traysText = _traysController.text.trim();
    final trays = int.tryParse(traysText);
    if (trays != null && trays > 0) {
      setState(() {
        calculatedCredit = (eggRate * 30) * trays;
      });
    } else {
      setState(() {
        calculatedCredit = null;
      });
    }
  }

  Future<void> _fetchTransactions() async {
    setState(() {
      isLoadingTransactions = true;
      errorMessage = null;
    });
    try {
      var query = supabase.from('wholesale_transaction').select(
          'id, user_id, date, credit, paid, balance, mode_of_payment, wholesale_users!inner(full_name)');

      // Apply filters
      if (selectedUserId != null && selectedUserId!.isNotEmpty) {
        query = query.eq('user_id', selectedUserId!);
      }
      if (startDate != null) {
        query = query.gte('date', startDate!.toIso8601String());
      }
      if (endDate != null) {
        query = query.lte('date', endDate!.toIso8601String());
      }
      if (selectedModeOfPayment != null && selectedModeOfPayment != 'All') {
        if (selectedModeOfPayment == 'None') {
          query = query.isFilter('mode_of_payment', null);
        } else {
          query = query.eq('mode_of_payment', selectedModeOfPayment!);
        }
      }

      // Apply sorting
      final response = await query.order('date', ascending: sortAscending);

      setState(() {
        transactions = List<Map<String, dynamic>>.from(response);
        isLoadingTransactions = false;
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
        isLoadingTransactions = false;
      });
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
      print(
          'PostgrestException in _fetchTransactions: $e, Details: ${e.details}');
    } on FormatException catch (e) {
      setState(() {
        errorMessage = 'Invalid user ID format: $e';
        isLoadingTransactions = false;
      });
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Invalid user ID format: $e')));
    } catch (e) {
      setState(() {
        errorMessage = 'Unexpected error fetching transactions: $e';
        isLoadingTransactions = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Unexpected error fetching transactions: $e')));
      print('Unexpected error in _fetchTransactions: $e');
    }
  }

  Future<void> _updateTransaction() async {
    setState(() {
      isLoadingTransactions = true;
      errorMessage = null;
    });
    try {
      if (selectedUserId == null) {
        throw Exception('Please select a user');
      }
      final traysText = _traysController.text.trim();
      final trays = int.tryParse(traysText);
      if (trays == null || trays <= 0) {
        throw Exception('Please enter a valid number of trays');
      }
      final credit = (eggRate * 30) * trays;
      final paid = double.tryParse(_paidController.text) ?? 0.0;
      final modeOfPayment = selectedPaymentMode;

      final transactionData = {
        'user_id': selectedUserId!,
        'date': DateTime.now().toIso8601String(),
        'credit': credit,
        'paid': paid,
        'balance': credit - paid,
        'mode_of_payment': modeOfPayment,
        // Uncomment if you add a trays column to wholesale_transaction
        // 'trays': trays,
      };

      if (editingTransactionId != null) {
        await supabase
            .from('wholesale_transaction')
            .update(transactionData)
            .eq('id', editingTransactionId!);
      } else {
        await supabase.from('wholesale_transaction').insert(transactionData);
      }

      setState(() {
        _traysController.clear();
        _paidController.clear();
        selectedPaymentMode = null;
        selectedUserId = null;
        editingTransactionId = null;
        calculatedCredit = null;
      });
      _fetchTransactions();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(editingTransactionId != null
                ? 'Transaction updated successfully'
                : 'Transaction added successfully')),
      );
    } on PostgrestException catch (e) {
      String message;
      if (e.code == '42P01') {
        message =
            'Table "wholesale_transaction" does not exist. Verify schema.';
      } else if (e.code == '42501') {
        message = 'Permission denied for "wholesale_transaction". Check RLS.';
      } else {
        message = 'Error updating transaction: ${e.message} (Code: ${e.code})';
      }
      setState(() {
        errorMessage = message;
        isLoadingTransactions = false;
      });
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      setState(() {
        errorMessage = 'Unexpected error updating transaction: $e';
        isLoadingTransactions = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unexpected error updating transaction: $e')));
    }
  }

  Future<void> _deleteTransaction(String id) async {
    // Changed from int to String
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content:
            const Text('Are you sure you want to delete this transaction?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      isLoadingTransactions = true;
      errorMessage = null;
    });
    try {
      await supabase.from('wholesale_transaction').delete().eq('id', id);
      _fetchTransactions();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Transaction deleted successfully')),
      );
    } on PostgrestException catch (e) {
      String message;
      if (e.code == '42P01') {
        message =
            'Table "wholesale_transaction" does not exist. Verify schema.';
      } else if (e.code == '42501') {
        message = 'Permission denied for "wholesale_transaction". Check RLS.';
      } else {
        message = 'Error deleting transaction: ${e.message} (Code: ${e.code})';
      }
      setState(() {
        errorMessage = message;
        isLoadingTransactions = false;
      });
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      setState(() {
        errorMessage = 'Unexpected error deleting transaction: $e';
        isLoadingTransactions = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unexpected error deleting transaction: $e')));
    }
  }

  void _editTransaction(Map<String, dynamic> transaction) {
    setState(() {
      editingTransactionId = transaction['id'].toString(); // Ensure string
      selectedUserId = transaction['user_id'].toString();
      final credit = transaction['credit'] as num;
      final trays = (credit / (eggRate * 30)).round();
      _traysController.text = trays.toString();
      _paidController.text = transaction['paid'].toString();
      selectedPaymentMode = transaction['mode_of_payment'];
      _calculateCredit();
    });
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF2196F3),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
            dialogBackgroundColor: Colors.white,
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        startDate = picked.start;
        endDate = picked.end;
      });
      _fetchTransactions();
    }
  }

  @override
  void dispose() {
    _traysController.removeListener(_calculateCredit);
    _traysController.dispose();
    _paidController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Update Transaction',
          style: GoogleFonts.roboto(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: const Color(0xFF1A0841),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1A0841), Color(0xFF3B322C)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: isLoadingUsers
            ? Center(
                child: CircularProgressIndicator(
                  color: Colors.white,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : RefreshIndicator(
                onRefresh: _fetchTransactions,
                color: Colors.white,
                backgroundColor: const Color(0xFF3B322C),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Transaction Input Form
                      Card(
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
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                editingTransactionId != null
                                    ? 'Edit Transaction'
                                    : 'Add New Transaction',
                                style: GoogleFonts.roboto(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF1A0841),
                                ),
                              ),
                              const SizedBox(height: 16),
                              DropdownButtonFormField<String>(
                                value: selectedUserId,
                                hint: Text(
                                  'Select User',
                                  style:
                                      GoogleFonts.roboto(color: Colors.black54),
                                ),
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  filled: true,
                                  fillColor: Colors.white.withOpacity(0.7),
                                ),
                                dropdownColor: Colors.white,
                                items: users.map((user) {
                                  return DropdownMenuItem<String>(
                                    value: user['id'].toString(),
                                    child: Text(
                                      user['full_name'],
                                      style: GoogleFonts.roboto(),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    selectedUserId = value;
                                  });
                                  _fetchTransactions();
                                },
                              ),
                              const SizedBox(height: 16),
                              TextField(
                                controller: _traysController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: 'Number of Trays',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  filled: true,
                                  fillColor: Colors.white.withOpacity(0.7),
                                ),
                                style: GoogleFonts.roboto(),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Egg Rate: ₹${eggRate.toStringAsFixed(2)} per egg',
                                style: GoogleFonts.roboto(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                calculatedCredit != null
                                    ? 'Calculated Credit: ₹${calculatedCredit!.toStringAsFixed(2)}'
                                    : 'Enter trays to calculate credit',
                                style: GoogleFonts.roboto(
                                  fontSize: 14,
                                  color: calculatedCredit != null
                                      ? const Color(0xFF4CAF50)
                                      : Colors.grey[700],
                                ),
                              ),
                              const SizedBox(height: 16),
                              TextField(
                                controller: _paidController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: 'Paid (₹)',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  filled: true,
                                  fillColor: Colors.white.withOpacity(0.7),
                                ),
                                style: GoogleFonts.roboto(),
                              ),
                              const SizedBox(height: 16),
                              DropdownButtonFormField<String>(
                                value: selectedPaymentMode,
                                hint: Text(
                                  'Select Payment Mode',
                                  style:
                                      GoogleFonts.roboto(color: Colors.black54),
                                ),
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  filled: true,
                                  fillColor: Colors.white.withOpacity(0.7),
                                ),
                                dropdownColor: Colors.white,
                                items: const [
                                  DropdownMenuItem(
                                    value: 'Cash',
                                    child: Text('Cash'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'Online',
                                    child: Text('Online'),
                                  ),
                                ],
                                onChanged: (value) {
                                  setState(() {
                                    selectedPaymentMode = value;
                                  });
                                },
                              ),
                              const SizedBox(height: 16),
                              if (errorMessage != null)
                                Text(
                                  errorMessage!,
                                  style: GoogleFonts.roboto(
                                    color: Colors.redAccent,
                                    fontSize: 14,
                                  ),
                                ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: isLoadingTransactions
                                    ? null
                                    : _updateTransaction,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF2196F3),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                  minimumSize: const Size(double.infinity, 50),
                                ),
                                child: isLoadingTransactions
                                    ? const CircularProgressIndicator(
                                        color: Colors.white)
                                    : Text(
                                        editingTransactionId != null
                                            ? 'Update Transaction'
                                            : 'Add Transaction',
                                        style: GoogleFonts.roboto(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Filter and Sorting Controls
                      Card(
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
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Filters',
                                style: GoogleFonts.roboto(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF1A0841),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: TextButton.icon(
                                      onPressed: _selectDateRange,
                                      icon: const Icon(Icons.calendar_today,
                                          color: Color(0xFF1A0841)),
                                      label: Text(
                                        startDate == null
                                            ? 'Select Date Range'
                                            : '${DateFormat('d MMM').format(startDate!)} - ${DateFormat('d MMM').format(endDate!)}',
                                        style: GoogleFonts.roboto(
                                          color: const Color(0xFF1A0841),
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: DropdownButton<String>(
                                      value: selectedModeOfPayment ?? 'All',
                                      items: const [
                                        DropdownMenuItem(
                                            value: 'All',
                                            child: Text('All Modes')),
                                        DropdownMenuItem(
                                            value: 'Cash', child: Text('Cash')),
                                        DropdownMenuItem(
                                            value: 'Online',
                                            child: Text('Online')),
                                        DropdownMenuItem(
                                            value: 'None', child: Text('None')),
                                      ],
                                      onChanged: (value) {
                                        setState(() {
                                          selectedModeOfPayment = value;
                                        });
                                        _fetchTransactions();
                                      },
                                      isExpanded: true,
                                      underline: const SizedBox(),
                                      style: GoogleFonts.roboto(
                                        color: const Color(0xFF1A0841),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              DropdownButton<bool>(
                                value: sortAscending,
                                items: const [
                                  DropdownMenuItem(
                                    value: false,
                                    child: Text('Newest First'),
                                  ),
                                  DropdownMenuItem(
                                    value: true,
                                    child: Text('Oldest First'),
                                  ),
                                ],
                                onChanged: (value) {
                                  setState(() {
                                    sortAscending = value!;
                                  });
                                  _fetchTransactions();
                                },
                                isExpanded: true,
                                underline: const SizedBox(),
                                style: GoogleFonts.roboto(
                                  color: const Color(0xFF1A0841),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Transaction History
                      Text(
                        'Transaction History',
                        style: GoogleFonts.roboto(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
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
                      isLoadingTransactions
                          ? Center(
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : transactions.isEmpty
                              ? Card(
                                  elevation: 4,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0xFFF5F5F5),
                                          Colors.white
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
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
                                          selectedUserId == null
                                              ? 'No transactions found.'
                                              : 'No transactions for this user.',
                                          textAlign: TextAlign.center,
                                          style: GoogleFonts.roboto(
                                            color: Colors.grey[700],
                                            fontSize: 18,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              : ListView.separated(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: transactions.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(height: 12),
                                  itemBuilder: (context, index) {
                                    final transaction = transactions[index];
                                    final userName =
                                        transaction['wholesale_users']
                                            ['full_name'];
                                    final date =
                                        DateTime.parse(transaction['date']);
                                    final formattedDate =
                                        DateFormat('d MMM yyyy, HH:mm')
                                            .format(date);
                                    final credit = transaction['credit']
                                        .toStringAsFixed(2);
                                    final paid =
                                        transaction['paid'].toStringAsFixed(2);
                                    final balance = transaction['balance']
                                        .toStringAsFixed(2);
                                    final modeOfPayment =
                                        transaction['mode_of_payment'] ??
                                            'None';
                                    final trays =
                                        (transaction['credit'] / (eggRate * 30))
                                            .round();
                                    final initials = userName
                                        .split(' ')
                                        .map((e) => e.isNotEmpty ? e[0] : '')
                                        .take(2)
                                        .join();
                                    final balanceColor =
                                        (transaction['balance'] as num) > 0
                                            ? Colors.redAccent
                                            : Colors.green;

                                    return AnimatedOpacity(
                                      opacity: 1.0,
                                      duration:
                                          const Duration(milliseconds: 300),
                                      child: Card(
                                        elevation: 4,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Container(
                                          decoration: BoxDecoration(
                                            gradient: const LinearGradient(
                                              colors: [
                                                Color(0xFFF5F5F5),
                                                Colors.white
                                              ],
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            border: Border.all(
                                                color: Colors.grey.shade300),
                                          ),
                                          padding: EdgeInsets.all(
                                              screenWidth < 400 ? 12 : 16),
                                          child: Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              CircleAvatar(
                                                radius:
                                                    screenWidth < 400 ? 20 : 24,
                                                backgroundColor:
                                                    const Color(0xFF2196F3),
                                                child: Text(
                                                  initials,
                                                  style: GoogleFonts.roboto(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.w700,
                                                    fontSize: screenWidth < 400
                                                        ? 14
                                                        : 16,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Row(
                                                      children: [
                                                        Expanded(
                                                          child: Text(
                                                            userName,
                                                            style: GoogleFonts
                                                                .roboto(
                                                              fontSize:
                                                                  screenWidth <
                                                                          400
                                                                      ? 14
                                                                      : 16,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w700,
                                                              color: const Color(
                                                                  0xFF1A0841),
                                                            ),
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                          ),
                                                        ),
                                                        Chip(
                                                          label: Text(
                                                            modeOfPayment,
                                                            style: GoogleFonts
                                                                .roboto(
                                                              fontSize: 10,
                                                              color: Colors
                                                                  .grey[800],
                                                            ),
                                                          ),
                                                          avatar: Icon(
                                                            modeOfPayment ==
                                                                    'Cash'
                                                                ? Icons.money
                                                                : modeOfPayment ==
                                                                        'Online'
                                                                    ? Icons
                                                                        .credit_card
                                                                    : Icons
                                                                        .block,
                                                            size: 14,
                                                            color: Colors
                                                                .grey[800],
                                                          ),
                                                          backgroundColor:
                                                              Colors.grey
                                                                  .shade200,
                                                          padding:
                                                              const EdgeInsets
                                                                  .symmetric(
                                                                  horizontal:
                                                                      4),
                                                          labelPadding:
                                                              const EdgeInsets
                                                                  .only(
                                                                  right: 4),
                                                        ),
                                                      ],
                                                    ),
                                                    const SizedBox(height: 8),
                                                    Text(
                                                      'Date: $formattedDate',
                                                      style: GoogleFonts.roboto(
                                                        fontSize:
                                                            screenWidth < 400
                                                                ? 10
                                                                : 12,
                                                        color: Colors.grey[800],
                                                      ),
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      'Trays: $trays',
                                                      style: GoogleFonts.roboto(
                                                        fontSize:
                                                            screenWidth < 400
                                                                ? 12
                                                                : 14,
                                                        color: const Color(
                                                            0xFF4CAF50),
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                    ),
                                                    Text(
                                                      'Credit: ₹$credit',
                                                      style: GoogleFonts.roboto(
                                                        fontSize:
                                                            screenWidth < 400
                                                                ? 12
                                                                : 14,
                                                        color: const Color(
                                                            0xFF4CAF50),
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                    ),
                                                    Text(
                                                      'Paid: ₹$paid',
                                                      style: GoogleFonts.roboto(
                                                        fontSize:
                                                            screenWidth < 400
                                                                ? 12
                                                                : 14,
                                                        color: Colors.grey[800],
                                                      ),
                                                    ),
                                                    Text(
                                                      'Balance: ₹$balance',
                                                      style: GoogleFonts.roboto(
                                                        fontSize:
                                                            screenWidth < 400
                                                                ? 12
                                                                : 14,
                                                        color: balanceColor,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Column(
                                                children: [
                                                  Tooltip(
                                                    message: 'Edit Transaction',
                                                    child: IconButton(
                                                      icon: Icon(
                                                        Icons.edit,
                                                        size: screenWidth < 400
                                                            ? 18
                                                            : 20,
                                                        color: const Color(
                                                            0xFF2196F3),
                                                      ),
                                                      onPressed: () =>
                                                          _editTransaction(
                                                              transaction),
                                                    ),
                                                  ),
                                                  Tooltip(
                                                    message:
                                                        'Delete Transaction',
                                                    child: IconButton(
                                                      icon: Icon(
                                                        Icons.delete,
                                                        size: screenWidth < 400
                                                            ? 18
                                                            : 20,
                                                        color: Colors.red,
                                                      ),
                                                      onPressed: () =>
                                                          _deleteTransaction(
                                                              transaction[
                                                                  'id']),
                                                    ),
                                                  ),
                                                ],
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
              ),
      ),
    );
  }
}
