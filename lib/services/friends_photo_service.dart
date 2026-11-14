import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

Future<Uint8List?> pickSquareProfilePhoto() async {
  final picked = await ImagePicker().pickImage(
    source: ImageSource.gallery,
    imageQuality: 90,
  );
  if (picked == null) return null;
  return _squarePng(await picked.readAsBytes());
}

Future<String> uploadProfileBytes(String uid, Uint8List bytes) async {
  final ref = FirebaseStorage.instance.ref('profile_pictures/$uid.jpg');
  await ref.putData(bytes, SettableMetadata(contentType: 'image/png'));
  return ref.getDownloadURL();
}

Future<Uint8List> _squarePng(Uint8List bytes) async {
  final codec = await ui.instantiateImageCodec(bytes);
  final frame = await codec.getNextFrame();
  final image = frame.image;
  final size = image.width < image.height ? image.width : image.height;
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  canvas.drawImageRect(
    image,
    ui.Rect.fromLTWH(
      (image.width - size) / 2,
      (image.height - size) / 2,
      size.toDouble(),
      size.toDouble(),
    ),
    ui.Rect.fromLTWH(0, 0, size.toDouble(), size.toDouble()),
    ui.Paint(),
  );
  final square = await recorder.endRecording().toImage(size, size);
  final data = await square.toByteData(format: ui.ImageByteFormat.png);
  return data!.buffer.asUint8List();
}
