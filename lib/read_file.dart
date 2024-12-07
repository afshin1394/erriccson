import 'dart:io';

Future<String?> readTextFile(String  path)  async {
  try {
    // Specify the path to your text file

    // Open the file and read its content
    File file = File(path);
    print(await file.readAsString());
    String contents = await file.readAsString();

    // Print the contents to the console
    return contents;
  } catch (e) {
    // Handle any errors that occur during reading
    return null;
  }
}