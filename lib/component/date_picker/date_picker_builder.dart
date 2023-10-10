part of custom_date_picker_c;

class CustomDatePickerBuilder extends StatefulWidget {
  CustomDatePickerBuilder({
    Key? key,
    required this.selectedDate,
    DateTime? minimumDate,
    DateTime? maximumDate,
    required this.onDateTimeChanged,
    required this.onSelectedPress,
    Locale? locale,
    CustomDatePickerOptions? options,
    CustomDatePickerScrollOptions? scrollViewOptions,
    this.indicator,
  }) : minimumDate = minimumDate ?? DateTime(2020, 1, 1),
       maximumDate = maximumDate ?? DateTime.now(),
       locale = locale ?? const Locale('ko'),
       options = options ?? const CustomDatePickerOptions(),
       scrollViewOptions = scrollViewOptions ?? const CustomDatePickerScrollOptions(),
       super(key: key);

  final DateTime selectedDate;
  final DateTime minimumDate;
  final DateTime maximumDate;
  final ValueChanged<DateTime> onDateTimeChanged;
  final Function(DateTime) onSelectedPress;
  final CustomDatePickerOptions options;
  final Locale locale;
  final CustomDatePickerScrollOptions scrollViewOptions;
  final Widget? indicator;

  @override
  State<CustomDatePickerBuilder> createState() => _CustomDatePickerBuilderState();
}

class _CustomDatePickerBuilderState extends State<CustomDatePickerBuilder> {
  late FixedExtentScrollController _yearController;
  late FixedExtentScrollController _monthController;
  // late FixedExtentScrollController _dayController;

  late Widget _yearScrollView;
  late Widget _monthScrollView;
  // late Widget _dayScrollView;

  late DateTime _selectedDate;
  bool isYearScrollable = true;
  bool isMonthScrollable = true;
  List<int> _years = [];
  List<int> _months = [];
  // List<int> _days = [];

  int get selectedYearIndex => !_years.contains(_selectedDate.year) ? 0 : _years.indexOf(_selectedDate.year);

  int get selectedMonthIndex => !_months.contains(_selectedDate.month) ? 0 : _months.indexOf(_selectedDate.month);

  // int get selectedDayIndex => !_days.contains(_selectedDate.day) ? 0 : _days.indexOf(_selectedDate.day);

  int get selectedYear => _years[_yearController.selectedItem % _years.length];

  int get selectedMonth => _months[_monthController.selectedItem % _months.length];

  // int get selectedDay => _days[_dayController.selectedItem % _days.length];

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.selectedDate.isAfter(widget.maximumDate) || widget.selectedDate.isBefore(widget.minimumDate) ? DateTime.now() : widget.selectedDate;

