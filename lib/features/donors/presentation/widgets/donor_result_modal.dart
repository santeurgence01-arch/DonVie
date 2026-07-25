import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:health_emergency/core/theme/app_theme.dart';
import 'package:health_emergency/core/widgets/primary_button.dart';
import 'package:health_emergency/features/donors/data/donor_model.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

/// Modale de résultat après création d'un donneur — §4.4.3.
/// Non fermable par tap extérieur ; se ferme uniquement via "Terminer".
Future<void> showDonorResultModal(
  BuildContext context, {
  required DonorModel donor,
  required String structureName,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (context) => PopScope(
      canPop: false,
      child: _DonorResultDialog(donor: donor, structureName: structureName),
    ),
  );
}

class _DonorResultDialog extends StatelessWidget {
  const _DonorResultDialog({required this.donor, required this.structureName});

  final DonorModel donor;
  final String structureName;

  Future<void> _copy(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: donor.identifiantDon));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ID copié')),
      );
    }
  }

  Future<void> _share() async {
    await SharePlus.instance.share(
      ShareParams(
        text:
            'Bienvenue chez $structureName !\n'
            'Votre identifiant donneur DonVie : ${donor.identifiantDon}\n'
            "Utilisez-le pour installer l'application donneur.",
      ),
    );
  }

  Future<void> _print() async {
    final doc = pw.Document();
    doc.addPage(
      pw.Page(
        build: (context) => pw.Center(
          child: pw.Column(
            mainAxisAlignment: pw.MainAxisAlignment.center,
            children: [
              pw.Text(
                structureName,
                style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 8),
              pw.Text('Fiche donneur — ${donor.nomComplet}'),
              pw.SizedBox(height: 24),
              pw.BarcodeWidget(
                barcode: pw.Barcode.qrCode(),
                data: donor.identifiantDon,
                width: 160,
                height: 160,
              ),
              pw.SizedBox(height: 16),
              pw.Text(
                donor.identifiantDon,
                style: pw.TextStyle(
                  font: pw.Font.courier(),
                  fontSize: 20,
                  letterSpacing: 2,
                ),
              ),
              pw.SizedBox(height: 16),
              pw.Text(
                "Communiquez cet identifiant au donneur pour qu'il installe son application.",
                textAlign: pw.TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
    await Printing.layoutPdf(onLayout: (format) async => doc.save(), format: PdfPageFormat.a5);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 40),
            const SizedBox(height: 12),
            Text(
              'Donneur enregistré avec succès !',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primaryLight, Color(0xFFFDF0EF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(AppRadius.control),
              ),
              child: Text(
                donor.identifiantDon,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "Communiquez cet identifiant au donneur pour qu'il installe son application.",
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _copy(context),
                    icon: const Icon(Icons.copy_rounded, size: 18),
                    label: const Text('Copier'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _share,
                    icon: const Icon(Icons.share_rounded, size: 18),
                    label: const Text('Partager'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _print,
                    icon: const Icon(Icons.print_rounded, size: 18),
                    label: const Text('Imprimer'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            PrimaryButton(
              label: 'Terminer',
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}
