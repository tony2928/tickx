import 'dart:io';
import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:tickx/models/ticket.dart';

class TicketPdfService {
  static Future<Uint8List> buildPdfBytes(RepairTicket ticket) async {
    final pdf = pw.Document();
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    final images = <pw.MemoryImage>[];
    for (final path in ticket.imagePaths) {
      final file = File(path);
      if (await file.exists()) {
        final bytes = await file.readAsBytes();
        images.add(pw.MemoryImage(bytes));
      }
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (context) => [
          pw.Text(
            'TickX - Reporte de recepción de equipo',
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 6),
          pw.Text('Ticket: ${ticket.id}'),
          pw.Text(
            'Fecha de recepción: ${dateFormat.format(ticket.dateReceived)}',
          ),
          pw.SizedBox(height: 12),
          _sectionTitle('Datos del cliente'),
          _kv('Nombre', ticket.customerName),
          _kv('Teléfono', ticket.phoneNumber),
          _kv('Recibido por', ticket.receivedBy),
          pw.SizedBox(height: 10),
          _sectionTitle('Datos del dispositivo'),
          _kv('Tipo', _deviceTypeLabel(ticket.deviceType)),
          _kv('Modelo', ticket.deviceModel),
          _kv('Estado del ticket', _statusLabel(ticket.status)),
          pw.SizedBox(height: 10),
          _sectionTitle('Observaciones'),
          _paragraph(
            'Problema reportado por cliente',
            ticket.customerReportedIssue,
          ),
          _paragraph('Condición física', ticket.physicalCondition),
          _paragraph('Diagnóstico técnico', ticket.technicianAssessment),
          if (images.isNotEmpty) ...[
            pw.SizedBox(height: 12),
            _sectionTitle('Imágenes adjuntas'),
            pw.Wrap(
              spacing: 8,
              runSpacing: 8,
              children: images
                  .map(
                    (img) => pw.Container(
                      width: 160,
                      height: 110,
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: PdfColors.grey300),
                        borderRadius: pw.BorderRadius.circular(6),
                      ),
                      child: pw.ClipRRect(
                        horizontalRadius: 6,
                        verticalRadius: 6,
                        child: pw.Image(img, fit: pw.BoxFit.cover),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );

    return pdf.save();
  }

  static Future<String?> exportToPdfFile(RepairTicket ticket) async {
    final defaultPath = _defaultExportPath(ticket.id);
    final defaultFile = File(defaultPath);

    final location = await getSaveLocation(
      suggestedName: defaultFile.uri.pathSegments.last,
      initialDirectory: defaultFile.parent.path,
      confirmButtonText: 'Guardar PDF',
      acceptedTypeGroups: const [
        XTypeGroup(label: 'PDF', extensions: ['pdf']),
      ],
    );

    if (location == null) {
      return null;
    }

    final savePath = location.path;
    final bytes = await buildPdfBytes(ticket);
    final file = File(savePath);
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }

  static Future<void> printTicket(RepairTicket ticket) async {
    final bytes = await buildPdfBytes(ticket);
    await Printing.layoutPdf(
      name: 'ticket_${ticket.id}.pdf',
      onLayout: (format) async => bytes,
    );
  }

  static pw.Widget _sectionTitle(String text) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      color: PdfColors.blue100,
      child: pw.Text(text, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
    );
  }

  static pw.Widget _kv(String key, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(top: 4),
      child: pw.RichText(
        text: pw.TextSpan(
          children: [
            pw.TextSpan(
              text: '$key: ',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
            pw.TextSpan(text: value),
          ],
        ),
      ),
    );
  }

  static pw.Widget _paragraph(String title, String content) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(top: 8),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(title, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 2),
          pw.Text(content),
        ],
      ),
    );
  }

  static String _statusLabel(RepairStatus status) {
    switch (status) {
      case RepairStatus.received:
        return 'Recibido';
      case RepairStatus.inProgress:
        return 'En reparación';
      case RepairStatus.waitingForParts:
        return 'Esperando piezas';
      case RepairStatus.ready:
        return 'Listo para entregar';
      case RepairStatus.delivered:
        return 'Entregado';
    }
  }

  static String _deviceTypeLabel(DeviceType type) {
    switch (type) {
      case DeviceType.laptop:
        return 'Laptop';
      case DeviceType.desktop:
        return 'Computadora de escritorio';
      case DeviceType.phone:
        return 'Celular';
      case DeviceType.tablet:
        return 'Tablet';
      case DeviceType.other:
        return 'Otro';
    }
  }

  static String _defaultExportPath(String ticketId) {
    final userProfile = Platform.environment['USERPROFILE'];
    final home = Platform.environment['HOME'];
    final base = userProfile ?? home ?? Directory.current.path;
    final exportDir = Directory(
      '$base${Platform.pathSeparator}Downloads${Platform.pathSeparator}TickX',
    );
    final fileName =
        'ticket_${ticketId}_${DateTime.now().millisecondsSinceEpoch}.pdf';
    return '${exportDir.path}${Platform.pathSeparator}$fileName';
  }
}
