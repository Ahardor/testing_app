import 'package:flutter/material.dart';

// Класс painter - отвечает за отрисовку точек, линий и фигур
class PointPainter extends CustomPainter {
  PointPainter({required this.points, this.figure = false});

  var points = <Offset>[]; // Массив точек
  bool figure; // Флаг фигуры

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint() // Стандартная кисть
      ..style = PaintingStyle.fill
      ..color = Colors.black
      ..strokeWidth = 7;

    for (var i = 0; i < points.length - 1; i++) {
      canvas.drawLine(points[i], points[i + 1], paint); // Отрисовка линий
    }
    if (figure) {
      // Отрисовка фигуры
      canvas.drawLine(points[0], points[points.length - 1], paint);

      var path = Path(); // Путь для отрисовки фигуры
      final pathPaint = Paint()
        ..style = PaintingStyle.fill
        ..color = Colors.white;

      path.moveTo(points.first.dx, points.first.dy); // Начальная точка
      for (var i = 0; i < points.length; i++) {
        path.lineTo(points[i].dx, points[i].dy);
      }

      canvas.drawPath(path, pathPaint); // Отрисовка фигуры
    }
  }

  @override
  bool shouldRepaint(PointPainter oldDelegate) =>
      true; // Перерисовка при изменении
}
