import 'dart:io';

import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:tickx/services/mobile_upload_server.dart';
import 'package:tickx/models/ticket.dart';
import 'package:tickx/widgets/app_notification.dart';

class TicketForm extends StatefulWidget {
  final RepairTicket? ticketToEdit;
  final Function(RepairTicket) onSave;
  final VoidCallback onCancel;

  const TicketForm({
    super.key,
    this.ticketToEdit,
    required this.onSave,
    required this.onCancel,
  });

  @override
  State<TicketForm> createState() => _TicketFormState();
}

class _TicketFormState extends State<TicketForm> {
  final _formKey = GlobalKey<FormState>();

  late String _name;
  late String _receivedBy;
  late String _phone;
  late DeviceType _deviceType;
  late String _deviceModel;
  late String _issue;
  late String _condition;
  late String _assessment;
  late List<String> _imagePaths;
  bool _dragging = false;
  MobileUploadServer? _mobileUploadServer;
  String? _mobileUploadUrl;
  bool _startingMobileServer = false;
  String? _mobileServerError;

  @override
  void initState() {
    super.initState();
    final t = widget.ticketToEdit;
    _name = t?.customerName ?? '';
    _receivedBy = t?.receivedBy ?? '';
    _phone = t?.phoneNumber ?? '';
    _deviceType = t?.deviceType ?? DeviceType.laptop;
    _deviceModel = t?.deviceModel ?? '';
    _issue = t?.customerReportedIssue ?? '';
    _condition = t?.physicalCondition ?? '';
    _assessment = t?.technicianAssessment ?? '';
    _imagePaths = List<String>.from(t?.imagePaths ?? []);

    if (widget.ticketToEdit == null) {
      _startMobileUploadServer();
    }
  }

  @override
  void dispose() {
    _mobileUploadServer?.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isEditing = widget.ticketToEdit != null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isEditing ? 'Editar Registro' : 'Nuevo Registro de Equipo',
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            _buildSectionTitle('Datos del Cliente'),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    'Nombre del Cliente',
                    _name,
                    (v) => _name = v,
                    Icons.person,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTextField(
                    'Teléfono',
                    _phone,
                    (v) => _phone = v,
                    Icons.phone,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildTextField(
              'Quién recibe el dispositivo',
              _receivedBy,
              (v) => _receivedBy = v,
              Icons.badge,
            ),
            const SizedBox(height: 16),
            _buildSectionTitle('Dispositivo del cliente'),
            _buildInputContainer(
              child: DropdownButtonFormField<DeviceType>(
                decoration: const InputDecoration(
                  labelText: 'Tipo de Dispositivo',
                  prefixIcon: Icon(Icons.devices),
                ),
                initialValue: _deviceType,
                borderRadius: BorderRadius.circular(14),
                dropdownColor: Colors.white,
                items: DeviceType.values
                    .map(
                      (v) => DropdownMenuItem(
                        value: v,
                        child: Text(_deviceTypeLabel(v)),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _deviceType = v!),
              ),
            ),
            const SizedBox(height: 16),
            _buildTextField(
              'Modelo del dispositivo',
              _deviceModel,
              (v) => _deviceModel = v,
              Icons.memory,
            ),
            const SizedBox(height: 24),
            _buildTextField(
              'Problema Reportado (Cliente)',
              _issue,
              (v) => _issue = v,
              Icons.report_problem,
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            _buildSectionTitle('Estado Físico / Accesorios'),
            _buildTextField(
              'Ej: Bisagras rotas, cargador incluido, sin batería',
              _condition,
              (v) => _condition = v,
              Icons.visibility,
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            _buildSectionTitle('Diagnóstico Previo (Técnico)'),
            _buildTextField(
              'Problemas que vemos al recibir',
              _assessment,
              (v) => _assessment = v,
              Icons.build,
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            _buildSectionTitle('Imágenes del equipo'),
            if (widget.ticketToEdit == null) ...[
              _buildMobileUploadPanel(),
              const SizedBox(height: 12),
            ],
            _buildImageArea(),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton.icon(
                onPressed: _pickImages,
                icon: const Icon(Icons.add_photo_alternate),
                label: const Text('Seleccionar imágenes'),
              ),
            ),
            const SizedBox(height: 12),
            if (_imagePaths.isNotEmpty) _buildReorderableImageList(),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: widget.onCancel,
                  icon: const Icon(Icons.cancel),
                  label: const Text('Cancelar'),
                ),
                const SizedBox(width: 16),
                FilledButton.icon(
                  onPressed: _save,
                  icon: const Icon(Icons.save),
                  label: Text(isEditing ? 'Guardar Cambios' : 'Crear Registro'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileUploadPanel() {
    if (_startingMobileServer) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.blue.shade200),
        ),
        child: const Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text('Iniciando servidor para carga desde celular...'),
            ),
          ],
        ),
      );
    }

