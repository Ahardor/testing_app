import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final drawManager = NotifierProvider<DrawManager, Draw>(() => DrawManager());
// Провайдер для хранения состояния поля

class Draw {
  Draw({
    Map<List<Offset>, bool> history = const {}, // История хранения состояний
    this.currentStep = -1, // Текущий шаг
    this.selectedPoint = -1, // Выбранный пункт
    this.tempMovement = Offset.zero, // Текущее перемещение точки
  }) {
    this.history = LinkedHashMap.of(history);
  }

  late LinkedHashMap<List<Offset>, bool> history; // История хранения состояний
  final int currentStep; // Текущий шаг
  final int selectedPoint; // Выбранный пункт
  final Offset tempMovement; // Текущее перемещение точки

  List<Offset> get points => // Получение текущего массива точек
      history.keys.isEmpty ? [] : history.keys.toList()[currentStep];

  List<Offset> get pointsDynamic =>
      history.keys.isEmpty // Динамический список точек при перемещении
          ? []
          : [
              for (var i = 0; i < points.length; i++)
                i == selectedPoint ? tempMovement + points[i] : points[i],
            ];
  bool get figure => history.keys.isEmpty ? false : history[points]!;

  Draw copyWith({
    // Копирование состояния
    Map<List<Offset>, bool>? history,
    int? currentStep,
    int? selectedPoint,
    Offset? tempMovement,
  }) {
    return Draw(
      history: history ?? this.history,
      currentStep: currentStep ?? this.currentStep,
      selectedPoint: selectedPoint ?? this.selectedPoint,
      tempMovement: tempMovement ?? this.tempMovement,
    );
  }
}

class DrawManager extends Notifier<Draw> {
  @override
  Draw build() {
    return Draw();
  }

  void addPoint(Offset point) {
    // Добавление точки
    if (state.figure) return; // Если фигура, то ничего не делаем
    if (state.points.length > 2) {
      // Если больше двух точек
      for (var i = 0; i < state.points.length - 2; i++) {
        if (checkColliding(
            // Проверка пересечения с другими линиями
            state.points[i],
            state.points[i + 1],
            state.points.last,
            point)) {
          return;
        }
      }
    }

    state = state.copyWith(
      // Обновление состояния
      currentStep: state.currentStep + 1,
      selectedPoint: state.points.length,
      history: state.history.keys.isEmpty
          ? {
              [point]: false // Если история пуста, то добавляем точку
            }
          : {
              for (var i = 0; i <= state.currentStep; i++)
                state.history.keys.toList()[i]: false, // Предыдущая история
              [...state.points, point]: false // Новая история
            },
    );
  }

  void selectPoint(int index) {
    // Выбор точки
    state = state.copyWith(selectedPoint: index); // Обновление состояния
  }

  void movePoint(int index, Offset point) {
    // Перемещение точки
    if (state.points.length > 2) {
      // Если больше двух точек
      for (var i = 0; i < state.points.length - (state.figure ? 0 : 1); i++) {
        // Проверка пересечения с другими линиями
        if (state
                .figure && // Отдельный алгоритм для фигуры и перемещения начальной точки
            index == 0 &&
            i > 0 &&
            i < state.points.length - 1) {
          if (checkColliding(
            state.points[i],
            state.points[i + 1],
            state.points[0] + point,
            state.points[state.points.length - 1],
          )) return;
          if (checkColliding(
            state.points[i],
            state.points[i + 1],
            state.points[0] + point,
            state.points[1],
          )) return;
        }
        if (index != 0) {
          if (i < index - 1 || i > index) {
            if (index > 0) {
              if (checkColliding(
                  state.points[i],
                  state.points[(i + 1) % state.points.length],
                  state.points[index - 1],
                  state.points[index] + point)) return;
            }
            if (index < state.points.length - 1) {
              if (checkColliding(
                  state.points[i],
                  state.points[(i + 1) % state.points.length],
                  state.points[index] + point,
                  state.points[index + 1])) return;
            } else {
              if (checkColliding(
                  state.points[i],
                  state.points[(i + 1) % state.points.length],
                  state.points[index] + point,
                  state.points[0])) return;
            }
          }
        }
      }
    }
    state = state.copyWith(
      // Обновление состояния
      tempMovement: point,
    );
  }

