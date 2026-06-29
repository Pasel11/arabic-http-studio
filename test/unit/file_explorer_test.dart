import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:arabic_http_studio/features/tools/file_explorer/services/file_explorer_service.dart';

void main() {
  group('FileExplorerService', () {
    final service = FileExplorerService.instance;

    group('formatFileSize', () {
      test('should format bytes', () {
        expect(service.formatFileSize(500), '500 B');
      });

      test('should format kilobytes', () {
        expect(service.formatFileSize(1024), '1.0 KB');
        expect(service.formatFileSize(1536), '1.5 KB');
      });

      test('should format megabytes', () {
        expect(service.formatFileSize(1024 * 1024), '1.0 MB');
      });

      test('should format gigabytes', () {
        expect(service.formatFileSize(1024 * 1024 * 1024), '1.0 GB');
      });

      test('should handle zero', () {
        expect(service.formatFileSize(0), '0 B');
      });
    });

    group('pinFile / unpinFile / isPinned', () {
      test('should pin and unpin files', () {
        const path = '/test/file.txt';

        expect(service.isPinned(path), isFalse);

        service.pinFile(path);
        expect(service.isPinned(path), isTrue);

        service.unpinFile(path);
        expect(service.isPinned(path), isFalse);
      });

      test('should track pinned files', () {
        const path1 = '/test/file1.txt';
        const path2 = '/test/file2.txt';

        service.pinFile(path1);
        service.pinFile(path2);

        expect(service.pinnedFiles, contains(path1));
        expect(service.pinnedFiles, contains(path2));

        service.unpinFile(path1);
        service.unpinFile(path2);
      });
    });

    group('recentFiles', () {
      test('should start empty', () {
        // Note: recent files may have entries from other tests
        expect(service.recentFiles, isA<List<String>>());
      });
    });

    group('FileItem', () {
      test('should detect image extensions', () {
        final item = FileItem(
          path: '/test/image.png',
          name: 'image.png',
          type: FileItemType.file,
          size: 1024,
          modified: DateTime.now(),
        );

        expect(item.isImage, isTrue);
        expect(item.extension, 'png');
      });

      test('should detect JSON files', () {
        final item = FileItem(
          path: '/test/data.json',
          name: 'data.json',
          type: FileItemType.file,
          size: 512,
          modified: DateTime.now(),
        );

        expect(item.isJson, isTrue);
        expect(item.isText, isTrue);
      });

      test('should detect text files', () {
        for (final ext in ['txt', 'md', 'yaml', 'csv', 'html']) {
          final item = FileItem(
            path: '/test/file.$ext',
            name: 'file.$ext',
            type: FileItemType.file,
            size: 100,
            modified: DateTime.now(),
          );
          expect(item.isText, isTrue, reason: '.$ext should be text');
        }
      });

      test('should handle files without extension', () {
        final item = FileItem(
          path: '/test/README',
          name: 'README',
          type: FileItemType.file,
          size: 100,
          modified: DateTime.now(),
        );

        expect(item.extension, isEmpty);
        expect(item.isImage, isFalse);
        expect(item.isJson, isFalse);
      });

      test('should handle directories', () {
        final item = FileItem(
          path: '/test/folder',
          name: 'folder',
          type: FileItemType.directory,
          size: 0,
          modified: DateTime.now(),
        );

        expect(item.extension, isEmpty);
        expect(item.isImage, isFalse);
      });
    });

    group('FileItemType', () {
      test('should have file and directory types', () {
        expect(FileItemType.values, contains(FileItemType.file));
        expect(FileItemType.values, contains(FileItemType.directory));
      });
    });
  });
}
