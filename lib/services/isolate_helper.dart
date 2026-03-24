import 'dart:async';
import 'package:flutter/foundation.dart' show compute;
import 'package:flutter/material.dart';
class IsolateHelper {
  static Future<T> computeInBackground<T, P>(
    FutureOr<T> Function(P) computation,
    P parameter, {
    String? debugLabel,
  }) async {
    try {
      debugPrint(
        '[IsolateHelper] Starting background computation${debugLabel != null ? ': $debugLabel' : ''}',
      );
      final result = await compute(computation, parameter);
      debugPrint('[IsolateHelper] Background computation completed');
      return result;
    } catch (e) {
      debugPrint('[IsolateHelper] Error in background computation: $e');
      rethrow;
    }
  }
  static Future<List<T>> computeSequenceInBackground<T, P>(
    List<(FutureOr<T> Function(P), P)> computations, {
    String? debugLabel,
  }) async {
    try {
      debugPrint(
        '[IsolateHelper] Starting sequential background computations${debugLabel != null ? ': $debugLabel' : ''}',
      );
      final results = <T>[];
      for (var i = 0; i < computations.length; i++) {
        final (computation, parameter) = computations[i];
        debugPrint(
          '[IsolateHelper] Running computation ${i + 1}/${computations.length}',
        );
        final result = await compute(computation, parameter);
        results.add(result);
      }
      debugPrint('[IsolateHelper] All sequential computations completed');
      return results;
    } catch (e) {
      debugPrint('[IsolateHelper] Error in sequential computations: $e');
      rethrow;
    }
  }
  static Future<T> computeWithTimeout<T, P>(
    FutureOr<T> Function(P) computation,
    P parameter, {
    Duration timeout = const Duration(seconds: 30),
    String? debugLabel,
    T Function()? onTimeout,
  }) async {
    try {
      debugPrint(
        '[IsolateHelper] Starting computation with ${timeout.inSeconds}s timeout${debugLabel != null ? ': $debugLabel' : ''}',
      );
      final future = compute(computation, parameter);
      return await future.timeout(
        timeout,
        onTimeout: onTimeout != null
            ? () {
                debugPrint('[IsolateHelper] Computation exceeded timeout');
                return onTimeout();
              }
            : null,
      );
    } catch (e) {
      debugPrint('[IsolateHelper] Error in computation with timeout: $e');
      rethrow;
    }
  }
}
class PDFAnalysisData {
  final String filePath;
  final List<int> fileBytes;
  PDFAnalysisData({required this.filePath, required this.fileBytes});
}
class PDFRepairData {
  final String inputPath;
  final String outputPath;
  final List<int> fileBytes;
  PDFRepairData({
    required this.inputPath,
    required this.outputPath,
    required this.fileBytes,
  });
}
class PDFTextRecoveryData {
  final String filePath;
  final List<int> fileBytes;
  PDFTextRecoveryData({required this.filePath, required this.fileBytes});
}
class IsolateResult<T> {
  final bool success;
  final T? data;
  final String? error;
  final DateTime timestamp;
  IsolateResult({
    required this.success,
    this.data,
    this.error,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
  factory IsolateResult.success(T data) =>
      IsolateResult(success: true, data: data, error: null);
  factory IsolateResult.error(String error) =>
      IsolateResult(success: false, data: null, error: error);
}