  void saveMoved(int index) {
    // Сохранение перемещения по отпусканию
    state = state.copyWith(
      currentStep: state.currentStep + 1,
      tempMovement: Offset.zero,
      history: {
        for (var i = 0; i <= state.currentStep; i++)
          state.history.keys.toList()[i]:
              state.history[state.history.keys.toList()[i]]!,
        [
          for (var i = 0; i < state.points.length; i++)
            (i == index ? state.tempMovement : Offset.zero) + state.points[i]
        ]: state.history[state.points]!
      },
    );
  }

  void undo() {
    // Отмена действия
    if (state.currentStep > 0) {
      state = state.copyWith(
        currentStep:
            (state.currentStep - 1).clamp(0, 2048), // Ограничение отмены
        history: state.history,
      );
    }
  }

  void redo() {
    // Повтор действия
    if (state.currentStep < state.history.length - 1) {
      state = state.copyWith(
        currentStep:
            (state.currentStep + 1).clamp(0, 2048), // Ограничение повтора
        history: state.history,
      );
    }
  }

  void makeFigure() {
    // Создание фигуры
    if (state.figure) return;
    if (state.points.length > 2) {
      for (var i = 0; i < state.points.length - 2; i++) {
        // Проверка пересечения с другими линиями
        if (checkColliding(state.points[i], state.points[i + 1],
            state.points.last, state.points.first)) {
          return;
        }
      }
    }
    state = state.copyWith(
      // Обновление состояния
      currentStep: state.currentStep + 1,
      history: {
        for (var i = 0; i <= state.currentStep; i++)
          state.history.keys.toList()[i]:
              state.history[state.history.keys.toList()[i]]!,
        [...state.points]: true // Сохранение фигуры в историю
      },
    );
  }

  double _countT1({
    // Расчёт параметра t1 функции прямой, включающей отрезок для проверки пересечения
    required Offset a,
    required Offset b,
    required double v1,
    required double v2,
    required double w1,
    required double w2,
  }) {
    if ((v1 == 0 && v2 == 0) ||
        (w1 == 0 && w2 == 0) ||
        (v1 == 0 && w1 == 0) ||
        (v2 == 0 && w2 == 0)) {
      return 0.1;
    }
    if (v1 == 0) {
      return (b.dy + w2 * (a.dx - b.dx) / v2 - a.dy) / w1;
    }
    if (v2 == 0) {
      return (b.dx - a.dx) / v1;
    }
    if (w1 == 0) {
      return (b.dx - a.dx + v2 * (a.dy - b.dy) / w2) / v1;
    }
    if (w2 == 0) {
      return (b.dy - a.dy) / w1;
    }
    return ((b.dx - a.dx) / v1 + (v2 * a.dy - v2 * b.dy) / (v1 * w2)) /
        (1 - v2 * w1 / (v1 * w2));
  }

  double _countT2({
    // Расчёт параметра t2 функции прямой, включающей отрезок для проверки пересечения
    required Offset a,
    required Offset b,
    required double v1,
    required double v2,
    required double w1,
    required double w2,
    required double t1,
  }) {
    if ((v1 == 0 && v2 == 0) ||
        (w1 == 0 && w2 == 0) ||
        (v1 == 0 && w1 == 0) ||
        (v2 == 0 && w2 == 0)) {
      return 0.1;
    }
    if (w2 == 0) {
      return (a.dx - b.dx + v1 * t1) / v2;
    }
    return (a.dy - b.dy + w1 * t1) / w2;
  }

  bool checkColliding(Offset a1, Offset a2, Offset b1, Offset b2) {
    // Проверка пересечения
    var v1 = a2.dx - a1.dx;
    var v2 = b2.dx - b1.dx;
    var w1 = a2.dy - a1.dy;
    var w2 = b2.dy - b1.dy;

    double t1 = _countT1(
        a: a1, b: b1, v1: v1, v2: v2, w1: w1, w2: w2); // Расчёт параметра t1
    double t2 = _countT2(
        a: a1,
        b: b1,
        v1: v1,
        v2: v2,
        w1: w1,
        w2: w2,
        t1: t1); // Расчёт параметра t2

    if (t1 > 0 && t2 > 0 && t1 < 1 && t2 < 1) {
      // Проверка пересечения
      debugPrint(
          "Colliding A(${a1.dx}, ${a1.dy}; ${a2.dx}, ${a2.dy}) B(${b1.dx}, ${b1.dy}; ${b2.dx}, ${b2.dy})");

      return true;
    }

    return false;
  }
}
