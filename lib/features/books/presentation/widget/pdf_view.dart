// lib/features/books/presentation/widgets/pdf_viewer_widget.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';

class PdfViewerWidget extends StatelessWidget {
  final File pdfFile;
  final int currentPage;
  final int totalPages;
  final void Function(int?, int?)? onPageChanged;
  final void Function(int?)? onRender;
  final void Function(dynamic)? onError;
  final PageErrorCallback? onPageError;
  final void Function(PDFViewController)? onViewCreated;

  const PdfViewerWidget({
    super.key,
    required this.pdfFile,
    required this.currentPage,
    required this.totalPages,
    required this.onPageChanged,
    required this.onRender,
    required this.onError,
    required this.onPageError,
    required this.onViewCreated,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (totalPages > 0) _buildProgressIndicator(context),
        Expanded(
          child: PDFView(
            filePath: pdfFile.path,
            enableSwipe: true,
            swipeHorizontal: false,
            autoSpacing: false,
            pageFling: true,
            pageSnap: true,
            defaultPage: 0,
            fitPolicy: FitPolicy.BOTH,
            preventLinkNavigation: false,
            onRender: onRender,
            onError: onError,
            onPageError: onPageError,
            onViewCreated: onViewCreated,
            onPageChanged: onPageChanged,
            onLinkHandler: (String? uri) {
              debugPrint('Link: $uri');
            },
          ),
        ),
      ],
    );
  }

  Widget _buildProgressIndicator(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 8,
      ),
      color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Page ${currentPage + 1} of $totalPages',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 16),
              child: LinearProgressIndicator(
                value: totalPages > 0 ? (currentPage + 1) / totalPages : 0,
                backgroundColor: Colors.grey.shade300,
                minHeight: 3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}