    _years = [for (int i = widget.minimumDate.year; i <= widget.maximumDate.year; i++) i];
    _initMonths();
    _initDays();
    _yearController = FixedExtentScrollController(initialItem: selectedYearIndex);
    _monthController = FixedExtentScrollController(initialItem: selectedMonthIndex);
    // _dayController = FixedExtentScrollController(initialItem: selectedDayIndex);
  }

  @override
  void didUpdateWidget(covariant CustomDatePickerBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_selectedDate != widget.selectedDate) {
      _selectedDate = widget.selectedDate;
      isYearScrollable = false;
      isMonthScrollable = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _yearController.animateToItem(selectedYearIndex, curve: Curves.ease, duration: const Duration(microseconds: 500));
        _monthController.animateToItem(selectedMonthIndex, curve: Curves.ease, duration: const Duration(microseconds: 500));
        // _dayController.animateToItem(selectedDayIndex, curve: Curves.ease, duration: const Duration(microseconds: 500));
      });
    }
  }

  @override
  void dispose() {
    _yearController.dispose();
    _monthController.dispose();
    // _dayController.dispose();
    super.dispose();
  }

  void _initDateScrollView() {
    _yearScrollView = CustomDatePickerScreen(
      dates: _years,
      controller: _yearController,
      options: widget.options,
      scrollViewOptions: widget.scrollViewOptions.year,
      selectedIndex: selectedYearIndex,
      isYearScrollView: true,
      locale: widget.locale,
      onChanged: (_) {
        _onDateTimeChanged();
        _initMonths();
        _initDays();
        if (isYearScrollable) {
          _monthController.jumpToItem(selectedMonthIndex);
          // _dayController.jumpToItem(selectedDayIndex);
        }
        isYearScrollable = true;
      }
    );
    _monthScrollView = CustomDatePickerScreen(
      dates: widget.locale.months.sublist(_months.first - 1, _months.last),
      controller: _monthController,
      options: widget.options,
      scrollViewOptions: widget.scrollViewOptions.month,
      selectedIndex: selectedMonthIndex,
      locale: widget.locale,
      isMonthScrollView: true,
      onChanged: (_) {
        _onDateTimeChanged();
        _initDays();
        if (isMonthScrollable) {
          // _dayController.jumpToItem(selectedDayIndex);
        }
        isMonthScrollable = true;
      },
    );
    // _dayScrollView = CustomDatePickerScreen(
    //   dates: _days,
    //   controller: _dayController,
    //   options: widget.options,
    //   scrollViewOptions: widget.scrollViewOptions.day,
    //   selectedIndex: selectedDayIndex,
    //   locale: widget.locale,
    //   onChanged: (_) {
    //     _onDateTimeChanged();
    //     _initDays();
    //   },
    // );
  }

  void _initMonths() {
    if (_selectedDate.year == widget.maximumDate.year && _selectedDate.year == widget.minimumDate.year) {
      _months = [for (int i = widget.minimumDate.month; i <= widget.maximumDate.month; i++) i];
    } else if (_selectedDate.year == widget.maximumDate.year) {
      _months = [for (int i = 1; i <= widget.maximumDate.month; i++) i];
    } else if (_selectedDate.year == widget.minimumDate.year) {
      _months = [for (int i = widget.minimumDate.month; i <= 12; i++) i];
    } else {
      _months = [for (int i = 1; i <= 12; i++) i];
    }
  }

  void _initDays() {
    int _maximumDay = getMonthCalculatorDate(year: _selectedDate.year, month: _selectedDate.month);
    // _days = [for (int i = 1; i <= _maximumDay; i++) i];
    if (_selectedDate.year == widget.maximumDate.year &&
        _selectedDate.month == widget.maximumDate.month &&
        _selectedDate.year == widget.minimumDate.year &&
        _selectedDate.month == widget.minimumDate.month) {
      // _days = _days.sublist(widget.minimumDate.day - 1, widget.maximumDate.day);
    } else if (_selectedDate.year == widget.maximumDate.year && _selectedDate.month == widget.maximumDate.month) {
      // _days = _days.sublist(0, widget.maximumDate.day);
    } else if (_selectedDate.year == widget.minimumDate.year && _selectedDate.month == widget.minimumDate.month) {
      // _days = _days.sublist(widget.minimumDate.day - 1, _days.length);
    }
  }

  void _onDateTimeChanged() {
    // _selectedDate = DateTime(selectedYear, selectedMonth, selectedDay);
    _selectedDate = DateTime(selectedYear, selectedMonth);
    widget.onDateTimeChanged(_selectedDate);
  }

  void _onDateTimePressed() {
    widget.onSelectedPress(_selectedDate);
  }

  List<Widget> _getScrollDatePicker() {
    _initDateScrollView();
    switch (widget.locale.languageCode) {
      case ko:
        // return [_yearScrollView, _monthScrollView, _dayScrollView];
        return [_yearScrollView, _monthScrollView];
      default:
        // return [_yearScrollView, _monthScrollView, _dayScrollView];
        return [_yearScrollView, _monthScrollView];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: _getScrollDatePicker(),
        ),
        IgnorePointer(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: Container(
                  color: ColorsConfig.transparent,
                ),
              ),
              widget.indicator ?? Container(
                height: widget.options.itemExtent,
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.15),
                  borderRadius: const BorderRadius.all(Radius.circular(4)),
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    Expanded(
                      child: Container(
                        color: ColorsConfig.transparent,
                      ),
                    ),
                    Container(
                      height: 110.0,
                      color: ColorsConfig().subBackground1(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Positioned(
          left: 30.0,
          bottom: 25.0,
          right: 30.0,
          child: InkWell(
            onTap: () {
              _onDateTimePressed();
            },
            child: Container(
              width: MediaQuery.of(context).size.width,
              height: 46.0,
              decoration: BoxDecoration(
                color: ColorsConfig.subscribeBtnPrimary,
                borderRadius: BorderRadius.circular(6.0),
              ),
              child: Center(
                child: CustomTextBuilder(
                  text: '확인',
                  fontColor: ColorsConfig.defaultWhite,
                  fontSize: 18.0,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}