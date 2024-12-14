// lib/providers/uploaded_files_provider.dart

import 'package:erricson_dongle_tool/lrf_dto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Define the UploadedFile model
class UploadedFile {
  final String fileName;
  final TextEditingController siteCode;
  final TextEditingController sequenceNumber;
  final TextEditingController fingerPrint;
  final String radioOne; // "radio_one" field
  final Properties properties; // For "properties"
  final ApprovalData approvalData; // For "approval_data"

  UploadedFile({
    required this.fileName,
    required this.siteCode,
    required this.sequenceNumber,
    required this.fingerPrint,
    required this.radioOne,
    required this.properties,
    required this.approvalData,
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

final uploadClickableProvider = StateProvider<bool>((ref)=> true);
final generateLKFClickableProvider = StateProvider<bool>((ref)=> true);


// Define the provider
final uploadedFilesProvider =
StateNotifierProvider<UploadedFilesNotifier, List<UploadedFile>>(
      (ref) => UploadedFilesNotifier(),
);
