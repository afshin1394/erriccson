// lib/providers/uploaded_files_provider.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Define the UploadedFile model
class UploadedFile {
  final String fileName;
  final TextEditingController siteCode;
  final TextEditingController sequenceNumber;
  final TextEditingController fingerPrint;

  UploadedFile({
    required this.fileName,
    required this.siteCode,
    required this.sequenceNumber,
    required this.fingerPrint,
  });
}

// Define the StateNotifier
class UploadedFilesNotifier extends StateNotifier<List<UploadedFile>> {
  UploadedFilesNotifier() : super([]);

  // Add multiple files
  void addFiles(List<UploadedFile> files) {
    state = [...state, ...files];
  }

  // Remove a specific file
  void removeFile(UploadedFile file) {
    state = state.where((f) => f != file).toList();
    file.siteCode.dispose();
    file.sequenceNumber.dispose();
    file.fingerPrint.dispose();
  }

  // Clear all files
  void clearFiles() {
    for (var file in state) {
      file.siteCode.dispose();
      file.sequenceNumber.dispose();
      file.fingerPrint.dispose();
    }
    state = [];
  }
}

final showUploadDialogProvider = StateProvider<bool>((ref) => true);

final uploadClickable = StateProvider<bool>((ref)=> true);
final generateLKFClickable = StateProvider<bool>((ref)=> true);


// Define the provider
final uploadedFilesProvider =
StateNotifierProvider<UploadedFilesNotifier, List<UploadedFile>>(
      (ref) => UploadedFilesNotifier(),
);
