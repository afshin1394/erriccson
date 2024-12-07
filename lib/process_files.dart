import 'dart:convert';
import 'dart:io';
import 'package:erricson_dongle_tool/lrf_dto.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';


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

Future<List<UploadedFile>> processFiles(List<LrfDto> lrfDtoList) async {
  List<UploadedFile> uploadedFiles = [];

  for (var lrfDto in lrfDtoList) {
    // Read the content of the file as a JSON string

    // Parse the JSON content into a FileContent model


    // Create the UploadedFile object using the parsed content
    uploadedFiles.add(
      UploadedFile(
        fileName: lrfDto.name??"",
        siteCode: TextEditingController(text: '${lrfDto.data?.siteId}'),
        sequenceNumber: TextEditingController(text: '${lrfDto.data?.serialNumber}'),
        fingerPrint: TextEditingController(text: '${lrfDto.data?.fingerprint}'),
      ),
    );
  }

  return uploadedFiles;
}
Future<List<LrfDto>> convertPlatformFileToFile(List<PlatformFile> files) async {
  // Use Future.wait() to await all asynchronous operations in the map
  List<LrfDto> result = await Future.wait(
    files.map((file) async {
      String filePath = file.path!;
      File fileInstance = File(filePath);
      String content = await fileInstance.readAsString();
      // Parse the JSON content into a FileContent model
      Map<String, dynamic> jsonData = jsonDecode(content);
      LrfDto fileContentModel = LrfDto.fromJson(file.name,jsonData);
      return fileContentModel;  // Return the content of each file
    }).toList(),
  );
  return result;  // Return the list of LRFDto
}