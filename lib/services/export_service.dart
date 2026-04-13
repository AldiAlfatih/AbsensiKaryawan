import 'dart:io';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/app_settings.dart';
import '../models/app_user.dart';

class ExportService {
  static Future<void> exportEmployeeRecap(List<AppUser> employees, AppSettings settings) async {
    List<List<dynamic>> rows = [];
    
    // Header
    rows.add(['NIK', 'Nama Karyawan', 'Email', 'Total Poin', 'Estimasi Gaji (Rp)']);

    // Data
    for (var emp in employees) {
      final int rupiah = emp.totalPoints * settings.pointValue;
      rows.add([
        emp.nik.isEmpty ? '-' : emp.nik,
        emp.name,
        emp.email,
        emp.totalPoints,
        rupiah
      ]);
    }

    // Convert to CSV
    String csv = const ListToCsvConverter().convert(rows);

    // Save to temp doc dir
    final dir = await getApplicationDocumentsDirectory();
    final fileName = 'GAPS_Payroll_Recap_${DateTime.now().millisecondsSinceEpoch}.csv';
    final file = File('${dir.path}/$fileName');
    
    await file.writeAsString(csv);
    
    // Share / Save via system
    await Share.shareXFiles([XFile(file.path)], text: 'Laporan Rekap Poin dan Gaji Karyawan GAPS');
  }
}
