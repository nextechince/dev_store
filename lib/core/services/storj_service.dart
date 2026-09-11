import 'dart:io';
import 'dart:typed_data';
import 'package:minio/minio.dart';
import '../constants/app_constants.dart';

class StorjService {
  // Kept the class name so AppRepository keeps working without edits.
  late Minio _minio;
  int _currentBucketIndex = 0;

  StorjService() {
    _initMinio();
  }

  void _initMinio() {
    _minio = Minio(
      endPoint: 's3.filebase.com',
      accessKey: AppConstants.storjAccessKey, // rename later if you want
      secretKey: '1821AC7D7B6E01E15117',
      useSSL: true,
    );
  }

  String get _currentBucket => AppConstants.storjBuckets[_currentBucketIndex];

  String get _nextBucket {
    _currentBucketIndex =
        (_currentBucketIndex + 1) % AppConstants.storjBuckets.length;
    return AppConstants.storjBuckets[_currentBucketIndex];
  }

  // ---------- UPLOAD ----------
  Future<String> uploadFile({
    required File file,
    required String folder,
    required String fileName,
    String? specificBucket,
  }) async {
    try {
      final bucket = specificBucket ?? _currentBucket;
      final objectPath = '$folder/$fileName';

      final fileLength = await file.length();
      final fileStream =
          file.openRead().map((chunk) => Uint8List.fromList(chunk));
      await _minio.putObject(bucket, objectPath, fileStream, size: fileLength);

      return '$bucket/$objectPath';
    } catch (e) {
      if (specificBucket == null) {
        final fallbackBucket = _nextBucket;
        final objectPath = '$folder/$fileName';

        final fileLength = await file.length();
        final fileStream =
            file.openRead().map((chunk) => Uint8List.fromList(chunk));
        await _minio.putObject(fallbackBucket, objectPath, fileStream,
            size: fileLength);

        return '$fallbackBucket/$objectPath';
      }
      rethrow;
    }
  }

  // ---------- PRESIGNED URL ----------
  Future<String> getPresignedUrl(
    String bucket,
    String objectPath, {
    int expirySeconds = 604800,
  }) async {
    final cleanPath =
        objectPath.startsWith('/') ? objectPath.substring(1) : objectPath;
    return await _minio.presignedGetObject(bucket, cleanPath,
        expires: expirySeconds);
  }

  // ---------- PUBLIC URL (Filebase IPFS gateway) ----------
  String getPublicUrl(String bucket, String objectPath) {
    final cleanPath =
        objectPath.startsWith('/') ? objectPath.substring(1) : objectPath;
    // Filebase IPFS gateway pattern. Works when the bucket is IPFS-enabled.
    return 'https://$bucket.ipfs.filebase.io/ipfs/$cleanPath';
  }

  // ---------- DELETE ----------
  Future<void> deleteFile(String bucket, String objectPath) async {
    final cleanPath =
        objectPath.startsWith('/') ? objectPath.substring(1) : objectPath;
    await _minio.removeObject(bucket, cleanPath);
  }

  // ---------- COPY (for approve flow) ----------
  Future<void> copyFile(
    String bucket,
    String sourcePath,
    String destPath,
  ) async {
    final cleanSource =
        sourcePath.startsWith('/') ? sourcePath.substring(1) : sourcePath;
    final cleanDest =
        destPath.startsWith('/') ? destPath.substring(1) : destPath;

    // MinIO Dart SDK doesn't reliably expose copyObject across versions,
    // so stream download → upload → delete source.
    final stream = await _minio.getObject(bucket, cleanSource);
    final chunks = <int>[];
    await for (final chunk in stream) {
      chunks.addAll(chunk);
    }

    await _minio.putObject(
      bucket,
      cleanDest,
      Stream.value(Uint8List.fromList(chunks)),
      size: chunks.length,
    );

    await _minio.removeObject(bucket, cleanSource);
  }

  // ---------- FILE INFO ----------
  Future<Map<String, dynamic>> getFileInfo(
      String bucket, String objectPath) async {
    final stat = await _minio.statObject(bucket, objectPath);
    return {
      'size': stat.size,
      'lastModified': stat.lastModified,
      'etag': stat.etag,
    };
  }

  // ---------- BUCKET USAGE ----------
  Future<int> getBucketUsage(String bucket) async {
    int totalSize = 0;
    await for (final result in _minio.listObjects(bucket)) {
      for (final object in result.objects) {
        totalSize += object.size ?? 0;
      }
    }
    return totalSize;
  }

  // ---------- PICK AVAILABLE BUCKET ----------
  Future<String> getAvailableBucket() async {
    for (final bucket in AppConstants.storjBuckets) {
      final usage = await getBucketUsage(bucket);
      // Free Filebase tier = 5 GB. Using 4 GB as safe cutoff.
      if (usage < 4 * 1024 * 1024 * 1024) {
        return bucket;
      }
    }
    throw Exception('All buckets are full');
  }
}
