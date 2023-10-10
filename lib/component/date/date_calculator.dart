import 'package:intl/intl.dart';

///
/// 날짜 계산기
///
class DateCalculatorWrapper {
  ///
  /// 요일 또는 시간 계산기
  ///
  String daysCalculator(String uploadDate) {
    // 현재 시간
    DateTime _today = DateTime.now();

    // 결과값
    String _result = '';

    // 현재날짜 - 업로드 날짜
    int _days = int.parse(_today.difference(DateTime.parse(uploadDate).toLocal()).inDays.toString());

    if (_days > 7) {  // 계산된 일수가 7일을 초과할 때
      _result = DateFormat('yyyy년 MM월 dd일').format(DateTime.parse(uploadDate).toLocal());
    } else if (_days > 0) {  // 계산된 일수가 1~7일 사이일 때
      _result = '$_days일전';
    } else {  // 계산된 일수가 하루 미만일 때
      // 현재시간 - 업로드 시간
      int _hours = int.parse(_today.difference(DateTime.parse(uploadDate).toLocal()).inHours.toString());

      if (_hours > 0) {  // 계산된 시간이 1~23시간 사이일 때
        _result = '$_hours시간전';
      } else {  // 계산된 시간이 1시간 미만일 때
        // 현재시간 - 업로드 분
        int _minutes = int.parse(_today.difference(DateTime.parse(uploadDate).toLocal()).inMinutes.toString());

        if (_minutes > 0) {  // 계산된 분이 1~59분 사이일 때
          _result = '$_minutes분전';
        } else {  // 1분 미만일 때
          _result = '방금';
        }
      }
    }
    
    return _result;
  }

  ///
  /// 종료일까지 남은일수 계산기
  /// ex)
  ///   - 오늘 = 2022/06/07
  ///   - 종료일 = 2022/06/12
  /// <br/>
  ///   종료 예정일 - 현재 시간 = 남은기간
  ///
  expiredDate(String date) {
    // 현재시간
    DateTime _now = DateTime.now();

    // 현재날짜 - 종료날짜
    int _expDays = int.parse(DateTime.parse(date).toLocal().difference(_now).inDays.toString());

    // 시간
    int _expHours = int.parse(DateTime.parse(date).toLocal().difference(_now).inHours.toString());

    if (_expHours < 24) {
      _expDays = 0;
    }

    return _expDays;
  }
  
  ///
  /// 종료일까지 남은일수의 시간 계산기
  /// ex)
  ///   - 오늘 = 2022/06/07 12:00:00
  ///   - 종료일 = 2022/06/12 18:00:00
  /// <br/>
  ///   종료 예정시간 - 현재 시간 = 남은시간
  ///
  expiredHoursForDate(String date) {
    // 현재시간
    DateTime _now = DateTime.now();

    // 현재날짜 - 종료날짜
    int _expDays = int.parse(DateTime.parse(date).toLocal().difference(_now).inHours.toString());
    int _exps = int.parse(DateTime.parse(date).toLocal().difference(_now).inDays.toString());

    if (_expDays <= 0) {
      _expDays = 0;
    } else if (_expDays >= 24 * _exps) {
      _expDays = _expDays ~/ (_exps + 1);
    }

    return _expDays;
  }

  ///
  /// 종료일까지 남은일수의 분 계산기
  /// ex)
  ///   - 오늘 = 2022/06/07 12:00:00
  ///   - 종료일 = 2022/06/12 18:30:00
  /// <br/>
  ///   종료 예정시간 - 현재 시간 = 남은시간
  ///
  expiredMinutesForDate(String date) {
    // 현재시간
    DateTime _now = DateTime.now();

    // 현재날짜 - 종료날짜
    int _expDays = int.parse(DateTime.parse(date).toLocal().difference(_now).inMinutes.toString());

    if (_expDays <= 0) {
      _expDays = 0;
    }

    return _expDays;
  }
  
  calculatorAMPM(String date, {bool? useAMPM}) {
    String _ampm = '';

    if (DateTime.parse(date).toLocal().hour < 12) {
      _ampm = '오전 ${DateTime.parse(date).toLocal().hour}시 ${DateTime.parse(date).toLocal().minute}분';

      if (DateTime.parse(date).toLocal().hour <= 0) {
        _ampm = '오전 ${DateTime.parse(date).toLocal().hour + 12}시 ${DateTime.parse(date).toLocal().minute}분';
      }
    } else {
      _ampm = '오후 ${DateTime.parse(date).toLocal().hour - 12}시 ${DateTime.parse(date).toLocal().minute}분';
    }

    if(useAMPM == true) {
      if (DateTime.parse(date).toLocal().hour < 12) {
        _ampm = '${DateTime.parse(date).toLocal().hour}:${DateTime.parse(date).toLocal().minute} AM';

        if (DateTime.parse(date).toLocal().hour <= 0) {
          _ampm = '${DateTime.parse(date).toLocal().hour + 12}:${DateTime.parse(date).toLocal().minute} AM';
        }
      } else {
        if (DateTime.parse(date).toLocal().hour - 12 < 10 && DateTime.parse(date).toLocal().minute < 10) {
          _ampm = '0${DateTime.parse(date).toLocal().hour - 12}:0${DateTime.parse(date).toLocal().minute} PM';
        } else if (DateTime.parse(date).toLocal().hour - 12 >= 10 && DateTime.parse(date).toLocal().minute < 10) {
          _ampm = '${DateTime.parse(date).toLocal().hour - 12}:0${DateTime.parse(date).toLocal().minute} PM';
        } else if (DateTime.parse(date).toLocal().hour - 12 < 10 && DateTime.parse(date).toLocal().minute >= 10) {
          _ampm = '0${DateTime.parse(date).toLocal().hour - 12}:${DateTime.parse(date).toLocal().minute} PM';
        } else {
          _ampm = '${DateTime.parse(date).toLocal().hour - 12}:${DateTime.parse(date).toLocal().minute} PM';
        }
      }
    }

    return _ampm;
  }
}