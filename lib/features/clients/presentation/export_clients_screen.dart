import 'dart:io';
import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';

import 'package:crm_app/features/clients/domain/models/client.dart';

class ExportClientsScreen extends StatelessWidget {
  final List<Client> clients;

  const ExportClientsScreen({Key? key, required this.clients})
    : super(key: key);

  // Export to CSV
  Future<void> _exportToCSV() async {
    List<List<String>> rows = [
      ["ID", "Name", "Email", "Phone", "Status"],
    ];
    for (var client in clients) {
      rows.add([
        client.id,
        client.name,
        client.email,
        client.phone.toString(),
        client.status,
      ]);
    }
    String csv = const ListToCsvConverter().convert(rows);

    final directory = await getApplicationDocumentsDirectory();
    final path = "${directory.path}/clients.csv";
    File file = File(path);
    await file.writeAsString(csv);
    // Optionally, show a success message
  }

  // Export to PDF
  Future<void> _exportToPDF() async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Table.fromTextArray(
            headers: ["ID", "Name", "Email", "Phone", "Status"],
            data:
                clients.map((client) {
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
    final directory = await getApplicationDocumentsDirectory();
    final path = directory.path + "/clients.pdf";
    File file = File(path);
    await file.writeAsBytes(await pdf.save());
    // Optionally, show a success message
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Export Clients")),
      body: Column(
        children: [
          ElevatedButton(onPressed: _exportToCSV, child: Text("Export to CSV")),
          ElevatedButton(onPressed: _exportToPDF, child: Text("Export to PDF")),
        ],
      ),
    );
  }
}
