import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:image_editor/flutter_image_editor.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Stream Check',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Stream Check'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  Offset initialOffset = Offset.zero;

  int? imgWidth;
  int? imgHeight;
  File? returnedFile;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            if (returnedFile != null)
              Image.file(
                returnedFile!,
                width: 300.0,
                height: 300.0,
                fit: BoxFit.contain,
              ),
            Center(
              child: ElevatedButton(
                onPressed: () async {
                  final bytes = await getImageBytes('assets/images/icon.png');
                  ui.Image uiImage =
                      await getUiImageWithoutSize('assets/images/icon.png');
                  final screenWidth = MediaQuery.of(context).size.width;
                  final widthDiff = screenWidth / uiImage.width;
                  final desireHeight = uiImage.height * widthDiff;
                  uiImage = await getUiImageWithSize(
                      bytes, screenWidth, desireHeight);
                  final file =
                      File('${(await getTemporaryDirectory()).path}/logo.png');
                  await file.create(recursive: true);
                  await file.writeAsBytes(bytes.buffer
                      .asUint8List(bytes.offsetInBytes, bytes.lengthInBytes));

                  Navigator.of(context)
                      .push(
                    MaterialPageRoute(
                      builder: (BuildContext context) => ImageEditor(
                        originImage: file,
                        uiImage: uiImage,
                        width: uiImage.width,
                        height: uiImage.height,
                      ),
                    ),
                  )
                      .then((value) {
                    if (value is EditorImageResult) {
                      returnedFile = value.newFile;
                      imgHeight = value.imgHeight;
                      imgWidth = value.imgWidth;
                      setState(() {});
                    }
                  });
                },
                child: Text(" Enter Editor Page"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
