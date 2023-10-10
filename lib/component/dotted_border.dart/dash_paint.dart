part of 'dotted_border.dart';

typedef PathBuilder = Path Function(Size);

class CustomDashPainter extends CustomPainter {
  final double strokeWidth;
  final List<double> pattern;
  final Color color;
  final BorderType borderType;
  final Radius radius;
  final StrokeCap strokeCap;
  final PathBuilder? customPath;

  CustomDashPainter({
    this.strokeWidth = 1.0,
    this.pattern = const <double>[3, 1],
    this.color = ColorsConfig.defaultBlack,
    this.borderType = BorderType.rect,
    this.radius = const Radius.circular(0),
    this.strokeCap = StrokeCap.butt,
    this.customPath,
  }) {
    assert(pattern.isNotEmpty, 'Dash Pattern cannot be empty');
  }

  @override
  bool shouldRepaint(CustomDashPainter oldDelegate) {
    return oldDelegate.strokeWidth != strokeWidth || oldDelegate.color != color || oldDelegate.pattern != pattern || oldDelegate.borderType != borderType;
  }

  @override
  void paint(Canvas canvas, Size size) {
    Paint _paint = Paint()
      ..strokeWidth = strokeWidth
      ..color = color
      ..strokeCap = strokeCap
      ..style = PaintingStyle.stroke;

    Path _path;
    
    if (customPath != null) {
      _path = dashPath(
        customPath!(size),
        dashArray: CircularIntervalList(pattern),
      );
    } else {
      _path = _getPath(size);
    }

    canvas.drawPath(_path, _paint);
  }

  Path _getPath(Size size) {
    Path _path;

    switch (borderType) {
      case BorderType.circle:
        _path = circlePath(size);
        break;
      case BorderType.rrect:
        _path = rrectPath(size, radius);
        break;
      case BorderType.rect:
        _path = rectPath(size);
        break;
      case BorderType.oval:
        _path = ovalPath(size);
        break;
    }

    return dashPath(_path, dashArray: CircularIntervalList(pattern));
  }

  Path circlePath(Size size) {
    double _w = size.width;
    double _h = size.height;
    double _s = size.shortestSide;

    return Path()..addRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          _w > _s ? (_w - _s) / 2 : 0,
          _h > _s ? (_h - _s) / 2 : 0,
          _s,
          _s,
        ),
        Radius.circular(_s / 2),
      ),
    );
  }

  Path rrectPath(Size size, Radius radius) {
    return Path()..addRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          0,
          0,
          size.width,
          size.height,
        ),
        radius,
      ),
    );
  }

  Path rectPath(Size size) {
    return Path()..addRect(
      Rect.fromLTWH(
        0,
        0,
        size.width,
        size.height,
      ),
    );
  }

  Path ovalPath(Size size) {
    return Path()..addOval(
      Rect.fromLTWH(
        0,
        0,
        size.width,
        size.height,
      ),
    );
  }
}