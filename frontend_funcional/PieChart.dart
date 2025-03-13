import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:math' as math;
import 'dart:io';

// Clase para el gráfico circular
class PieChart extends StatelessWidget {
  final List<Map<String, dynamic>> data;
  final double radius;

  PieChart({required this.data, this.radius = 100.0});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(radius * 2, radius * 2),
      painter: PieChartPainter(data: data),
    );
  }
}

class PieChartPainter extends CustomPainter {
  final List<Map<String, dynamic>> data;

  PieChartPainter({required this.data});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    double total = 0;
    for (var item in data) {
      total += item['value'] as double;
    }

    double startAngle = -math.pi / 2; // Comienza desde arriba

    for (var item in data) {
      final sweepAngle = 2 * math.pi * (item['value'] as double) / total;
      
      final paint = Paint()
        ..style = PaintingStyle.fill
        ..color = item['color'] as Color;
      
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        paint,
      );
      
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}