part of custom_date_picker_c;

const String ko = 'ko';

extension LocaleExtension on Locale {
  List<String> get months {
    switch (languageCode) {
      case ko:
        return koMonths;
      default:
        return koMonths;
    }
  }
}

const List<String> koMonths = [
  '1',
  '2',
  '3',
  '4',
  '5',
  '6',
  '7',
  '8',
  '9',
  '10',
  '11',
  '12',
];