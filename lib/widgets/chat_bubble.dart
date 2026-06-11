import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

/// Extracts the filename from an export path string.
///
/// Handles both "./storage/exports/abstract_42.tex" and "abstract_42.tex".
String _filenameFromExportPath(String exportPath) {
  final uri = Uri.tryParse(exportPath);
  if (uri != null && uri.pathSegments.isNotEmpty) {
    return uri.pathSegments.last;
  }
  // Fallback: just use the last segment after '/'
  final segments = exportPath.split('/');
  return segments.last;
}

class ChatBubble extends StatelessWidget {
  final String message;
  final bool isUser;
  final bool isLoading;
  final String? exportPath;

  const ChatBubble({
    super.key,
    required this.message,
    required this.isUser,
    this.isLoading = false,
    this.exportPath,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isUser ? const Color(0xFF0A84FF) : const Color(0xFF2C2C2E),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isLoading)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildDot(0),
                  const SizedBox(width: 4),
                  _buildDot(1),
                  const SizedBox(width: 4),
                  _buildDot(2),
                ],
              )
            else ...[
              Text(
                message,
                style: const TextStyle(
                  fontSize: 15,
                  color: Colors.white,
                ),
              ),
              if (exportPath != null && exportPath!.isNotEmpty) ...[
                const SizedBox(height: 8),
                _ExportFileTile(exportPath: exportPath!),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDot(int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      builder: (context, value, child) {
        return Opacity(
          opacity: (value + index * 0.3) % 1.0,
          child: Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Colors.white54,
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }
}

class _ExportFileTile extends StatelessWidget {
  final String exportPath;

  const _ExportFileTile({required this.exportPath});

  String get _filename => _filenameFromExportPath(exportPath);

  /// Use the file extension to pick an icon.
  IconData _fileIcon() {
    final ext = _filename.split('.').last.toLowerCase();
    switch (ext) {
      case 'tex':
        return Icons.description;
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'docx':
        return Icons.article;
      case 'pptx':
        return Icons.slideshow;
      default:
        return Icons.insert_drive_file;
    }
  }

  @override
  Widget build(BuildContext context) {
    final api = context.read<AuthService>().api;
    final downloadUrl = api.getExportFileUrl(_filename);

    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () => _downloadAndOpen(context, api, downloadUrl),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_fileIcon(), size: 18, color: const Color(0xFF0A84FF)),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                _filename,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF0A84FF),
                  decoration: TextDecoration.underline,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.open_in_new,
              size: 14,
              color: Color(0xFF0A84FF),
            ),
          ],
        ),
      ),
    );
  }

  /// Downloads the file via the authenticated API and opens it with the system handler.
  Future<void> _downloadAndOpen(
    BuildContext context,
    ApiService api,
    String url,
  ) async {
    try {
      // Загружаем файл через dio (с авторизацией) во временную директорию
      final dir = Directory.systemTemp.createTempSync('raf_export_');
      final filePath = '${dir.path}/$_filename';

      await api.downloadFile(url, filePath);

      // Пытаемся открыть файл через системный обработчик
      if (Platform.isAndroid || Platform.isIOS) {
        // На мобильных устройствах показываем SnackBar с уведомлением,
        // так как открытие произвольных файлов требует дополнительных пакетов
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Файл сохранён: $_filename'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else if (Platform.isLinux || Platform.isMacOS) {
        await Process.run('xdg-open', [filePath]);
      } else if (Platform.isWindows) {
        await Process.run('cmd', ['/c', 'start', '', filePath]);
      }
    } catch (e) {
      // Fallback: открываем URL в браузере (может не сработать без токена)
      debugPrint('Failed to open export file: $e');
      try {
        if (Platform.isLinux || Platform.isMacOS) {
          await Process.run('xdg-open', [url]);
        } else if (Platform.isWindows) {
          await Process.run('cmd', ['/c', 'start', '', url]);
        }
      } catch (_) {}
    }
  }
}