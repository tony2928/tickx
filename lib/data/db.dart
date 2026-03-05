import 'package:tickx/models/ticket.dart';

class TicketsDatabase {
  static final List<RepairTicket> _tickets = [];

  static List<RepairTicket> get activeTickets =>
      _tickets.where((t) => !t.isArchived).toList();
  static List<RepairTicket> get archivedTickets =>
      _tickets.where((t) => t.isArchived).toList();

  static void addTicket(RepairTicket ticket) {
    _tickets.insert(0, ticket);
  }

  static void updateTicket(RepairTicket ticket) {
    var index = _tickets.indexWhere((t) => t.id == ticket.id);
    if (index != -1) {
      _tickets[index] = ticket;
    }
  }

  static void archiveTicket(String id) {
    var index = _tickets.indexWhere((t) => t.id == id);
    if (index != -1) {
      _tickets[index].isArchived = true;
    }
  }

  static void deleteTicket(String id) {
    _tickets.removeWhere((t) => t.id == id);
  }
}
