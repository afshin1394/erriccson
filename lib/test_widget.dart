import 'dart:ui';
import 'package:erricson_dongle_tool/lrf_dto.dart';
import 'package:erricson_dongle_tool/process_files.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lottie/lottie.dart';
import 'package:erricson_dongle_tool/lkf_generator.dart';
import 'main.dart';

// Define a provider for uploaded files
final uploadedFilesProvider =
    StateNotifierProvider<UploadedFilesNotifier, List<UploadedFile>>(
  (ref) => UploadedFilesNotifier(),
);

class UploadedFilesNotifier extends StateNotifier<List<UploadedFile>> {
  UploadedFilesNotifier() : super([]);

  void addFiles(List<UploadedFile> files) {
    state = [...state, ...files];
  }

  void clearFiles() {
    state = [];
  }
}

class WindowsApp extends HookConsumerWidget {
  const WindowsApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final showInitialDialog = useState(true);
    final isUploading = useState(false);
    final animationController = useAnimationController();

    final uploadedFiles = ref.watch(uploadedFilesProvider);

    Future<void> handleFileUpload(BuildContext context) async {
      try {
        final result = await FilePicker.platform.pickFiles(allowMultiple: true);
        if (result != null) {
          isUploading.value = true;
          animationController
            ..reset()
            ..forward();

          // Offload file conversion and processing to separate isolates
          List<LrfDto> lrfDtoList =
              await compute(convertPlatformFileToFile, result.files);
          List<UploadedFile> uploadFiles =
              await compute(processFiles, lrfDtoList);

          // Update state without using TextEditingController
          ref.read(uploadedFilesProvider.notifier).addFiles(uploadFiles);

          isUploading.value = false;
          animationController.stop();

          if (context.mounted) {
            Navigator.of(context).pop();
          }
          showInitialDialog.value = false;
        }
      } catch (e) {
        isUploading.value = false;
        animationController.stop();
        // Handle errors gracefully
        if (context.mounted) {
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text('Error'),
              content: Text('An error occurred: $e'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
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
          },
        ),
      );
    }

    // Show the initial upload dialog on first build
    useEffect(
      () {
        if (showInitialDialog.value) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            showUploadDialog(context);
          });
        }
        return null;
      },
      [showInitialDialog.value],
    );

    // Handle Submit with Parallel Processing
    Future<void> handleSubmit(BuildContext context) async {
      try {
        String? selectedDirectory =
            await FilePicker.platform.getDirectoryPath();

        if (selectedDirectory != null && selectedDirectory.isNotEmpty) {
          // Show a loading indicator
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (_) => Center(
              child: Lottie.asset(
                'assets/lotties/loading_lottie.json',
                width: 100,
                height: 100,

              ),
            ),
          );

          // Process all files in parallel
          await Future.wait(uploadedFiles.map((uploadedFile) {
            return generateFullLicenseXml(
              basePath: selectedDirectory,
              fileName: uploadedFile.fileName,
              sequenceNumber: uploadedFile.sequenceNumber.text,
              fingerPrint: uploadedFile.fingerPrint.text,
            );
          }));

          // Dismiss the loading indicator
          if (context.mounted) {
            Navigator.of(context).pop();
          }

          // Show success dialog
          showDialog<void>(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text('Success'),
              content: const Text(
                  'All files have been processed and saved successfully.'),
              actions: [
                TextButton(
                  onPressed: () {
                    ref.read(uploadedFilesProvider.notifier).clearFiles();
                    Navigator.of(context).pop();
                  },
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
      } catch (e) {
        // Handle errors gracefully
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Error'),
            content: Text('An error occurred during submission: $e'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }

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
            const Gap(18),
            _buildLogoContainer(context, themeMode),
            const Gap(18),
            // Generate a list of cards for each uploaded file
            _buildFileCards(uploadedFiles),
            const Gap(18),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: _buildSubmitButton(context, handleSubmit),
      ),
    );
  }

  Widget _buildFileCards(List<UploadedFile> files) {
    return ListView.builder(
      shrinkWrap: true,
      // Prevent infinite scroll
      physics: const NeverScrollableScrollPhysics(),
      // Disable scrolling inside ListView
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
            const Gap(12),
            _buildInputField(
              controller: file.sequenceNumber,
              label: 'Sequence Number',
              hintText: 'Enter Sequence Number',
              icon: Icons.keyboard_alt_outlined,
            ),
            const Gap(12),
            _buildInputField(
              controller: file.fingerPrint,
              label: 'Fingerprint',
              hintText: 'Enter Fingerprint',
              icon: Icons.key,
            ),
            const Gap(12),
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
  Widget _buildSubmitButton(
      BuildContext context, Future<void> Function(BuildContext) onSubmit) {
    return ElevatedButton(
      onPressed: () => onSubmit(context),
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

class UploadDialog extends StatelessWidget {
  const UploadDialog({
    required this.animationController,
    required this.isUploading,
    required this.onUploadPressed,
    super.key,
  });

  final AnimationController animationController;
  final ValueNotifier<bool> isUploading;
  final VoidCallback onUploadPressed;

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
      child: AlertDialog(
        contentPadding: EdgeInsets.zero,
        content: ValueListenableBuilder<bool>(
          valueListenable: isUploading,
          builder: (context, uploading, child) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Lottie.asset(
                  'assets/lotties/upload_lottie.json',
                  width: 200,
                  height: 200,
                  controller: animationController,
                  onLoaded: (composition) {
                    animationController.duration = composition.duration;
                  },
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    uploading
                        ? 'Uploading files...'
                        : 'Please upload files to proceed.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: uploading ? null : onUploadPressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.yellow,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: uploading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Lottie.asset(
                          'assets/lotties/upload_icon_lottie.json',
                          width: 20,
                          height: 20,
                        ),
                  label: Text(
                    uploading ? 'Uploading...' : 'Upload Files',
                  ),
                ),
                const Gap(30),
              ],
            );
          },
        ),
      ),
    );
  }
}
