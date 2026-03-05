import 'dart:io';

import 'package:flutter/material.dart';
import 'package:tickx/models/ticket.dart';
import 'package:intl/intl.dart';

class TicketDetail extends StatelessWidget {
  final RepairTicket ticket;
  final VoidCallback onEdit;
  final VoidCallback onExportPdf;
  final VoidCallback onPrint;
  final Function(RepairStatus) onStatusChange;
  final VoidCallback onArchive;

  const TicketDetail({
    super.key,
    required this.ticket,
    required this.onEdit,
    required this.onExportPdf,
    required this.onPrint,
    required this.onStatusChange,
    required this.onArchive,
  });

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd/MM/yyyy HH:mm');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Ticket: ${ticket.id}',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              // Actions
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.blue),
                tooltip: 'Editar',
                onPressed: onEdit,
              ),
              IconButton(
                icon: const Icon(
                  Icons.picture_as_pdf,
                  color: Colors.deepPurple,
                ),
                tooltip: 'Exportar PDF',
                onPressed: onExportPdf,
              ),
              IconButton(
                icon: const Icon(Icons.print, color: Colors.teal),
                tooltip: 'Imprimir',
                onPressed: onPrint,
              ),
              IconButton(
                icon: const Icon(Icons.archive, color: Colors.red),
                tooltip: ticket.isArchived ? 'Desarchivar' : 'Archivar',
                onPressed: onArchive,
              ),
              const SizedBox(width: 8),
              _buildStatusDropdown(),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Recibido: ${fmt.format(ticket.dateReceived)}',
            style: const TextStyle(color: Colors.grey),
          ),
          const Divider(height: 40),

          // Customer Info
          _SectionTitle('Información del Cliente', icon: Icons.person),
          Card(
            child: ListTile(
              title: Text(
                ticket.customerName,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                'Teléfono: ${ticket.phoneNumber}\nRecibido por: ${ticket.receivedBy}',
              ),
              isThreeLine: true,
              trailing: IconButton(
                icon: const Icon(Icons.phone),
                onPressed: () {},
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Device Info
          _SectionTitle('Información del Dispositivo', icon: Icons.devices),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _InfoCard('Tipo', _deviceTypeLabel(ticket.deviceType)),
              ),
              const SizedBox(width: 16),
              Expanded(child: _InfoCard('Modelo', ticket.deviceModel)),
              const SizedBox(width: 16),
              Expanded(
                child: _InfoCard('Condición Física', ticket.physicalCondition),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _InfoCard(
                  'Problema Reportado (Cliente)',
                  ticket.customerReportedIssue,
                  color: Colors.blue.shade50,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _InfoCard(
                  'Diagnóstico Técnico',
                  ticket.technicianAssessment,
                  color: Colors.green.shade50,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          _SectionTitle('Fotos del equipo', icon: Icons.photo_library),
          _buildImagesSection(),
        ],
      ),
    );
  }

  Widget _buildImagesSection() {
    if (ticket.imagePaths.isEmpty) {
      return Container(
        height: 120,
        width: double.infinity,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
          color: Colors.grey.shade50,
        ),
        child: const Center(child: Text('Sin imágenes adjuntas')),
      );
    }

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: ticket.imagePaths.map((path) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 180,
            height: 140,
            color: Colors.grey.shade100,
            child: Image.file(
              File(path),
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return const Center(child: Icon(Icons.broken_image));
              },
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildStatusDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: _getStatusColor(ticket.status),
        borderRadius: BorderRadius.circular(20),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<RepairStatus>(
          value: ticket.status,
          icon: const Icon(Icons.arrow_drop_down, color: Colors.black87),
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
          onChanged: (val) {
            if (val != null) onStatusChange(val);
          },
          items: RepairStatus.values.map((status) {
            String label = '';
            switch (status) {
              case RepairStatus.received:
                label = 'Recibido';
                break;
              case RepairStatus.inProgress:
                label = 'En Reparación';
                break;
              case RepairStatus.waitingForParts:
                label = 'Esperando Piezas';
                break;
              case RepairStatus.ready:
                label = 'Listo para entregar';
                break;
              case RepairStatus.delivered:
                label = 'Entregado';
                break;
            }
            return DropdownMenuItem(value: status, child: Text(label));
          }).toList(),
        ),
      ),
    );
  }

  Color _getStatusColor(RepairStatus status) {
    switch (status) {
      case RepairStatus.received:
        return Colors.orange.shade200;
      case RepairStatus.inProgress:
        return Colors.blue.shade200;
      case RepairStatus.waitingForParts:
        return Colors.red.shade200;
      case RepairStatus.ready:
        return Colors.green.shade200;
      case RepairStatus.delivered:
        return Colors.grey.shade400;
    }
  }

  String _deviceTypeLabel(DeviceType type) {
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
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final IconData icon;

  const _SectionTitle(this.title, {required this.icon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: Colors.blueGrey),
          const SizedBox(width: 8),
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final String content;
  final Color? color;

  const _InfoCard(this.title, this.content, {this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color ?? Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 8),
          Text(content, style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }
}
