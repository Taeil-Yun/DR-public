part of custom_date_picker_c;

class CustomDatePickerScrollOptions {
  const CustomDatePickerScrollOptions({
    this.year = const CustomScrollDetailOptions(margin: EdgeInsets.all(4)),
    this.month = const CustomScrollDetailOptions(margin: EdgeInsets.all(4)),
    // this.day = const CustomScrollDetailOptions(margin: EdgeInsets.all(4)),
  });

  final CustomScrollDetailOptions year;
  final CustomScrollDetailOptions month;
  // final CustomScrollDetailOptions day;

 static CustomDatePickerScrollOptions all(CustomScrollDetailOptions value) {
    return CustomDatePickerScrollOptions(
      year: value,
      month: value,
      // day: value,
    );
  }
}

class CustomScrollDetailOptions {
  const CustomScrollDetailOptions({
    this.label = '',
    this.alignment = Alignment.centerLeft,
    this.margin,
    this.selectedTextStyle = const TextStyle(fontSize: 16.0, fontWeight: FontWeight.w700),
    this.textStyle = const TextStyle(fontSize: 14.0, fontWeight: FontWeight.w400),
  });

  final String label;
  final Alignment alignment;
  final EdgeInsets? margin;
  final TextStyle textStyle;
  final TextStyle selectedTextStyle;
}