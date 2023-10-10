import 'dart:math';

class RandomStringExtractor {
  String getRandomString ({required int length}) {
    const _str = 'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';
    
    return List.generate(length, (index) {
      final randomIndex = Random.secure().nextInt(_str.length);
      return _str[randomIndex];
    }).join('');
  }

  String getRandomLowString ({required int length}) {
    const _str = 'abcdefghijklmnopqrstuvwxyz1234567890';
    
    return List.generate(length, (index) {
      final randomIndex = Random.secure().nextInt(_str.length);
      return _str[randomIndex];
    }).join('');
  }

  String getRandomUpperString ({required int length}) {
    const _str = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890';
    
    return List.generate(length, (index) {
      final randomIndex = Random.secure().nextInt(_str.length);
      return _str[randomIndex];
    }).join('');
  }

  String getRandomUpperStringOnly ({required int length}) {
    const _str = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    
    return List.generate(length, (index) {
      final randomIndex = Random.secure().nextInt(_str.length);
      return _str[randomIndex];
    }).join('');
  }

  String getRandomLowStringOnly ({required int length}) {
    const _str = 'abcdefghijklmnopqrstuvwxyz';
    
    return List.generate(length, (index) {
      final randomIndex = Random.secure().nextInt(_str.length);
      return _str[randomIndex];
    }).join('');
  }
}