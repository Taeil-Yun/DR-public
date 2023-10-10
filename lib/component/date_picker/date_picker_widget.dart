part of custom_date_picker_c;

class CustomDatePickerScreen extends StatelessWidget {
  const CustomDatePickerScreen({
    Key? key,
    required this.onChanged,
    required this.dates,
    required this.controller,
    required this.options,
    required this.scrollViewOptions,
    required this.selectedIndex,
    required this.locale,
    this.isYearScrollView = false,
    this.isMonthScrollView = false,
  }) : super(key: key);

  final FixedExtentScrollController controller;
  final ValueChanged<int> onChanged;
  final List dates;
  final CustomDatePickerOptions options;
  final CustomScrollDetailOptions scrollViewOptions;
  final int selectedIndex;
  final Locale locale;
  final bool isYearScrollView;
  final bool isMonthScrollView;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        int _maximumCount = constraints.maxHeight ~/ options.itemExtent;
        return Container(
          margin: scrollViewOptions.margin,
          width: (MediaQuery.of(context).size.width / 2) - 16.0,
          child: ListWheelScrollView.useDelegate(
            itemExtent: options.itemExtent,
            diameterRatio: options.diameterRatio,
            controller: controller,
            physics: const FixedExtentScrollPhysics(),
            perspective: options.perspective,
            onSelectedItemChanged: onChanged,
            childDelegate: options.isLoop && dates.length > _maximumCount
              ? ListWheelChildLoopingListDelegate(
                children: List<Widget>.generate(
                  dates.length, (index) => _buildDateView(index: index),
                ),
              )
              : ListWheelChildListDelegate(
                children: List<Widget>.generate(
                  dates.length, (index) => _buildDateView(index: index),
                ),
              ),
          ),
        );
      },
    );
  }

  Widget _buildDateView({required int index}) {
    return Container(
      alignment: scrollViewOptions.alignment,
      child: Center(
        child: CustomTextBuilder(
          text: '${dates[index]}${scrollViewOptions.label}',
          fontColor: ColorsConfig().textWhite1(),
          fontSize: 16.0,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}