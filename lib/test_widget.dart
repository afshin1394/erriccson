// lib/widgets/windows_app.dart

import 'dart:ui';

import 'package:erricson_dongle_tool/process_files.dart';
import 'package:erricson_dongle_tool/upload_widget.dart';
import 'package:erricson_dongle_tool/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:file_picker/file_picker.dart';

// Import your providers


// Import the LoadingDialog widget
import 'LKF_generator.dart';
import 'UpdateFilesNotifier.dart';
import 'loading_widget.dart';
import 'lrf_dto.dart';
import 'main.dart';

// Import other dependencies and helper methods
// e.g., convertPlatformFileToFile, processFiles, UploadDialog, generateFullLicenseXml, etc.

class WindowsApp extends HookConsumerWidget {
  const WindowsApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final isUploading = useState(false);
    final animationController = useAnimationController();

    // Watch the uploadedFilesProvider
    final uploadedFiles = ref.watch(uploadedFilesProvider);

    // Watch the showUploadDialogProvider
    final showInitialDialog = ref.watch(showUploadDialogProvider);

    Future<void> handleFileUpload(BuildContext context) async {
      DateUtil.init();

      try {
        final result = await FilePicker.platform.pickFiles(allowMultiple: true);
        if (result != null) {
          isUploading.value = true;
          animationController
            ..reset()
            ..forward();

          List<LrfDto> lrfDtoList = await convertPlatformFileToFile(result.files);
          List<UploadedFile> uploadFiles = await processFiles(lrfDtoList);

          // Create UploadedFile instances
          List<UploadedFile> newUploadedFiles = uploadFiles.map((lrf) {
            return UploadedFile(
              fileName: lrf.fileName,
              siteCode: TextEditingController(text: lrf.siteCode.text),
              sequenceNumber:
              TextEditingController(text: lrf.sequenceNumber.text),
              fingerPrint: TextEditingController(text: lrf.fingerPrint.text),
            );
          }).toList();

          // Add to the provider
          ref.read(uploadedFilesProvider.notifier).addFiles(newUploadedFiles);

          isUploading.value = false;
          animationController.stop();

          if (context.mounted) {
            Navigator.of(context).pop();
          }

          // Update the provider to hide the dialog
          ref.read(showUploadDialogProvider.notifier).state = false;
        }
      } catch (e) {
        // Handle errors, e.g., show a Snackbar or Dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload files: $e')),
        );
      }
    }

    // Show the upload dialog
    Future<void> showUploadDialog(BuildContext context) async {
      return showDialog<void>(
        barrierDismissible: false,
        context: context,
        builder: (_) => UploadDialog(
          animationController: animationController,
          isUploading: isUploading,
          onUploadPressed: () {
            handleFileUpload(context);
            // pemToRSAPrivateKey(privateKeyToPEMGen());
            // generateFullLicenseXml();
          },
        ),
      );
    }

    useEffect(
          () {
        if (showInitialDialog) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            showUploadDialog(context);
          });
        }
        return null;
      },
      [showInitialDialog],
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Ericsson Dongle Tool',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          _buildThemeSwitcher(context, ref, themeMode),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        child: Column(
          children: [
            const SizedBox(height: 18),
            _buildLogoContainer(context, themeMode),
            const SizedBox(height: 18),
            // Generate a list of cards for each uploaded file
            _buildFileCards(uploadedFiles),
            const SizedBox(height: 18),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: _buildSubmitButton(context, ref),
      ),
    );
  }

  Widget _buildFileCards(List<UploadedFile> files) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: files.length,
      itemBuilder: (context, index) {
        final file = files[index];
        return _buildCardForFile(file);
      },
    );
  }

  Widget _buildCardForFile(UploadedFile file) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 5,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildInputField(
              controller: file.siteCode,
              label: 'Site Code',
              hintText: 'Site Code',
              icon: Icons.location_on,
            ),
            const SizedBox(height: 12),
            _buildInputField(
              controller: file.sequenceNumber,
              label: 'Sequence Number',
              hintText: 'Enter Sequence Number',
              icon: Icons.keyboard_alt_outlined,
            ),
            const SizedBox(height: 12),
            _buildInputField(
              controller: file.fingerPrint,
              label: 'Finger Print',
              hintText: 'Enter Finger Print',
              icon: Icons.key,
            ),
            const SizedBox(height: 12),
            Text(
              'Uploaded File: ${file.fileName}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hintText,
    required IconData icon,
  }) {
    return TextField(
      controller: controller,
      readOnly: true,
      decoration: InputDecoration(
        prefixIcon: Icon(icon),
        labelText: label,
        hintText: hintText,
        border: const OutlineInputBorder(),
      ),
    );
  }

  // Submit Button
  Widget _buildSubmitButton(BuildContext context, WidgetRef ref) {
    return ElevatedButton(
      onPressed: () async {
        // Show the loading dialog
        showDialog(
          context: context,
          barrierDismissible: false, // Prevents closing the dialog by tapping outside
          builder: (context) => const LoadingDialog(message: 'Processing files...'),
        );

        try {
          String? selectedDirectory = await FilePicker.platform.getDirectoryPath();

          if (selectedDirectory != null && selectedDirectory.isNotEmpty) {
            final uploadedFiles = ref.read(uploadedFilesProvider);

            List<Future<void>> processingFutures = uploadedFiles.map((uploadedFile) async {
              print(uploadedFile.fileName);
              await Future.delayed(const Duration(milliseconds: 1)); // Optional: Remove if unnecessary
              await generateFullLicenseXml(
                basePath: selectedDirectory,
                fileName: uploadedFile.fileName,
                sequenceNumber: uploadedFile.sequenceNumber.text,
                fingerPrint: uploadedFile.fingerPrint.text,
              );
            }).toList();
            await Future.wait(processingFutures);

          }

          // After processing, dismiss the loading dialog
          Navigator.of(context).pop();

          // Show confirmation dialog
         await showDialog<void>(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text('Upload'),
              content: const Text('Files are uploaded successfully.'),
              actions: [
                TextButton(
                  onPressed: () {
                    // Clear the uploaded files using the provider
                    ref.read(uploadedFilesProvider.notifier).clearFiles();
                    ref.read(showUploadDialogProvider.notifier).state=true;
                    Navigator.of(context).pop();
                  },
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        } catch (e) {
          // If an error occurs, dismiss the loading dialog and show an error message
          Navigator.of(context).pop();

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to submit files: $e')),
          );
        }
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.yellow,
        foregroundColor: Colors.black,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: const Text(
        'Submit',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    );
  }

  // Theme switcher
  Widget _buildThemeSwitcher(
      BuildContext context,
      WidgetRef ref,
      ThemeMode themeMode,
      ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: IconButton(
        icon: Icon(
          themeMode == ThemeMode.light ? Icons.dark_mode : Icons.light_mode,
        ),
        onPressed: () {
          ref.read(themeModeProvider.notifier).state =
          themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
        },
        tooltip: themeMode == ThemeMode.light
            ? 'Switch to Dark Mode'
            : 'Switch to Light Mode',
      ),
    );
  }

  // Logo container
  Widget _buildLogoContainer(BuildContext context, ThemeMode themeMode) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.yellow.withOpacity(0.5),
            spreadRadius: themeMode == ThemeMode.light ? 2 : 0.5,
            blurRadius: 10,
            offset: const Offset(5, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          width: MediaQuery.of(context).size.width / 6,
          height: 200,
          child: Image.asset(
            'assets/images/irancell_logo.jpg',
            fit: BoxFit.fill,
          ),
        ),
      ),
    );
  }
}

