import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/widgets.dart';

ImageProvider? resolveImageProvider(String? src) {
  if (src == null) return null;
  final s = src.trim();
  if (s.isEmpty) return null;

  // Data URI (data:[<mediatype>][;base64],<data>)
  if (s.startsWith('data:')) {
    final comma = s.indexOf(',');
    if (comma == -1) return null;
    final meta = s.substring(5, comma);
    final data = s.substring(comma + 1);
    final isBase64 = meta.contains('base64');
    try {
      if (isBase64) {
        final bytes = base64Decode(data);
        return MemoryImage(bytes);
      } else {
        // Fallback: try URL-decode then treat as bytes
        final decoded = Uri.decodeComponent(data);
        final bytes = Uint8List.fromList(decoded.codeUnits);
        return MemoryImage(bytes);
      }
    } catch (_) {
      return null;
    }
  }

  // Normal http/https URL
  if (s.startsWith('http')) return NetworkImage(s);

  // Unknown scheme -> return null
  return null;
}
