part of custom_date_picker_c;

class CustomDatePickerOptions {
  const CustomDatePickerOptions({
    this.itemExtent = 30.0,
    this.diameterRatio = 3,
    this.perspective = 0.01,
    this.isLoop = false,
  });

  final double itemExtent;
  final double diameterRatio;
  final double perspective;
  final bool isLoop;
}