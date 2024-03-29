import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tflite/tflite.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'dart:io';

void main(){
  runApp(MyApp());
}
const String ssd = "SSD MobileNet";
const String yolo = "Tiny YOLOv2";



class MyApp extends StatelessWidget{
  @override
  Widget build(BuildContext context){
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: TfliteHome(),
    );
  }

}

class  TfliteHome extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    // TODO: implement createState
    return TfliteHomeState();
  }

}

class TfliteHomeState extends State<TfliteHome> {
  String _model = ssd;
  File _image;
  double _imageWidth;
  double _imageHeight;
  bool _busy = false;
  List _recognition;
  @override
  void initState(){
    super.initState();
    _busy = true;
    loadModel().then((val){
      setState(() {
        _busy = false;
      });
    });


  }
  loadModel() async{
    Tflite.close();
    try{
      String res;
      if(_model == yolo){
        res = await Tflite.loadModel(model: "assests/tflite/yolov2_tiny.tflite",
            labels: "assests/tflite/yolov2_tiny.txt"
        );
      }
      else{
        res = await Tflite.loadModel(
        model: "assests/tflite/ssd_mobilenet.tflite",
        labels: "assests/tflite/ssd_mobilenet.txt"
        );
      }
      print(res);
    } on PlatformException{
      print ("Failed to load the model");
    }

  }
 selectFromImagePicker() async{
   var image = await ImagePicker.pickImage(source: ImageSource.gallery);
   if(image == null)return;
   setState(() {
     _busy = true;
   });
   predictImage(image);
 }
 predictImage(File image) async{
   if(image == null)return;

   if(_model == yolo){
     await yolov2Tiny(image);
   }else{
     await ssdMobileNet(image);
   }

   FileImage(image)
       .resolve(ImageConfiguration())
       .addListener((ImageStreamListener((ImageInfo info,bool _){
         setState(() {
           _imageWidth = info.image.width.toDouble();
           _imageHeight = info.image.height.toDouble();
         });
   })));
   setState(() {
     _image = image;
     _busy = false;
   });
 }
 yolov2Tiny(File image) async{
   var recognition = await Tflite.detectObjectOnImage(
       path: image.path,
      model: "YOLO",
     threshold: 0.3,
     imageMean: 0.0,
     imageStd: 255.0,
     numResultsPerClass: 1
   );
   setState(() {
     _recognition = recognition;
   });
 }

 ssdMobileNet(File image)async{
   var recognition = await Tflite.detectObjectOnImage(
       path: image.path, numResultsPerClass: 1);
   setState(() {
     _recognition = recognition;
   });
 }
 List<Widget> renderBoxes(Size screen){
   if(_recognition == null){
     return[];
   }
   if(_imageWidth == null || _imageHeight == null)return[];

   double factorX = screen.width;
   double factorY = _imageHeight/_imageWidth*screen.width;

   Color blue = Colors.blue;
   return _recognition.map((re){
     return Positioned(
     left: re["rect"]["x"]*factorX,
     top: re["rect"]["y"]*factorY,
     width: re["rect"]["w"]*factorX,
     height: re["rect"]["h"]*factorY,
     child: Container(
        decoration: BoxDecoration(border: Border.all(
        color: blue,
        width: 3,
   )),
        child: Text("${re["detectedClass"]} ${(re["confidenceInClass"]* 100).toStringAsFixed(0)}",
        style: TextStyle(
        background: Paint()..color=blue,
        color: Colors.white,
        fontSize: 15,

   ),
   ),
   )
     );
   }).toList();
 }
  @override
  Widget build(BuildContext context) {
   Size size = MediaQuery.of(context).size;
   List<Widget> stackChildren = [];

   stackChildren.add(Positioned(
     top:0.0,
     left:0.0,
     width: size.width,
     child: _image == null?Text("No Image Selected"):Image.file(_image),
   ));

   stackChildren.addAll(renderBoxes(size));
   if(_busy){
     stackChildren.add(Center(child: CircularProgressIndicator(),));
   }
    return Scaffold(
      appBar: AppBar(
        title: Text("Tfite Demo"),
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.image),
        tooltip: "Pick Image from Gallery",
        onPressed: selectFromImagePicker ,
      ),
      body: Stack(
        children: stackChildren,
      ),

    );
  }
}
