import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sembast/sembast_io.dart';
import 'package:tickx/models/ticket.dart';

class TicketsDatabase {
  static final List<RepairTicket> _tickets = [];
  static Database? _database;
  static final StoreRef<String, Map<String, dynamic>> _store =
      stringMapStoreFactory.store('tickets');

  static Future<void> init() async {
    if (_database != null) {
      return;
    }

    final appDir = await getApplicationSupportDirectory();
    final dbDir = Directory(p.join(appDir.path, 'tickx_data'));
    await dbDir.create(recursive: true);

    final dbPath = p.join(dbDir.path, 'tickx.db');
    _database = await databaseFactoryIo.openDatabase(dbPath);

    final records = await _store.find(_database!);
    _tickets
      ..clear()
      ..addAll(records.map((r) => RepairTicket.fromMap(r.value)));
  }

  static List<RepairTicket> get activeTickets =>
      _tickets.where((t) => !t.isArchived).toList();
  static List<RepairTicket> get archivedTickets =>
      _tickets.where((t) => t.isArchived).toList();

  static Future<void> addTicket(RepairTicket ticket) async {
    await init();
    _tickets.insert(0, ticket);
    await _store.record(ticket.id).put(_database!, ticket.toMap());
  }

  static Future<void> updateTicket(RepairTicket ticket) async {
    await init();
    var index = _tickets.indexWhere((t) => t.id == ticket.id);
    if (index != -1) {
      _tickets[index] = ticket;
    }
    await _store.record(ticket.id).put(_database!, ticket.toMap());
  }

  static Future<void> archiveTicket(String id) async {
    await init();
    var index = _tickets.indexWhere((t) => t.id == id);
    if (index != -1) {
      _tickets[index].isArchived = true;
      await _store.record(id).put(_database!, _tickets[index].toMap());
    }
  }

  static Future<void> deleteTicket(String id) async {
    await init();
    _tickets.removeWhere((t) => t.id == id);
    await _store.record(id).delete(_database!);
  }
}
