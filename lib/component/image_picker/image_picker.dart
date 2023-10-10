import 'package:image_picker/image_picker.dart';

class ImagePickerSelector {
  Future<XFile> imagePicker() async {
    XFile? image = await ImagePicker().pickImage(source: ImageSource.gallery);

    return image!;
  }
  
  Future<List<XFile>> multiImagePicker() async {
    List<XFile>? images = await ImagePicker().pickMultiImage();

    return images!;
  }

  Future<XFile> getCamera() async {
    XFile? camera = await ImagePicker().pickImage(source: ImageSource.camera);

    return camera!;
  }
}
