import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class LocalOcrService {
  /// Extracts text from one or more receipt image paths on mobile (Android/iOS).
  /// Reconstructs tabular rows using spatial bounding-box clustering to ensure
  /// columns (item name, quantity, rate, amount) are kept on single cohesive lines.
  /// Falls back gracefully to null on web/desktop or on platform exceptions.
  Future<String?> extractTextFromImages(List<String> imagePaths) async {
    if (kIsWeb) return null;
    if (!Platform.isAndroid && !Platform.isIOS) return null;
    if (imagePaths.isEmpty) return null;

    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
    final StringBuffer combinedText = StringBuffer();

    try {
      for (final path in imagePaths) {
        final file = File(path);
        if (!await file.exists()) continue;

        final inputImage = InputImage.fromFilePath(path);
        final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);

        final structuredText = _reconstructLinesSpatially(recognizedText);
        if (structuredText.isNotEmpty) {
          if (combinedText.isNotEmpty) {
            combinedText.writeln();
          }
          combinedText.write(structuredText);
        }
      }

      final result = combinedText.toString().trim();
      return result.isNotEmpty ? result : null;
    } catch (e) {
      debugPrint('[LocalOcrService] ML Kit recognition skipped or failed: $e');
      return null;
    } finally {
      await textRecognizer.close();
    }
  }

  String _reconstructLinesSpatially(RecognizedText recognizedText) {
    try {
      final List<_OcrWord> words = [];

      for (final block in recognizedText.blocks) {
        for (final line in block.lines) {
          if (line.elements.isNotEmpty) {
            for (final element in line.elements) {
              final box = element.boundingBox;
              words.add(_OcrWord(
                text: element.text,
                left: box.left,
                top: box.top,
                right: box.right,
                bottom: box.bottom,
                centerY: box.top + (box.height / 2.0),
                height: box.height,
              ));
            }
          } else {
            final box = line.boundingBox;
            words.add(_OcrWord(
              text: line.text,
              left: box.left,
              top: box.top,
              right: box.right,
              bottom: box.bottom,
              centerY: box.top + (box.height / 2.0),
              height: box.height,
            ));
          }
        }
      }

      if (words.isEmpty) {
        return recognizedText.text;
      }

      // Sort words by vertical center
      words.sort((a, b) => a.centerY.compareTo(b.centerY));

      // Adaptive line clustering threshold based on median word height
      final List<double> heights = words.map((w) => w.height).toList()..sort();
      final double medianHeight = heights[heights.length ~/ 2];
      final double threshold = (medianHeight * 0.6).clamp(8.0, 24.0);

      final List<List<_OcrWord>> rows = [];
      List<_OcrWord> currentRow = [];
      double currentCenterY = -1.0;

      for (final word in words) {
        if (currentRow.isEmpty) {
          currentRow.add(word);
          currentCenterY = word.centerY;
        } else {
          if ((word.centerY - currentCenterY).abs() <= threshold) {
            currentRow.add(word);
            final sum = currentRow.fold<double>(0.0, (acc, w) => acc + w.centerY);
            currentCenterY = sum / currentRow.length;
          } else {
            currentRow.sort((a, b) => a.left.compareTo(b.left));
            rows.add(List.from(currentRow));
            currentRow = [word];
            currentCenterY = word.centerY;
          }
        }
      }
      if (currentRow.isNotEmpty) {
        currentRow.sort((a, b) => a.left.compareTo(b.left));
        rows.add(currentRow);
      }

      final StringBuffer sb = StringBuffer();
      for (final row in rows) {
        final lineText = row.map((w) => w.text).join(' ');
        if (lineText.trim().isNotEmpty) {
          sb.writeln(lineText.trim());
        }
      }

      final reconstructed = sb.toString().trim();
      return reconstructed.isNotEmpty ? reconstructed : recognizedText.text;
    } catch (_) {
      return recognizedText.text;
    }
  }
}

class _OcrWord {
  final String text;
  final double left;
  final double top;
  final double right;
  final double bottom;
  final double centerY;
  final double height;

  _OcrWord({
    required this.text,
    required this.left,
    required this.top,
    required this.right,
    required this.bottom,
    required this.centerY,
    required this.height,
  });
}
