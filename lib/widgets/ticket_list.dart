import 'package:flutter/material.dart';
import 'package:tickx/models/ticket.dart';
import 'package:intl/intl.dart';

class TicketList extends StatelessWidget {
  final List<RepairTicket> tickets;
  final RepairTicket? selectedTicket;
  final ValueChanged<RepairTicket> onSelect;

  const TicketList({
    super.key,
    required this.tickets,
    this.selectedTicket,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    if (tickets.isEmpty) return const Center(child: Text("No hay registros"));

    return ListView.builder(
      itemCount: tickets.length,
      itemBuilder: (context, index) {
        final item = tickets[index];
        final isSelected = item.id == selectedTicket?.id;
        final formatter = DateFormat('dd/MM/yyyy HH:mm');

        IconData icon;
        switch (item.deviceType) {
          case DeviceType.laptop:
            icon = Icons.laptop;
            break;
          case DeviceType.desktop:
            icon = Icons.desktop_windows;
            break;
          case DeviceType.phone:
            icon = Icons.phone_android;
            break;
          case DeviceType.tablet:
            icon = Icons.tablet_mac;
            break;
          default:
            icon = Icons.device_unknown;
        }

        return ListTile(
          leading: CircleAvatar(
            backgroundColor: isSelected
                ? Colors.white
                : Colors.blue.withValues(alpha: 0.1),
            child: Icon(icon, color: isSelected ? Colors.blue : null),
          ),
          title: Text(
            item.customerName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            '${item.id} · ${formatter.format(item.dateReceived)}\n${_deviceTypeLabel(item.deviceType)} · ${_statusLabel(item.status)}\nRecibe: ${item.receivedBy}',
            maxLines: 3,
          ),
          isThreeLine: true,
          selected: isSelected,
          selectedTileColor: Colors.blue.withValues(alpha: 0.1),
          onTap: () => onSelect(item),
        );
      },
    );
  }

  String _deviceTypeLabel(DeviceType type) {
    switch (type) {
      case DeviceType.laptop:
        return 'Laptop';
      case DeviceType.desktop:
        return 'Computadora';
      case DeviceType.phone:
        return 'Celular';
      case DeviceType.tablet:
        return 'Tablet';
      case DeviceType.other:
        return 'Otro';
    }
  }

  String _statusLabel(RepairStatus status) {
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
}
