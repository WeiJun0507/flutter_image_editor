import 'dart:io';
import 'dart:ui' as ui;
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:image_editor/flutter_image_editor.dart';
import 'package:image_editor/model/editor_result.dart';
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
                  final bytes =
                      await getImageBytes('assets/images/long-img.webp');
                  ui.Image uiImage = await getUiImageWithoutSize(
                      'assets/images/long-img.webp');
                  final screenWidth = MediaQuery.of(context).size.width;
                  final screenHeight = MediaQuery.of(context).size.height;
                  final viewPadding = MediaQuery.of(context).viewPadding;

                  // final widthDiff = screenWidth / uiImage.width;
                  // final desireHeight = uiImage.height * widthDiff;

                  double canvasHeight = 0.0;
                  double canvasWidth = 0.0;
                  if (uiImage.height > uiImage.width) {
                    canvasHeight = screenHeight -
                        viewPadding.top -
                        viewPadding.bottom -
                        (kToolbarHeight * 3);
                    final hRatio = canvasHeight / uiImage.height;
                    if (uiImage.width * hRatio > screenWidth) {
                      final minusRatio = uiImage.width * hRatio / screenWidth;
                      canvasHeight = canvasHeight / minusRatio;
                      canvasWidth = math.min(uiImage.width * hRatio, screenWidth);
                    }

                  } else {
                    canvasWidth = screenWidth;
                    canvasHeight = math.min(
                      uiImage.height.toDouble(),
                      screenHeight - viewPadding.top - viewPadding.bottom,
                    );
                  }

                  uiImage = await getUiImageWithSize(
                    bytes,
                    canvasHeight,
                    canvasWidth,
                  );

                  final file = File(
                      '${(await getTemporaryDirectory()).path}/long-img.webp');
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
