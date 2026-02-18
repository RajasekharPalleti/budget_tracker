import 'dart:typed_data';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';

import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:pdf/pdf.dart';
import '../models/budget.dart';
import '../services/pdf_service.dart';
import '../theme/design_system.dart';

class BudgetPdfPreviewScreen extends StatelessWidget {
  final Budget budget;
  final String currencySymbol;

  const BudgetPdfPreviewScreen({
    super.key,
    required this.budget,
    required this.currencySymbol,
  });

  Future<void> _savePdfToStorage(BuildContext context) async {
    try {
      final bytes = await PdfService.buildPdf(PdfPageFormat.a4, budget, currencySymbol);
      final fileName = '${budget.name.replaceAll(' ', '_')}_report.pdf';
      
      if (kIsWeb) {
         await Printing.sharePdf(bytes: bytes, filename: fileName);
         return;
      }

      Directory? directory;
      if (Platform.isAndroid) {
        // Try to get public Download directory
        directory = Directory('/storage/emulated/0/Download');
        if (!await directory.exists()) {
          directory = await getExternalStorageDirectory();
        }
      } else {
        directory = await getApplicationDocumentsDirectory();
      }

      final file = File('${directory?.path}/$fileName');
      await file.writeAsBytes(bytes);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Saved to ${file.path}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'OPEN',
              textColor: Colors.white,
              onPressed: () => OpenFile.open(file.path),
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving PDF: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _printPdf(BuildContext context) async {
    try {
      await Printing.layoutPdf(
        onLayout: (format) => PdfService.buildPdf(format, budget, currencySymbol),
        name: '${budget.name} Report',
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error printing PDF: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Budget Report', style: TextStyle(color: AppColors.textPrimary,  fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.description_outlined, size: 80, color: AppColors.primary),
              ),
              const SizedBox(height: 24),
              const Text(
                'Report Ready to Export',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textPrimary, fontFamily: 'Inter'),
              ),
              const SizedBox(height: 8),
              const Text(
                'Choose an action below to view your report.',
                style: TextStyle(fontSize: 16, color: AppColors.textSecondary, fontFamily: 'Inter'),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              
              // Download Button
              SizedBox(
                width: 250,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () => _savePdfToStorage(context),
                  icon: const Icon(Icons.download_rounded, color: Colors.white),
                  label: const Text('Download PDF', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Print Button
              SizedBox(
                width: 250,
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: () => _printPdf(context),
                  icon: const Icon(Icons.print_rounded, color: AppColors.primary),
                  label: const Text('Print / Preview', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.primary, width: 2),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
