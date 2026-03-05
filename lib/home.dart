import 'package:flutter/material.dart';
import 'package:tickx/models/ticket.dart';
import 'package:tickx/data/db.dart';
import 'package:tickx/services/ticket_pdf_service.dart';
import 'package:tickx/widgets/app_notification.dart';
import 'package:tickx/widgets/ticket_list.dart';
import 'package:tickx/widgets/ticket_detail.dart';
import 'package:tickx/widgets/ticket_form.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  RepairTicket? _selectedTicket;
  bool _isEditing = false;
  bool _isCreating = false;
  bool _showArchived = false;
  bool _recientesPrimero = true;

  void _onTicketSelected(RepairTicket ticket) {
    setState(() {
      _selectedTicket = ticket;
      _isEditing = false;
      _isCreating = false;
    });
  }

  void _startCreating() {
    setState(() {
      _selectedTicket = null;
      _isCreating = true;
      _isEditing = false;
    });
  }

  void _saveTicket(RepairTicket ticket) {
    setState(() {
      if (_isCreating) {
        TicketsDatabase.addTicket(ticket);
      } else if (_isEditing) {
        TicketsDatabase.updateTicket(ticket);
      }
      _selectedTicket = ticket;
      _isCreating = false;
      _isEditing = false;
    });
  }

  void _cancelForm() {
    setState(() {
      _isCreating = false;
      _isEditing = false;
      // if it was creating, selected is already null
    });
  }

  void _toggleArchivedMode() {
    setState(() {
      _showArchived = !_showArchived;
      _selectedTicket = null;
      _isCreating = false;
      _isEditing = false;
    });
  }

  void _toggleOrden() {
    setState(() {
      _recientesPrimero = !_recientesPrimero;
    });
  }

  void _changeTicketStatus(RepairStatus newStatus) {
    if (_selectedTicket != null) {
      setState(() {
        _selectedTicket!.status = newStatus;
        TicketsDatabase.updateTicket(_selectedTicket!);
      });
    }
  }

  void _archiveOrUnarchiveTicket() {
    if (_selectedTicket != null) {
      setState(() {
        _selectedTicket!.isArchived = !_selectedTicket!.isArchived;
        TicketsDatabase.updateTicket(_selectedTicket!);
        _selectedTicket = null; // deselect after archiving/unarchiving
      });
    }
  }

  Future<void> _exportSelectedTicketPdf() async {
    if (_selectedTicket == null) {
      return;
    }

    try {
      final path = await TicketPdfService.exportToPdfFile(_selectedTicket!);
      if (!mounted) {
        return;
      }

      if (path == null) {
        AppNotification.show(
          context,
          message: 'Exportación cancelada',
          type: AppNotificationType.warning,
        );
        return;
      }

      AppNotification.show(
        context,
        message: 'PDF guardado en: $path',
        type: AppNotificationType.success,
        duration: const Duration(seconds: 4),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }
      AppNotification.show(
        context,
        message: 'No se pudo exportar PDF: $e',
        type: AppNotificationType.error,
        duration: const Duration(seconds: 5),
      );
    }
  }

  Future<void> _printSelectedTicket() async {
    if (_selectedTicket == null) {
      return;
    }

    try {
      await TicketPdfService.printTicket(_selectedTicket!);
    } catch (e) {
      if (!mounted) {
        return;
      }
      AppNotification.show(
        context,
        message: 'No se pudo imprimir: $e',
        type: AppNotificationType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final baseTickets = _showArchived
        ? TicketsDatabase.archivedTickets
        : TicketsDatabase.activeTickets;
    final ticketsToShow = [...baseTickets]
      ..sort((a, b) {
        final comparison = a.dateReceived.compareTo(b.dateReceived);
        return _recientesPrimero ? -comparison : comparison;
      });

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _showArchived
              ? 'TickX - Equipos Archivados'
              : 'TickX - Equipos Activos',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          TextButton.icon(
            onPressed: _toggleOrden,
            icon: Icon(_recientesPrimero ? Icons.south : Icons.north),
            label: Text(
              _recientesPrimero ? 'Recientes primero' : 'Antiguos primero',
            ),
          ),
          const SizedBox(width: 8),
          TextButton.icon(
            onPressed: _toggleArchivedMode,
            icon: Icon(_showArchived ? Icons.list_alt : Icons.archive),
            label: Text(_showArchived ? 'Ver Activos' : 'Ver Archivados'),
          ),
          const SizedBox(width: 8),
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: FilledButton.icon(
              onPressed: _startCreating,
              icon: const Icon(Icons.add),
              label: const Text('Nuevo Equipo'),
            ),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF7FAFF), Color(0xFFEFF4FF)],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // Left side: List
              Container(
                width: 360,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 12,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: TicketList(
                    tickets: ticketsToShow,
                    selectedTicket: _selectedTicket,
                    onSelect: _onTicketSelected,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              // Right side: Details or Form
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.grey.shade200),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 14,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                  child: _buildRightPanel(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRightPanel() {
    if (_isCreating || _isEditing) {
      return TicketForm(
        ticketToEdit: _isEditing ? _selectedTicket : null,
        onSave: _saveTicket,
        onCancel: _cancelForm,
      );
    }

    if (_selectedTicket == null) {
      return Center(
        child: Text(
          _showArchived
              ? 'Selecciona un equipo archivado'
              : 'Selecciona o registra un equipo',
          style: const TextStyle(fontSize: 18, color: Colors.grey),
        ),
      );
    }

    return TicketDetail(
      ticket: _selectedTicket!,
      onEdit: () => setState(() => _isEditing = true),
      onExportPdf: _exportSelectedTicketPdf,
      onPrint: _printSelectedTicket,
      onStatusChange: _changeTicketStatus,
      onArchive: _archiveOrUnarchiveTicket,
    );
  }
}