    if (_mobileServerError != null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'No se pudo activar carga móvil: $_mobileServerError',
              style: TextStyle(color: Colors.red.shade900),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _startMobileUploadServer,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (_mobileUploadUrl == null) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Subir desde celular (misma Wi‑Fi)',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          const Text(
            'Escanea este QR para abrir la página y tomar/subir fotos directo al ticket.',
          ),
          const SizedBox(height: 12),
          Center(
            child: QrImageView(
              data: _mobileUploadUrl!,
              size: 180,
              backgroundColor: Colors.white,
            ),
          ),
          const SizedBox(height: 10),
          SelectableText(_mobileUploadUrl!),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton.icon(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: _mobileUploadUrl!));
                if (mounted) {
                  AppNotification.show(
                    context,
                    message: 'Enlace copiado',
                    type: AppNotificationType.info,
                  );
                }
              },
              icon: const Icon(Icons.copy),
              label: const Text('Copiar enlace'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageArea() {
    return DropTarget(
      onDragEntered: (_) => setState(() => _dragging = true),
      onDragExited: (_) => setState(() => _dragging = false),
      onDragDone: (detail) {
        setState(() => _dragging = false);
        final paths = detail.files.map((f) => f.path).toList();
        _addImages(paths);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _dragging ? Colors.blue.shade50 : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _dragging ? Colors.blue : Colors.grey.shade300,
            width: _dragging ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              Icons.cloud_upload,
              size: 32,
              color: _dragging ? Colors.blue : Colors.grey,
            ),
            const SizedBox(height: 8),
            Text(
              'Arrastra imágenes aquí',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: _dragging ? Colors.blue : Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'También puedes usar el botón "Seleccionar imágenes"',
              style: TextStyle(color: Colors.grey.shade700),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReorderableImageList() {
    return SizedBox(
      height: 220,
      child: ReorderableListView.builder(
        itemCount: _imagePaths.length,
        onReorder: (oldIndex, newIndex) {
          setState(() {
            if (newIndex > oldIndex) {
              newIndex -= 1;
            }
            final item = _imagePaths.removeAt(oldIndex);
            _imagePaths.insert(newIndex, item);
          });
        },
        itemBuilder: (context, index) {
          final path = _imagePaths[index];
          return Card(
            key: ValueKey('$path-$index'),
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  File(path),
                  width: 56,
                  height: 56,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 56,
                      height: 56,
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.broken_image),
                    );
                  },
                ),
              ),
              title: Text(
                path.split('\\').last,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text('Posición ${index + 1}'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.drag_handle),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _imagePaths.removeAt(index);
                      });
                    },
                    icon: const Icon(Icons.delete_outline),
                    tooltip: 'Quitar',
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 16,
          color: Colors.blueAccent,
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label,
    String initialValue,
    Function(String) onSave,
    IconData icon, {
    int maxLines = 1,
  }) {
    return _buildInputContainer(
      child: TextFormField(
        initialValue: initialValue,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          alignLabelWithHint: maxLines > 1,
        ),
        maxLines: maxLines,
        validator: (v) => v!.isEmpty ? 'Requerido' : null,
        onSaved: (v) => onSave(v!),
      ),
    );
  }

  Widget _buildInputContainer({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );
  }

  Future<void> _pickImages() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: const ['jpg', 'jpeg', 'png', 'webp'],
    );

    if (result == null || result.files.isEmpty) {
      return;
    }

    final selected = result.paths.whereType<String>().toList();
    _addImages(selected);
  }

  void _addImages(List<String> newPaths) {
    setState(() {
      for (final path in newPaths) {
        if (!_imagePaths.contains(path)) {
          _imagePaths.add(path);
        }
      }
    });
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

  Future<void> _startMobileUploadServer() async {
    setState(() {
      _startingMobileServer = true;
      _mobileServerError = null;
    });

    try {
      await _mobileUploadServer?.stop();
      final server = MobileUploadServer();
      final url = await server.start(
        onImageUploaded: (savedPath) {
          if (!mounted) {
            return;
          }
          setState(() {
            if (!_imagePaths.contains(savedPath)) {
              _imagePaths.add(savedPath);
            }
          });
        },
      );

      if (!mounted) {
        await server.stop();
        return;
      }

      setState(() {
        _mobileUploadServer = server;
        _mobileUploadUrl = url;
        _startingMobileServer = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _mobileServerError = e.toString();
        _startingMobileServer = false;
      });
    }
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      RepairTicket ticket;
      if (widget.ticketToEdit != null) {
        ticket = widget.ticketToEdit!;
        ticket.customerName = _name;
        ticket.receivedBy = _receivedBy;
        ticket.phoneNumber = _phone;
        ticket.deviceType = _deviceType;
        ticket.deviceModel = _deviceModel;
        ticket.customerReportedIssue = _issue;
        ticket.physicalCondition = _condition;
        ticket.technicianAssessment = _assessment;
        ticket.imagePaths = List<String>.from(_imagePaths);
      } else {
        ticket = RepairTicket(
          id: 'TX-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
          customerName: _name,
          receivedBy: _receivedBy,
          phoneNumber: _phone,
          deviceType: _deviceType,
          deviceModel: _deviceModel,
          customerReportedIssue: _issue,
          physicalCondition: _condition,
          technicianAssessment: _assessment,
          imagePaths: List<String>.from(_imagePaths),
          dateReceived: DateTime.now(),
        );
      }
      widget.onSave(ticket);
    }
  }
}
