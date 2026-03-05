import 'dart:convert';
import 'dart:io';

import 'package:mime/mime.dart';

class MobileUploadServer {
  HttpServer? _server;
  Directory? _uploadDirectory;

  Future<String> start({
    required void Function(String savedPath) onImageUploaded,
  }) async {
    final ip = await _resolveLocalIp();
    if (ip == null) {
      throw Exception('No se pudo detectar una IP local de red.');
    }

    _uploadDirectory ??= await Directory(
      '${Directory.systemTemp.path}${Platform.pathSeparator}tickx_uploads',
    ).create(recursive: true);

    _server = await HttpServer.bind(InternetAddress.anyIPv4, 0);
    final port = _server!.port;

    _server!.listen((request) async {
      try {
        if (request.method == 'GET' && request.uri.path == '/') {
          _writeHtmlResponse(request.response);
          return;
        }

        if (request.method == 'POST' && request.uri.path == '/upload') {
          final saved = await _handleUpload(request);
          for (final path in saved) {
            onImageUploaded(path);
          }
          request.response
            ..statusCode = HttpStatus.ok
            ..headers.contentType = ContentType.json
            ..write(jsonEncode({'ok': true, 'count': saved.length}));
          await request.response.close();
          return;
        }

        request.response
          ..statusCode = HttpStatus.notFound
          ..write('Ruta no encontrada')
          ..close();
      } catch (_) {
        request.response
          ..statusCode = HttpStatus.internalServerError
          ..write('Error al procesar la solicitud')
          ..close();
      }
    });

    return 'http://$ip:$port';
  }

  Future<void> stop() async {
    await _server?.close(force: true);
    _server = null;
  }

  Future<List<String>> _handleUpload(HttpRequest request) async {
    final contentType = request.headers.contentType;
    final boundary = contentType?.parameters['boundary'];
    if (boundary == null) {
      throw Exception('Carga inválida: no hay boundary.');
    }

    final transformer = MimeMultipartTransformer(boundary);
    final parts = transformer.bind(request);
    final savedPaths = <String>[];

    await for (final part in parts) {
      final dispositionRaw = part.headers['content-disposition'];
      if (dispositionRaw == null) {
        continue;
      }

      final disposition = HeaderValue.parse(dispositionRaw);
      final fileName = disposition.parameters['filename'];
      if (fileName == null || fileName.isEmpty) {
        continue;
      }

      final cleanName = fileName.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
      final outPath =
          '${_uploadDirectory!.path}${Platform.pathSeparator}${DateTime.now().millisecondsSinceEpoch}_$cleanName';
      final outFile = File(outPath);
      final sink = outFile.openWrite();
      await part.pipe(sink);
      await sink.close();

      savedPaths.add(outFile.path);
    }

    return savedPaths;
  }

  void _writeHtmlResponse(HttpResponse response) {
    response
      ..statusCode = HttpStatus.ok
      ..headers.contentType = ContentType.html
      ..write(_pageHtml)
      ..close();
  }

  Future<String?> _resolveLocalIp() async {
    final interfaces = await NetworkInterface.list(
      type: InternetAddressType.IPv4,
      includeLinkLocal: false,
    );

    for (final interface in interfaces) {
      for (final address in interface.addresses) {
        if (!address.isLoopback) {
          return address.address;
        }
      }
    }

    return null;
  }
}

const String _pageHtml = '''
<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>TickX - Subir imágenes</title>
  <style>
    body { font-family: Arial, sans-serif; margin: 0; background: #f6f8fb; color: #1f2937; }
    .wrap { max-width: 520px; margin: 24px auto; padding: 16px; }
    .card { background: #fff; border-radius: 14px; padding: 18px; box-shadow: 0 2px 8px rgba(0,0,0,.08); }
    h1 { font-size: 20px; margin-top: 0; }
    p { color: #4b5563; }
    input, button { width: 100%; font-size: 16px; margin-top: 10px; }
    button { background: #2563eb; color: #fff; border: none; border-radius: 10px; padding: 12px; }
    .ok { margin-top: 12px; color: #166534; font-weight: 600; }
    .err { margin-top: 12px; color: #991b1b; font-weight: 600; }
  </style>
</head>
<body>
  <div class="wrap">
    <div class="card">
      <h1>Subir fotos a TickX</h1>
      <p>Toma fotos o elige imágenes para enviarlas al ticket que estás creando en la PC.</p>
      <input id="files" type="file" accept="image/*" capture="environment" multiple />
      <button id="send">Subir imágenes</button>
      <div id="msg"></div>
    </div>
  </div>
  <script>
    const btn = document.getElementById('send');
    const fileInput = document.getElementById('files');
    const msg = document.getElementById('msg');

    btn.addEventListener('click', async () => {
      if (!fileInput.files || fileInput.files.length === 0) {
        msg.className = 'err';
        msg.textContent = 'Selecciona al menos una imagen.';
        return;
      }

      const fd = new FormData();
      for (const f of fileInput.files) {
        fd.append('files', f, f.name);
      }

      btn.disabled = true;
      btn.textContent = 'Subiendo...';
      msg.textContent = '';

      try {
        const res = await fetch('/upload', { method: 'POST', body: fd });
        if (!res.ok) throw new Error('Error de carga');
        msg.className = 'ok';
        msg.textContent = 'Imágenes subidas correctamente. Puedes volver a tomar más.';
        fileInput.value = '';
      } catch (e) {
        msg.className = 'err';
        msg.textContent = 'No se pudo subir. Verifica que PC y celular estén en la misma red Wi‑Fi.';
      } finally {
        btn.disabled = false;
        btn.textContent = 'Subir imágenes';
      }
    });
  </script>
</body>
</html>
''';
