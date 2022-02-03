import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_barcode_sdk/dynamsoft_barcode.dart';
import 'package:flutter_barcode_sdk/flutter_barcode_sdk.dart';
import 'package:image_picker/image_picker.dart';
import 'package:qrcode/utils.dart';

class WebQr extends StatefulWidget {
  @override
  _WebQrState createState() => _WebQrState();
}

class _WebQrState extends State<WebQr> {
  String _platformVersion = 'Unknown';
  FlutterBarcodeSdk? _barcodeReader;
  String? _file;
  String _barcodeResults = '';
  final picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    initPlatformState();

    initBarcodeSDK();
  }

  Future<void> initBarcodeSDK() async {
    _barcodeReader = FlutterBarcodeSdk();
    await _barcodeReader!.init();
    await _barcodeReader!.setBarcodeFormats(BarcodeFormat.ALL);
    // Get all current parameters.
    // Refer to: https://www.dynamsoft.com/barcode-reader/parameters/reference/image-parameter/?ver=latest
    String params = await _barcodeReader!.getParameters();
    print("params :$params");
    // Convert parameters to a JSON object.
    dynamic obj = json.decode(json.decode(params));
    // Modify parameters.
    obj['ImageParameter']['DeblurLevel'] = 5;
    // Update the parameters.
    int ret = await _barcodeReader!.setParameters(json.encode(obj));
    print('Parameter update: $ret');
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    String platformVersion;
    // Platform messages may fail, so we use a try/catch PlatformException.
    try {
      platformVersion = await FlutterBarcodeSdk.platformVersion;
    } on PlatformException {
      platformVersion = 'Failed to get platform version.';
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      _platformVersion = platformVersion;
    });
  }

  void updateResults(List<BarcodeResult> results) {
    if (results.length > 0) _barcodeReader!.closeVideo();

    setState(() {
      _barcodeResults = getBarcodeResults(results);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
          appBar: AppBar(
            title: const Text('Barcode Reader'),
          ),
          body: Column(children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _file == null
                        ? Image.asset('images/default.png')
                        : Image.network(_file!),
                    Text(
                      _barcodeResults,
                      style: TextStyle(fontSize: 14, color: Colors.black),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              height: 100,
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: <Widget>[
                    MaterialButton(
                        child: Text('Barcode Reader'),
                        textColor: Colors.white,
                        color: Colors.blue,
                        onPressed: () async {
                          final pickedFile =
                              await picker.getImage(source: ImageSource.camera);

                          setState(() {
                            if (pickedFile != null) {
                              _file = pickedFile.path;
                            } else {
                              print('No image selected.');
                            }

                            _barcodeResults = '';
                          });

                          if (_file != null) {
                            List<BarcodeResult> results =
                                await _barcodeReader!.decodeFile(_file!);
                            updateResults(results);
                          }
                        }),
                    MaterialButton(
                        child: const Text('Barcode Scanner'),
                        textColor: Colors.white,
                        color: Colors.blue,
                        onPressed: () async {
                          _barcodeReader!.decodeVideo((results) {
                            // print(results);
                            updateResults(results);
                          });
                        }),
                  ]),
            ),
          ])),
    );
  }
}
