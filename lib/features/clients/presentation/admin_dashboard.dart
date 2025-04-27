import 'dart:io';
import 'dart:typed_data';
import 'package:crm_app/features/clients/presentation/dashboard_screen.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:csv/csv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:go_router/go_router.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _notesController = TextEditingController();
  String _selectedStatus = 'New';

  List<DocumentSnapshot> _clients = [];

  @override
  void initState() {
    super.initState();
    _fetchClients();
  }

  Future<void> _fetchClients() async {
    final querySnapshot =
        await FirebaseFirestore.instance
            .collection('clients')
            .orderBy('createdAt', descending: true)
            .get();
    setState(() {
      _clients = querySnapshot.docs;
    });
  }

  Future<void> _addClient() async {
    if (_formKey.currentState!.validate()) {
      await FirebaseFirestore.instance.collection('clients').add({
        'name': _nameController.text,
        'email': _emailController.text,
        'phone': _phoneController.text,
        'status': _selectedStatus,
        'notes': _notesController.text,
        'createdAt': Timestamp.now(),
      });

      _formKey.currentState!.reset();
      _nameController.clear();
      _emailController.clear();
      _phoneController.clear();
      _notesController.clear();

      await _fetchClients();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Client added successfully!'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  Future<void> _importClientsFromFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (result != null && result.files.single.bytes != null) {
        final platformFile = result.files.single;
        final content = String.fromCharCodes(platformFile.bytes!);
        print('CSV Content:\n$content');

        final rows = const CsvToListConverter().convert(content);
        print('Parsed CSV Rows: ${rows.length}');

        for (var row in rows.skip(1)) {
          if (row.length >= 4) {
            String name = row[0].toString();
            String email = row[1].toString();
            String phone = row[2].toString();
            String status = row[3].toString();
            String notes = row.length > 4 ? row[4].toString() : '';

            final parsedPhone = _parsePhone(phone);

            await FirebaseFirestore.instance.collection('clients').add({
              'name': name,
              'email': email,
              'phone': parsedPhone,
              'status': status,
              'notes': notes,
              'createdAt': Timestamp.now(),
            });
          }
        }

        await _fetchClients();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Data imported successfully!'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      } else {
        print('No file selected or file picker was canceled.');
      }
    } catch (e) {
      print('Error during import: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Import failed: $e'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  int _parsePhone(dynamic phone) {
    if (phone == null) return 0;
    if (phone is int) return phone;
    final parsedPhone = int.tryParse(phone.toString());
    return parsedPhone ?? 0;
  }

  int get _total => _clients.length;
  int get _new => _clients.where((c) => c['status'] == 'New').length;
  int get _won => _clients.where((c) => c['status'] == 'Won').length;
  int get _lost => _clients.where((c) => c['status'] == 'Lost').length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.arrow_back, color: Colors.white),
          ),
          onPressed: () => GoRouter.of(context).go('/dashboard'),
        ),
        title: Text(
          'Admin Dashboard',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.grey[850]!, Colors.grey[900]!],
          ),
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Stats Cards
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,

                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _buildStatCard('Total Clients', _total, Colors.blueAccent),
                    SizedBox(width: 16),
                    _buildStatCard('New Leads', _new, Colors.greenAccent),
                    SizedBox(width: 16),
                    _buildStatCard('Won Leads', _won, Colors.purpleAccent),
                    SizedBox(width: 16),
                    _buildStatCard('Lost Leads', _lost, Colors.redAccent),
                  ],
                ),
              ),
              SizedBox(height: 24),

              // Import Button
              Center(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.4),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: ElevatedButton.icon(
                    onPressed: _importClientsFromFile,
                    icon: Icon(Icons.upload_file, color: Colors.white),
                    label: Text(
                      "Import from CSV",
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent.withOpacity(0.7),
                      padding: EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 24,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 24),

              // Add Client Form
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: Colors.black.withOpacity(0.3),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.1),
                    width: 1,
                  ),
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Add New Client",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 16),
                      _buildGlassInputField(
                        controller: _nameController,
                        label: 'Name',
                        validator: (val) => val!.isEmpty ? 'Enter name' : null,
                      ),
                      SizedBox(height: 16),
                      _buildGlassInputField(
                        controller: _emailController,
                        label: 'Email',
                        validator: (val) => val!.isEmpty ? 'Enter email' : null,
                      ),
                      SizedBox(height: 16),
                      _buildGlassInputField(
                        controller: _phoneController,
                        label: 'Phone',
                      ),
                      SizedBox(height: 16),
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.black.withOpacity(0.2),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.1),
                          ),
                        ),
                        child: DropdownButtonFormField<String>(
                          value: _selectedStatus,
                          onChanged:
                              (val) => setState(() => _selectedStatus = val!),
                          items:
                              ['New', 'Won', 'Lost']
                                  .map(
                                    (status) => DropdownMenuItem(
                                      value: status,
                                      child: Text(
                                        status,
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    ),
                                  )
                                  .toList(),
                          decoration: InputDecoration(
                            labelText: 'Status',
                            labelStyle: TextStyle(color: Colors.white70),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16,
                            ),
                          ),
                          dropdownColor: Colors.grey[900],
                          icon: Icon(
                            Icons.arrow_drop_down,
                            color: Colors.white,
                          ),
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      SizedBox(height: 16),
                      _buildGlassInputField(
                        controller: _notesController,
                        label: 'Notes',
                        maxLines: 3,
                      ),
                      SizedBox(height: 20),
                      Center(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.blueAccent.withOpacity(0.4),
                                blurRadius: 10,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: ElevatedButton.icon(
                            onPressed: _addClient,
                            icon: Icon(Icons.save, color: Colors.white),
                            label: Text(
                              "Add Client",
                              style: TextStyle(color: Colors.white),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blueAccent.withOpacity(
                                0.7,
                              ),
                              padding: EdgeInsets.symmetric(
                                vertical: 16,
                                horizontal: 24,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 0,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 24),
              Divider(color: Colors.white.withOpacity(0.1)),
              SizedBox(height: 16),
              Text(
                "Clients",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 16),
              ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: _clients.length,
                itemBuilder: (context, index) {
                  final client = _clients[index];
                  return Container(
                    margin: EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: Colors.black.withOpacity(0.3),
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                    ),
                    child: ListTile(
                      title: Text(
                        client['name'],
                        style: TextStyle(color: Colors.white),
                      ),
                      subtitle: Text(
                        client['email'],
                        style: TextStyle(color: Colors.white70),
                      ),
                      trailing: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor(client['status']),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          client['status'],
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
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
    );
  }

  Widget _buildGlassInputField({
    required TextEditingController controller,
    required String label,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.black.withOpacity(0.2),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: TextFormField(
        controller: controller,
        style: TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.white70),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        validator: validator,
        maxLines: maxLines,
      ),
    );
  }

  Widget _buildStatCard(String title, int count, Color color) {
    return Container(
      width: 180,
      padding: EdgeInsets.all(20),
      margin: EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.black.withOpacity(0.3),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: Colors.white70, fontSize: 14)),
          SizedBox(height: 8),
          Text(
            '$count',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'New':
        return Colors.blueAccent.withOpacity(0.7);
      case 'Won':
        return Colors.greenAccent.withOpacity(0.7);
      case 'Lost':
        return Colors.redAccent.withOpacity(0.7);
      default:
        return Colors.grey.withOpacity(0.7);
    }
  }
}
