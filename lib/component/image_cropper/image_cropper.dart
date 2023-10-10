import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

class ImageCropperLauncher {
  Future<CroppedFile> imageCropper(
    XFile image,
    {
      double? imageRatioX,
      double? imageRatioY,
      bool useRatioPreset = false,
    }
  ) async {
    CroppedFile? croppedImage = await ImageCropper().cropImage(
      sourcePath: image.path,
      aspectRatioPresets: useRatioPreset ? [
        CropAspectRatioPreset.square,
        CropAspectRatioPreset.ratio3x2,
        CropAspectRatioPreset.original,
        CropAspectRatioPreset.ratio4x3,
        CropAspectRatioPreset.ratio16x9
      ] : [],
      aspectRatio: const CropAspectRatio(ratioX: 390.0, ratioY: 91.0),
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: '',
          toolbarColor: Colors.deepOrange,
          toolbarWidgetColor: Colors.white,
          initAspectRatio: CropAspectRatioPreset.original,
          lockAspectRatio: false,
        ),
        IOSUiSettings(
          title: '',
          doneButtonTitle: '완료',
          cancelButtonTitle: '취소',
          // aspectRatioLockEnabled: true,'
          // minimumAspectRatio: 16/9,
          rotateButtonsHidden: true,
        ),
      ],
    );

    return croppedImage!;
  }
}