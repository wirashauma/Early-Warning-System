import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';

class SseEvent {
  final String? id;
  final String? event;
  final String data;

  SseEvent({this.id, this.event, required this.data});

  @override
  String toString() => 'SseEvent(id: $id, event: $event, data: $data)';
}

class SseClient {
  final String url;
  final Map<String, String>? headers;

  StreamController<SseEvent>? _controller;
  HttpClient? _client;
  bool _isConnecting = false;
  bool _shouldReconnect = true;
  Timer? _reconnectTimer;
  final Duration _reconnectDelay = const Duration(seconds: 5);

  Stream<SseEvent> get stream {
    _controller ??= StreamController<SseEvent>.broadcast(
      onListen: _start,
      onCancel: _stop,
    );
    return _controller!.stream;
  }

  SseClient(this.url, {this.headers});

  void _start() {
    _shouldReconnect = true;
    _connect();
  }

  void _stop() {
    _shouldReconnect = false;
    _reconnectTimer?.cancel();
    _client?.close(force: true);
    _controller?.close();
    _controller = null;
  }

  Future<void> _connect() async {
    if (_isConnecting) return;
    _isConnecting = true;

    try {
      _client = HttpClient();
      _client!.connectionTimeout = const Duration(seconds: 10);

      final request = await _client!.getUrl(Uri.parse(url));
      headers?.forEach((key, value) {
        request.headers.set(key, value);
      });
      request.headers.set('Accept', 'text/event-stream');
      request.headers.set('Cache-Control', 'no-cache');

      final response = await request.close();
      _isConnecting = false;

      if (response.statusCode == 200) {
        debugPrint('⚡ [SSE] Connected successfully to $url');

        String? currentId;
        String? currentEvent;
        final buffer = StringBuffer();

        await for (final chunk in response.transform(utf8.decoder).transform(const LineSplitter())) {
          final line = chunk.trim();
          if (line.isEmpty) {
            // Empty line indicates end of event
            if (buffer.isNotEmpty) {
              _controller?.add(SseEvent(
                id: currentId,
                event: currentEvent,
                data: buffer.toString(),
              ));
              buffer.clear();
              currentEvent = null;
            }
            continue;
          }

          if (line.startsWith('id:')) {
            currentId = line.substring(3).trim();
          } else if (line.startsWith('event:')) {
            currentEvent = line.substring(6).trim();
          } else if (line.startsWith('data:')) {
            buffer.write(line.substring(5).trim());
          }
        }
      } else {
        throw HttpException('Server returned status code ${response.statusCode}');
      }
    } catch (e) {
      _isConnecting = false;
      debugPrint('❌ [SSE] Connection error on $url: $e');
      if (_shouldReconnect) {
        _scheduleReconnect();
      }
    }
  }

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    debugPrint('🔄 [SSE] Scheduling reconnect in ${_reconnectDelay.inSeconds}s...');
    _reconnectTimer = Timer(_reconnectDelay, () {
      if (_shouldReconnect) {
        _connect();
      }
    });
  }

  void close() {
    _stop();
  }
}
