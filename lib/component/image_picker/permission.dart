import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:DRPublic/component/image_picker/image_picker.dart';

class IgetPermission {
  Future<XFile?> getGalleryPermission() async {
    var status = await Permission.photos.status;

    if (status.isGranted) {
      return ImagePickerSelector().imagePicker();
    } else {
      await Permission.photos.request();

      return ImagePickerSelector().imagePicker();
    }
  }

  Future<List<XFile>> getMultiImageAndGalleryPermission() async {
    var status = await Permission.photos.status;

    if (status.isGranted) {
      return ImagePickerSelector().multiImagePicker();
    } else {
      await Permission.photos.request();

      return ImagePickerSelector().multiImagePicker();
    }
  }

  Future<XFile?> getCameraPermission() async {
    var status = await Permission.camera.status;

    if (status.isGranted) {
      return ImagePickerSelector().getCamera();
    } else {
      await Permission.camera.request();

      return ImagePickerSelector().getCamera();
    }
  }

  Future<void> getCalendarPermission() async {
    var status = await Permission.calendar.status;

    if (status.isGranted) {
      // ImagePickerSelector().getCamera();
    } else {
      await Permission.calendar.request().then((value) {
        // ImagePickerSelector().getCamera();
      });
    }
  }

  Future<void> getStoragePermission() async {
    var status = await Permission.storage.status;

    if (status.isGranted) {
      // ImagePickerSelector().getCamera();
    } else {
      await Permission.storage.request().then((value) {
        // ImagePickerSelector().getCamera();
      });
    }
  }

  Future<void> getLocationPermission() async {
    var status = await Permission.location.status;

    if (status.isGranted) {
      // ImagePickerSelector().getCamera();
    } else {
      await Permission.location.request().then((value) {
        // ImagePickerSelector().getCamera();
      });
    }
  }
}
