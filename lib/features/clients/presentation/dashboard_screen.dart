import 'dart:convert';
import 'dart:io';
import 'dart:io' as io;
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crm_app/features/clients/data/respositories/client_repositories.dart';
import 'package:crm_app/features/clients/domain/models/client.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/Pdf.dart';
import 'package:printing/printing.dart';
import 'package:go_router/go_router.dart';
import 'package:universal_html/html.dart' as html;

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _totalClients = 0;
  int _newLeads = 0;
  int _wonLeads = 0;
  int _lostLeads = 0;
  List<Client> _clients = [];
  String _searchQuery = '';
  String _selectedStatus = 'All';

  @override
  void initState() {
    super.initState();
    _fetchClientStats();
  }

  Future<void> _fetchClientStats() async {
    final clients =
        await ClientRepository(FirebaseFirestore.instance).fetchClients();
    setState(() {
      _clients = clients;
      _totalClients = clients.length;
      _newLeads = clients.where((client) => client.status == 'New').length;
      _wonLeads = clients.where((client) => client.status == 'Won').length;
      _lostLeads = clients.where((client) => client.status == 'Lost').length;
    });
  }

  List<Client> get filteredClients {
    return _clients.where((client) {
      final matchesSearch =
          client.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          client.email.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesStatus =
          _selectedStatus == 'All' || client.status == _selectedStatus;
      return matchesSearch && matchesStatus;
    }).toList();
  }

  Future<void> _exportToCSV() async {
    List<List<String>> rows = [
      ["ID", "Name", "Email", "Phone", "Status"],
    ];
    for (var client in filteredClients) {
      rows.add([
        client.id,
        client.name,
        client.email,
        client.phone.toString(),
        client.status,
      ]);
    }

    String csv = const ListToCsvConverter().convert(rows);

    if (kIsWeb) {
      // Web: Trigger file download
      final bytes = utf8.encode(csv);
      final blob = html.Blob([bytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor =
          html.AnchorElement(href: url)
            ..setAttribute("download", "clients.csv")
            ..click();
      html.Url.revokeObjectUrl(url);
    } else {
      // Android/iOS/Desktop
      final directory = await getApplicationDocumentsDirectory();
      final path = "${directory.path}/clients.csv";
      final file = io.File(path);
      await file.writeAsString(csv);
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('CSV exported to $path')));
      }
    }
  }

  Future<void> _exportToPDF() async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Table.fromTextArray(
            headers: ["ID", "Name", "Email", "Phone", "Status"],
            data:
                filteredClients.map((client) {
                  return [
                    client.id,
                    client.name,
                    client.email,
                    client.phone,
                    client.status,
                  ];
                }).toList(),
          );
        },
      ),
    );

    final bytes = await pdf.save();

    if (kIsWeb) {
      final blob = html.Blob([bytes], 'application/pdf');
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor =
          html.AnchorElement(href: url)
            ..setAttribute("download", "clients.pdf")
            ..click();
      html.Url.revokeObjectUrl(url);
    } else {
      final directory = await getApplicationDocumentsDirectory();
      final path = "${directory.path}/clients.pdf";
      final file = io.File(path);
      await file.writeAsBytes(bytes);
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('PDF exported to $path')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 0, 0, 0),
      appBar: AppBar(
        title: Row(
          children: [
            kIsWeb
                ? Image.asset(
                  'assets/4.jpg', // Replace with your web logo URL
                  height: 40,
                )
                : Image.asset(
                  'assets/4.jpg', // Replace with the path to your mobile logo asset
                  height: 140,
                ),
            const SizedBox(width: 10),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 500),
              style: const TextStyle(
                color: Colors.white,
                fontFamily:
                    'Roboto', // Replace 'Roboto' with your desired Google Font
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
              child: const Text('LEAD FLOW'),
            ),
          ],
        ),
        backgroundColor: Colors.black87, // Dark background for the app bar
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () => context.go('/'),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/add-client'),
        icon: Icon(Icons.person_add, color: Colors.black),
        label: Text('Add Client', style: TextStyle(color: Colors.black)),
        backgroundColor: const Color.fromARGB(255, 0, 123, 255),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                _buildStatCard('Total Clients', _totalClients, Colors.blue),
                _buildStatCard('New Leads', _newLeads, Colors.green),
                _buildStatCard('Won Leads', _wonLeads, Colors.purple),
                _buildStatCard('Lost Leads', _lostLeads, Colors.red),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                    onChanged: (value) => setState(() => _searchQuery = value),
                    decoration: InputDecoration(
                      hintText: 'Search by name or email...',
                      prefixIcon: Icon(Icons.search, color: Colors.white),
                      filled: true,
                      fillColor: Colors.black54,
                      border: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: Colors.white.withOpacity(0.3),
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(width: 10),
                DropdownButton<String>(
                  value: _selectedStatus,
                  onChanged:
                      (value) => setState(() => _selectedStatus = value!),
                  items:
                      ['All', 'New', 'Won', 'Lost'].map((status) {
                        return DropdownMenuItem(
                          value: status,
                          child: Text(
                            status,
                            style: TextStyle(color: Colors.white),
                          ),
                        );
                      }).toList(),
                  dropdownColor: Colors.black87,
                  underline: Container(
                    height: 2,
                    color: Colors.white.withOpacity(0.3),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _buildGlassButton(
                    onPressed: _exportToCSV,
                    icon: Icons.download,
                    label: "Export CSV",
                    color: Colors.blueAccent,
                  ),
                  const SizedBox(width: 10),
                  _buildGlassButton(
                    onPressed: _exportToPDF,
                    icon: Icons.picture_as_pdf,
                    label: "Export PDF",
                    color: Colors.redAccent,
                  ),
                  const SizedBox(width: 10),

                  _buildGlassButton(
                    onPressed:
                        () => GoRouter.of(context).go('/admin/dashboard'),
                    icon: Icons.admin_panel_settings,
                    label: "Admin Panel",
                    color: Colors.deepPurple,
                  ),
                  const SizedBox(width: 10),

                  _buildGlassButton(
                    onPressed: () => context.push('/client-list'),
                    icon: Icons.list_alt,
                    label: 'View Clients',
                    color: Colors.teal,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            ListView.builder(
              itemCount: filteredClients.length,
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemBuilder: (context, index) {
                final client = filteredClients[index];
                return AnimatedContainer(
                  duration: Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black45.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.5),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: ListTile(
                    title: Text(
                      client.name,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    subtitle: Text(
                      client.email,
                      style: TextStyle(color: Colors.white70),
                    ),
                    trailing: Chip(
                      label: Text(
                        client.status,
                        style: TextStyle(color: Colors.white),
                      ),
                      backgroundColor: _getStatusColor(client.status),
                    ),
                    onTap: () {},
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, int count, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      width: 160,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 14, color: color)),
          const SizedBox(height: 4),
          Text(
            '$count',
            style: TextStyle(
              fontSize: 24,
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
        return Colors.green.shade300;
      case 'Won':
        return Colors.blue.shade300;
      case 'Lost':
        return Colors.red.shade300;
      default:
        return Colors.grey.shade400;
    }
  }

  Widget _buildGlassButton({
    required VoidCallback onPressed,
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.4),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 8,
              spreadRadius: 2,
            ),
          ],
        ),
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(color: Colors.white)),
          ],
        ),
      ),
    );
  }
}
