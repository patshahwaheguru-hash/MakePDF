import 'dart:io';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MakePDF',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.blue),
      home: const HomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _status = 'No file selected';
  bool _loading = false;

  Future<void> _pickAndConvert() async {
    setState(() { _loading = true; _status = 'Picking file...'; });
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'xls'],
    );
    if (result == null) { setState(() { _loading = false; _status = 'Cancelled'; }); return; }
    await _convertExcelToPdf(File(result.files.single.path!));
  }

  Future<void> _convertExcelToPdf(File excelFile) async {
    try {
      setState(() { _status = 'Reading Excel...'; });
      var bytes = await excelFile.readAsBytes();
      var excel = Excel.decodeBytes(bytes);
      final pdf = pw.Document();
      for (var table in excel.tables.keys) {
        var sheet = excel.tables[table]!;
        pdf.addPage(pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) => [
            pw.Header(text: 'Sheet: $table'),
            pw.Table.fromTextArray(
              headers: sheet.rows.first.map((e) => e?.value.toString()?? '').toList(),
              data: sheet.rows.skip(1).map((row) => row.map((e) => e?.value.toString()?? '').toList()).toList(),
            ),
          ],
        ));
      }
      setState(() { _status = 'Saving PDF...'; });
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/converted.pdf');
      await file.writeAsBytes(await pdf.save());
      setState(() { _status = 'Done! Saved as converted.pdf'; });
      await Share.shareXFiles([XFile(file.path)], text: 'My Excel to PDF');
    } catch (e) {
      setState(() { _status = 'Error: $e'; });
    }
    setState(() { _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('MakePDF - Excel to PDF')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(_status, textAlign: TextAlign.center),
            const SizedBox(height: 20),
            _loading? const CircularProgressIndicator() : ElevatedButton.icon(
              icon: const Icon(Icons.upload_file),
              label: const Text('Pick Excel & Convert'),
              onPressed: _pickAndConvert,
              style: ElevatedButton.styleFrom(minimumSize: const Size(200, 50)),
            ),
          ]),
        ),
      ),
    );
  }
}
