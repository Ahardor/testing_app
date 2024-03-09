import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:testing_app/painter.dart';
import 'package:testing_app/provider.dart';
import 'dart:math';

void main() {
  runApp(
    const ProviderScope(
      // Провайдер для хранения состояния
      child: MainApp(),
    ),
  );
}

class MainApp extends ConsumerWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      home: SafeArea(
        // Отступы внутри экрана
        child: Material(
          child: Container(
            color: const Color(0xFFe3e3e3),
            child: Stack(
              // Стек для отрисовки
              children: [
                InteractiveViewer(
                  // Динамичное поле для рисования
                  // boundaryMargin: const EdgeInsets.all(200),
                  minScale: 0.3,
                  maxScale: 2,
                  child: GestureDetector(
                    // Обработка событий касания
                    onTapUp: (details) {
                      // Обработка нажатия
                      ref
                          .read(drawManager.notifier)
                          .addPoint(details.localPosition); // Добавление точки
                    },
                    child: Container(
                      height: double.infinity,
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        image: DecorationImage(
                          image: AssetImage('assets/back.png'), // Фон
                          // fit: BoxFit.cover,
                        ),
                      ),
                      child: Stack(
                        children: [
                          CustomPaint(
                            // Отрисовка точек
                            painter: PointPainter(
                              // Класс painter - отвечает за отрисовку точек, линий и фигур
                              points: ref.watch(drawManager).pointsDynamic,
                              figure: ref.watch(drawManager).figure,
                            ),
                          ),
                          if (ref.watch(drawManager).points.isNotEmpty)
                            for (var i = 0;
                                i < ref.watch(drawManager).points.length;
                                i++)
                              i == ref.watch(drawManager).selectedPoint
                                  ? SelectedPointWidget(
                                      // Отрисовка выделенной точки
                                      offset: ref
                                          .watch(drawManager)
                                          .pointsDynamic[i],
                                      ref: ref,
                                      index: i)
                                  : PointWidget(
                                      // Отрисовка не выделенной точки
                                      offset: ref.watch(drawManager).points[i],
                                      ref: ref,
                                      index: i),
                          if (ref.watch(drawManager).figure) ...[
                            for (var i = 0;
                                i < ref.watch(drawManager).points.length - 1;
                                i++)
                              LengthText(
                                // Отрисовка длины отрезков
                                first: ref.watch(drawManager).pointsDynamic[i],
                                last:
                                    ref.watch(drawManager).pointsDynamic[i + 1],
                              ),
                            LengthText(
                              // Отрисовка длины отрезка между концом фигуры и началом
                              first: ref.watch(drawManager).pointsDynamic.last,
                              last: ref.watch(drawManager).pointsDynamic.first,
                            ),
                          ]
                        ],
                      ),
                    ),
                  ),
                ),
                Align(
                  alignment:
                      Alignment.topLeft, // Выравнивание в левом верхнем углу
                  child: Container(
                    height: 40,
                    padding: const EdgeInsets.all(5),
                    margin: const EdgeInsets.only(left: 20, top: 20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          onPressed: () {
                            ref
                                .read(drawManager.notifier)
                                .undo(); // Отмена действия
                          },
                          icon: Image.asset(
                            "assets/undo.png",
                            color: ref.watch(drawManager).currentStep > 0
                                ? null
                                : Colors.grey.shade400,
                          ),
                        ),
                        Container(
                          // Разделитель
                          color: Colors.grey,
                          height: 20,
                          width: 1,
                          margin: const EdgeInsets.symmetric(horizontal: 5),
                        ),
                        IconButton(
                          onPressed: () {
                            ref
                                .read(drawManager.notifier)
                                .redo(); // Повтор действия
                          },
                          icon: Image.asset(
                            "assets/redo.png",
                            color: ref.watch(drawManager).currentStep <
                                    ref.watch(drawManager).history.length - 1
                                ? null
                                : Colors.grey.shade400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        margin: const EdgeInsets.all(10),
                        width: double.infinity,
                        // height: 40,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          "Нажмите на любую точку экрана чтобы построить угол",
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.only(
                            left: 10, right: 10, bottom: 20),
                        width: double.infinity,
                        // height: 40,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                        ),

                        child: ElevatedButton(
                          onPressed: ref.watch(drawManager).currentStep < 1
                              ? null
                              : () {
                                  ref
                                      .read(drawManager.notifier)
                                      .undo(); // Отмена действия
                                },
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            backgroundColor: Colors.grey.shade300,
                            padding: const EdgeInsets.all(10),
                            foregroundColor: Colors.grey.shade800,
                          ),
                          child: const Column(
                            children: [
                              Icon(Icons.cancel),
                              Text("Отменить действие")
                            ],
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Класс для отрисовки длины отрезков
class LengthText extends StatelessWidget {
  const LengthText({
    super.key,
    required this.first,
    required this.last,
  });

  final Offset first; // Начальная точка
  final Offset last; // Конечная точка

  @override
  Widget build(BuildContext context) {
    var total = (last.dx - first.dx).abs() +
        (last.dy - first.dy).abs(); // Суммарная длина по обоим координатам
    var xFactor = (first.dx - last.dx) / total; // Влияние координаты Х
    var yFactor = (last.dy - first.dy) / total; // Влияние координаты Y

    //Влияния нужны для правильного расположения текста длины, к примеру
    //если фактор по оси X = 0, то текст будет расположен слева или справа от линии
    //если фактор по оси Y = 0, то текст будет расположен сверху или снизу от линии

    var x = last.dx - first.dx; // Длина отрезка по Х
    var y = last.dy - first.dy; // Длина отрезка по Y

    var len = sqrt(x * x + y * y); // Длина отрезка на плоскости

    var angle = acos(x / len); // Угол между осью X и отрезком

    return Positioned(
      left: (last.dx + first.dx) / 2 -
          40 +
          yFactor * 20, // Позиция текста от левого края
      top: (last.dy + first.dy) / 2 -
          20 +
          xFactor * 20, // Позиция текста от верхнего края
      child: Transform.rotate(
        angle: y < 0 ? -angle : angle, // Поворот текста
        child: SizedBox(
          height: 40,
          width: 80,
          child: Center(
              child: Text(
            len.toStringAsFixed(2),
            style: const TextStyle(
                color: Colors.blue, fontWeight: FontWeight.w400),
          )),
        ),
      ),
    );
  }
}

// Класс для отрисовки точек
class PointWidget extends StatelessWidget {
  const PointWidget({
    super.key,
    required this.offset,
    required this.ref,
    required this.index,
  });

  final Offset offset; // Координаты точки
  final WidgetRef ref; // Контейнер для доступа к данным
  final int index; // Индекс точки

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: offset.dx - 7.5,
      top: offset.dy - 7.5,
      child: InkWell(
        onTap: () {
          // Обработка нажатия на точку
          if (index == 0 && ref.watch(drawManager).points.length > 2) {
            // Если первая точка и больше двух точек
            ref.read(drawManager.notifier).makeFigure(); // Создание фигуры
          }
          ref
              .read(drawManager.notifier)
              .selectPoint(index); // Выбор точки для редактирования
        },
        child: Container(
          height: 15,
          width: 15,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.blue,
            border: Border.all(color: Colors.white, width: 3),
          ),
        ),
      ),
    );
  }
}

// Класс для отрисовки выбранной точки
class SelectedPointWidget extends StatelessWidget {
  const SelectedPointWidget({
    super.key,
    required this.offset,
    required this.ref,
    required this.index,
  });

  final Offset offset; // Координаты точки
  final WidgetRef ref; // Контейнер для доступа к данным
  final int index; // Индекс точки

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: offset.dx - 30,
      top: offset.dy - 30,
      child: GestureDetector(
        onPanUpdate: (details) {
          // Обработка перемещения точки
          ref.read(drawManager.notifier).movePoint(
              index,
              details.localPosition -
                  const Offset(30, 30)); // Перемещение точки
        },
        onPanEnd: (details) {
          // Обработка окончания перемещения точки
          ref
              .read(drawManager.notifier)
              .saveMoved(index); // Сохранение перемещения
        },
        child: Image.asset(
          "assets/move.png", // Иконка перемещения
          height: 60,
        ),
      ),
    );
  }
}
