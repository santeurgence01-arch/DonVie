import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health_emergency/core/constants/app_constants.dart';
import 'package:health_emergency/core/theme/app_theme.dart';
import 'package:health_emergency/features/onboarding/application/onboarding_providers.dart';

const _maxFileSizeBytes = 10 * 1024 * 1024;
const _allowedExtensions = ['pdf', 'jpg', 'jpeg', 'png'];

String _formatSize(int bytes) {
  if (bytes < 1024) return '$bytes o';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} Ko';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} Mo';
}

IconData _iconForType(String contentType) {
  if (contentType.contains('pdf')) return Icons.picture_as_pdf_outlined;
  return Icons.image_outlined;
}

class Step2Documents extends ConsumerWidget {
  const Step2Documents({super.key});

  Future<void> _pickFiles(BuildContext context, WidgetRef ref) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: _allowedExtensions,
      allowMultiple: true,
      withData: true,
    );
    if (result == null) return;

    final oversized = result.files.where((f) => f.size > _maxFileSizeBytes);
    if (oversized.isNotEmpty && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${oversized.length} fichier(s) dépassent 10 Mo et ont été ignorés.',
          ),
        ),
      );
    }

    final files = result.files
        .where((f) => f.size <= _maxFileSizeBytes && f.bytes != null)
        .map(
          (f) => (
            fileName: f.name,
            bytes: f.bytes!,
            contentType: _contentTypeFor(f.extension),
          ),
        )
        .toList();

    if (files.isNotEmpty) {
      await ref.read(onboardingControllerProvider.notifier).addFiles(files);
    }
  }

  String _contentTypeFor(String? extension) {
    switch (extension?.toLowerCase()) {
      case 'pdf':
        return 'application/pdf';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      default:
        return 'application/octet-stream';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingControllerProvider);
    final controller = ref.read(onboardingControllerProvider.notifier);
    final isMobile = MediaQuery.sizeOf(context).width < kMobileBreakpoint;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          onTap: () => _pickFiles(context, ref),
          borderRadius: BorderRadius.circular(AppRadius.card),
          child: DottedBorderBox(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Column(
                children: [
                  const Icon(
                    Icons.upload_file_outlined,
                    size: 32,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    isMobile
                        ? 'Sélectionner des fichiers'
                        : 'Glissez vos fichiers ici ou cliquez pour parcourir',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'PDF, JPG, PNG — 10 Mo max par fichier',
          style: Theme.of(context).textTheme.labelLarge,
        ),
        if (state.showStep2Errors && state.documents.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text(
              'Au moins un document est requis.',
              style: TextStyle(color: AppColors.danger, fontSize: 12),
            ),
          ),
        if (state.documents.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sectionGap),
          for (final doc in state.documents)
            _DocumentRow(
              document: doc,
              onRetry: () => controller.retryUpload(doc.id),
              onDelete: () => controller.removeDocument(doc.id),
            ),
        ],
      ],
    );
  }
}

class _DocumentRow extends StatelessWidget {
  const _DocumentRow({
    required this.document,
    required this.onRetry,
    required this.onDelete,
  });

  final OnboardingDocument document;
  final VoidCallback onRetry;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.control),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(_iconForType(document.contentType), color: AppColors.textSecondary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        document.fileName,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatSize(document.size),
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                  ],
                ),
                if (document.status == DocumentUploadStatus.uploading) ...[
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: document.progress > 0 ? document.progress : null,
                      minHeight: 4,
                      backgroundColor: AppColors.border,
                    ),
                  ),
                ],
                if (document.status == DocumentUploadStatus.error) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.error_outline_rounded,
                        color: AppColors.danger,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'Échec de l\'upload',
                        style: TextStyle(color: AppColors.danger, fontSize: 12),
                      ),
                      TextButton(
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        onPressed: onRetry,
                        child: const Text('Réessayer'),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          if (document.status == DocumentUploadStatus.success)
            IconButton(
              icon: const Icon(Icons.close, size: 18),
              onPressed: onDelete,
            ),
        ],
      ),
    );
  }
}

/// Bordure en pointillés simple pour la zone de dépôt de documents.
class DottedBorderBox extends StatelessWidget {
  const DottedBorderBox({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedBorderPainter(),
      child: child,
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.border
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(AppRadius.card),
    );
    final path = Path()..addRRect(rrect);
    final dashPath = Path();
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        const dashLength = 6.0;
        const gapLength = 4.0;
        dashPath.addPath(
          metric.extractPath(distance, distance + dashLength),
          Offset.zero,
        );
        distance += dashLength + gapLength;
      }
    }
    canvas.drawPath(dashPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
