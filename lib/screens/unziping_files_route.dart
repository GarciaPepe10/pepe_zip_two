import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:archive/archive_io.dart';
import 'dart:io';

class UnZipiingRoute extends StatefulWidget {
  @override
  _UnZipiingRouteState createState() => _UnZipiingRouteState();
}

class _UnZipiingRouteState extends State<UnZipiingRoute> {
  String? _directoryPath;
  bool _widgetLoaded = false;
  late Widget _textFromFile;
  late List<File> getFiles;
  final myController = TextEditingController();
  final _littleFont = const TextStyle(fontSize: 7.0);

  _fillListFiles() {
    _buildSuggestions().then((val) => setState(() {
          _textFromFile = val;
          _widgetLoaded = true;
        }));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: Text("UnZipping Files"),
        ),
        body: SingleChildScrollView(
            child: Column(children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(top: 60.0),
            child: Center(
              child: Container(
                  width: 400,
                  height: 250,
                  /*decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(50.0)),*/
                  child: _widgetLoaded
                      ? _textFromFile
                      : ListTile(
                          leading: Image.asset('assets/images/zip.png'),
                          title: Text('chose the origen'),
                          trailing: Icon(Icons.arrow_forward),
                          onTap: () {
                            _fillListFiles();
                          },
                        )),
            ),
          ),
          _directoryPath != null
              ? ListTile(
                  title: const Text('Directory path'),
                  subtitle: Text(_directoryPath!),
                )
              : ListTile(
                  leading: Image.asset('assets/images/pngwing.com.png'),
                  title: Text('chose the destination'),
                  trailing: Icon(Icons.arrow_forward),
                  onTap: () {
                    _selectFolder();
                  },
                ),
          ListTile(
            leading: Image.asset('assets/images/uncompress.png'),
            title: Text('UnZip stuff'),
            trailing: Icon(Icons.arrow_forward),
            onTap: () {
              _UnZipFiles();
              _showToast(context);
            },
          ),
        ])));
  }

  void _UnZipFiles() {
    _UnZipFile(extractToPath: _directoryPath ?? "", zipFile: getFiles[0]);
  }

  void _selectFolder() async {
    _resetState();
    try {
      String? path = await FilePicker.platform.getDirectoryPath();
      setState(() {
        _directoryPath = path;
      });
    } on PlatformException catch (e) {
      _logException('Unsupported operation' + e.toString());
    } catch (e) {
      _logException(e.toString());
    }
  }

  void _resetState() {
    if (!mounted) {
      return;
    }
    setState(() {
      _directoryPath = null;
    });
  }

  void _logException(String message) {
    print(message);
  }

  Future<Widget> _buildSuggestions() async {
    getFiles = await _pickFilesToUnZip();
    return ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: getFiles.length,
        itemBuilder: (context, i) {
          return _buildRow(getFiles[i]);
        });
  }

  Widget _buildRow(File file) {
    return ListTile(
      title: Text(
        file.path,
        style: _littleFont,
      ),
    );
  }

  Future<List<File>> _pickFilesToUnZip() async {
    FilePickerResult? result =
        await FilePicker.platform.pickFiles(allowMultiple: false);
    List<File> files;
    if (result != null) {
      files = result.paths.map((path) => File(path ?? "")).toList();
    } else {
      files = new List.filled(0, File(""), growable: true);
    }

    return files;
  }

  Future<void> _UnZipFile({
    required File zipFile,
    required String extractToPath,
  }) async {
    // Read the Zip file from disk.
    final bytes = await zipFile.readAsBytes();
    // Decode the Zip file
    final Archive archive = ZipDecoder().decodeBytes(bytes);
    // Extract the contents of the Zip archive to extractToPath.
    for (final ArchiveFile file in archive) {
      final String filename = file.name;
      if (file.isFile) {
        final data = file.content as List<int>;
        File('$extractToPath/$filename')
          ..createSync(recursive: true)
          ..writeAsBytesSync(data);
      } else {
        // it should be a directory
        Directory('$extractToPath/$filename').create(recursive: true);
      }
    }
  }

  void _showToast(BuildContext context) {
    final scaffold = ScaffoldMessenger.of(context);
    scaffold.showSnackBar(
      SnackBar(
        content: const Text('done'),
      ),
    );
  }
}
