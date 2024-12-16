
import 'package:erricson_dongle_tool/consts.dart';
import 'package:erricson_dongle_tool/secure_storage.dart';
import 'package:erricson_dongle_tool/test_widget.dart';
import 'package:erricson_dongle_tool/theme.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';


final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.dark);

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: AppThemeData.lightTheme,
      darkTheme: AppThemeData.darkTheme,
      themeMode: themeMode,
      home: const WindowsApp(),
    );
  }

  @override
  void initState() {
    super.initState();

    // Call async function using Future.delayed
    Future.delayed(Duration.zero, () async {
      writeToStorage(private_key_password, "Hasan.gh@mtnirancell.ir");
    });
  }
}

class XmlDisplayPage extends StatefulWidget {
  @override
  State<XmlDisplayPage> createState() => _XmlDisplayPageState();

  const XmlDisplayPage({super.key});
}

class _XmlDisplayPageState extends State<XmlDisplayPage> {
  String sitecode = '';
  String name = '';
  String signature = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('XML Data')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Sitecode: $sitecode'),
            Text('Name: $name'),
            Text('Signature: $signature'),
            ElevatedButton(
              onPressed: () {
                // Add signature verification logic
              },
              child: Text('Verify Signature'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void initState() {

  }
}

class DataValidationScreen extends StatefulWidget {
  const DataValidationScreen({Key? key}) : super(key: key);

  @override
  State<DataValidationScreen> createState() => _DataValidationScreenState();
}

class _DataValidationScreenState extends State<DataValidationScreen> {
  String sitecode = '';
  String name = '';
  String signature = '';

  @override
  void initState() {
    super.initState();

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Irancell Data Processor'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Normal Text Field
            const Text(
              'Enter Vendor ID:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Vendor ID',
              ),
            ),
            const SizedBox(height: 16),

            // Bigger Text Field 1
            const Text(
              'Validation Input:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 120,
              child: TextField(
                maxLines: null,
                expands: true,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Enter data to validate...',
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Bigger Text Field 2
            const Text(
              'Encryption Input:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 120,
              child: TextField(
                maxLines: null,
                expands: true,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Enter data to encrypt...',
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Submit Button
            Center(
              child: ElevatedButton(
                onPressed: () {
                  // Handle validation and encryption here
                },
                child: const Text('Process Data'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
