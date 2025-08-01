// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/src/physics/utils.dart' show nearEqual;
import 'package:flutter_test/flutter_test.dart';

import '../widgets/semantics_tester.dart';

void main() {
  // Regression test for https://github.com/flutter/flutter/issues/105833
  testWidgets('Drag gesture uses provided gesture settings', (WidgetTester tester) async {
    RangeValues values = const RangeValues(0.1, 0.5);
    bool dragStarted = false;
    final Key sliderKey = UniqueKey();

    await tester.pumpWidget(
      MaterialApp(
        home: Directionality(
          textDirection: TextDirection.ltr,
          child: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Material(
                child: Center(
                  child: GestureDetector(
                    behavior: HitTestBehavior.deferToChild,
                    onHorizontalDragStart: (DragStartDetails details) {
                      dragStarted = true;
                    },
                    child: MediaQuery(
                      data: MediaQuery.of(
                        context,
                      ).copyWith(gestureSettings: const DeviceGestureSettings(touchSlop: 20)),
                      child: RangeSlider(
                        key: sliderKey,
                        values: values,
                        onChanged: (RangeValues newValues) {
                          setState(() {
                            values = newValues;
                          });
                        },
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );

    TestGesture drag = await tester.startGesture(tester.getCenter(find.byKey(sliderKey)));
    await tester.pump(kPressTimeout);

    // Less than configured touch slop, more than default touch slop
    await drag.moveBy(const Offset(19.0, 0));
    await tester.pump();

    expect(values, const RangeValues(0.1, 0.5));
    expect(dragStarted, true);

    dragStarted = false;

    await drag.up();
    await tester.pumpAndSettle();

    drag = await tester.startGesture(tester.getCenter(find.byKey(sliderKey)));
    await tester.pump(kPressTimeout);

    bool sliderEnd = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Directionality(
          textDirection: TextDirection.ltr,
          child: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Material(
                child: Center(
                  child: GestureDetector(
                    behavior: HitTestBehavior.deferToChild,
                    onHorizontalDragStart: (DragStartDetails details) {
                      dragStarted = true;
                    },
                    child: MediaQuery(
                      data: MediaQuery.of(
                        context,
                      ).copyWith(gestureSettings: const DeviceGestureSettings(touchSlop: 10)),
                      child: RangeSlider(
                        key: sliderKey,
                        values: values,
                        onChanged: (RangeValues newValues) {
                          setState(() {
                            values = newValues;
                          });
                        },
                        onChangeEnd: (RangeValues newValues) {
                          sliderEnd = true;
                        },
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );

    // More than touch slop.
    await drag.moveBy(const Offset(12.0, 0));

    await drag.up();
    await tester.pumpAndSettle();

    expect(sliderEnd, true);
    expect(dragStarted, false);
  });

  testWidgets('Range Slider can move when tapped (continuous LTR)', (WidgetTester tester) async {
    RangeValues values = const RangeValues(0.3, 0.7);

    await tester.pumpWidget(
      MaterialApp(
        home: Directionality(
          textDirection: TextDirection.ltr,
          child: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Material(
                child: Center(
                  child: RangeSlider(
                    values: values,
                    onChanged: (RangeValues newValues) {
                      setState(() {
                        values = newValues;
                      });
                    },
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );

    // No thumbs get select when tapping between the thumbs outside the touch
    // boundaries
    expect(values, equals(const RangeValues(0.3, 0.7)));
    //  taps at 0.5
    await tester.tap(find.byType(RangeSlider));
    await tester.pump();
    expect(values, equals(const RangeValues(0.3, 0.7)));

    // Get the bounds of the track by finding the slider edges and translating
    // inwards by the overlay radius.
    final Offset topLeft = tester.getTopLeft(find.byType(RangeSlider)).translate(24, 0);
    final Offset bottomRight = tester.getBottomRight(find.byType(RangeSlider)).translate(-24, 0);

    // The start thumb is selected when tapping the left inactive track.
    final Offset leftTarget = topLeft + (bottomRight - topLeft) * 0.1;
    await tester.tapAt(leftTarget);
    expect(values.start, moreOrLessEquals(0.1, epsilon: 0.01));
    expect(values.end, equals(0.7));

    // The end thumb is selected when tapping the right inactive track.
    await tester.pump();
    final Offset rightTarget = topLeft + (bottomRight - topLeft) * 0.9;
    await tester.tapAt(rightTarget);
    expect(values.start, moreOrLessEquals(0.1, epsilon: 0.01));
    expect(values.end, moreOrLessEquals(0.9, epsilon: 0.01));
  });

  testWidgets('Range Slider can move when tapped (continuous RTL)', (WidgetTester tester) async {
    RangeValues values = const RangeValues(0.3, 0.7);

    await tester.pumpWidget(
      MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Material(
                child: Center(
                  child: RangeSlider(
                    values: values,
                    onChanged: (RangeValues newValues) {
                      setState(() {
                        values = newValues;
                      });
                    },
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );

    // No thumbs get select when tapping between the thumbs outside the touch
    // boundaries
    expect(values, equals(const RangeValues(0.3, 0.7)));
    // taps at 0.5
    await tester.tap(find.byType(RangeSlider));
    await tester.pump();
    expect(values, equals(const RangeValues(0.3, 0.7)));

    // Get the bounds of the track by finding the slider edges and translating
    // inwards by the overlay radius.
    final Offset topLeft = tester.getTopLeft(find.byType(RangeSlider)).translate(24, 0);
    final Offset bottomRight = tester.getBottomRight(find.byType(RangeSlider)).translate(-24, 0);

    // The end thumb is selected when tapping the left inactive track.
    final Offset leftTarget = topLeft + (bottomRight - topLeft) * 0.1;
    await tester.tapAt(leftTarget);
    expect(values.start, 0.3);
    expect(values.end, moreOrLessEquals(0.9, epsilon: 0.01));

    // The start thumb is selected when tapping the right inactive track.
    await tester.pump();
    final Offset rightTarget = topLeft + (bottomRight - topLeft) * 0.9;
    await tester.tapAt(rightTarget);
    expect(values.start, moreOrLessEquals(0.1, epsilon: 0.01));
    expect(values.end, moreOrLessEquals(0.9, epsilon: 0.01));
  });

  testWidgets('Range Slider can move when tapped (discrete LTR)', (WidgetTester tester) async {
    RangeValues values = const RangeValues(30, 70);

    await tester.pumpWidget(
      MaterialApp(
        home: Directionality(
          textDirection: TextDirection.ltr,
          child: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Material(
                child: Center(
                  child: RangeSlider(
                    values: values,
                    max: 100.0,
                    divisions: 10,
                    onChanged: (RangeValues newValues) {
                      setState(() {
                        values = newValues;
                      });
                    },
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );

    // No thumbs get select when tapping between the thumbs outside the touch
    // boundaries
    expect(values, equals(const RangeValues(30, 70)));
    // taps at 0.5
    await tester.tap(find.byType(RangeSlider));
    await tester.pumpAndSettle();
    expect(values, equals(const RangeValues(30, 70)));

    // Get the bounds of the track by finding the slider edges and translating
    // inwards by the overlay radius.
    final Offset topLeft = tester.getTopLeft(find.byType(RangeSlider)).translate(24, 0);
    final Offset bottomRight = tester.getBottomRight(find.byType(RangeSlider)).translate(-24, 0);

    // The start thumb is selected when tapping the left inactive track.
    final Offset leftTarget = topLeft + (bottomRight - topLeft) * 0.1;
    await tester.tapAt(leftTarget);
    await tester.pumpAndSettle();
    expect(values.start.round(), equals(10));
    expect(values.end.round(), equals(70));

    // The end thumb is selected when tapping the right inactive track.
    await tester.pump();
    final Offset rightTarget = topLeft + (bottomRight - topLeft) * 0.9;
    await tester.tapAt(rightTarget);
    await tester.pumpAndSettle();
    expect(values.start.round(), equals(10));
    expect(values.end.round(), equals(90));
  });

  testWidgets('Range Slider can move when tapped (discrete RTL)', (WidgetTester tester) async {
    RangeValues values = const RangeValues(30, 70);

    await tester.pumpWidget(
      MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Material(
                child: Center(
                  child: RangeSlider(
                    values: values,
                    max: 100,
                    divisions: 10,
                    onChanged: (RangeValues newValues) {
                      setState(() {
                        values = newValues;
                      });
                    },
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );

    // No thumbs get select when tapping between the thumbs outside the touch
    // boundaries
    expect(values, equals(const RangeValues(30, 70)));
    // taps at 0.5
    await tester.tap(find.byType(RangeSlider));
    await tester.pumpAndSettle();
    expect(values, equals(const RangeValues(30, 70)));

    // Get the bounds of the track by finding the slider edges and translating
    // inwards by the overlay radius.
    final Offset topLeft = tester.getTopLeft(find.byType(RangeSlider)).translate(24, 0);
    final Offset bottomRight = tester.getBottomRight(find.byType(RangeSlider)).translate(-24, 0);

    // The start thumb is selected when tapping the left inactive track.
    final Offset leftTarget = topLeft + (bottomRight - topLeft) * 0.1;
    await tester.tapAt(leftTarget);
    await tester.pumpAndSettle();
    expect(values.start.round(), equals(30));
    expect(values.end.round(), equals(90));

    // The end thumb is selected when tapping the right inactive track.
    await tester.pump();
    final Offset rightTarget = topLeft + (bottomRight - topLeft) * 0.9;
    await tester.tapAt(rightTarget);
    await tester.pumpAndSettle();
    expect(values.start.round(), equals(10));
    expect(values.end.round(), equals(90));
  });

  testWidgets('Range Slider thumbs can be dragged to the min and max (continuous LTR)', (
    WidgetTester tester,
  ) async {
    RangeValues values = const RangeValues(0.3, 0.7);

    await tester.pumpWidget(
      MaterialApp(
        home: Directionality(
          textDirection: TextDirection.ltr,
          child: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Material(
                child: Center(
                  child: RangeSlider(
                    values: values,
                    onChanged: (RangeValues newValues) {
                      setState(() {
                        values = newValues;
                      });
                    },
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );

    // Get the bounds of the track by finding the slider edges and translating
    // inwards by the overlay radius.
    final Offset topLeft = tester.getTopLeft(find.byType(RangeSlider)).translate(24, 0);
    final Offset bottomRight = tester.getBottomRight(find.byType(RangeSlider)).translate(-24, 0);

    // Drag the start thumb to the min.
    final Offset leftTarget = topLeft + (bottomRight - topLeft) * 0.3;
    await tester.dragFrom(leftTarget, topLeft + (bottomRight - topLeft) * -0.4);
    expect(values.start, equals(0));

    // Drag the end thumb to the max.
    await tester.pumpAndSettle();
    final Offset rightTarget = topLeft + (bottomRight - topLeft) * 0.7;
    await tester.dragFrom(rightTarget, topLeft + (bottomRight - topLeft) * 0.4);
    expect(values.end, equals(1));
  });

  testWidgets('Range Slider thumbs can be dragged to the min and max (continuous RTL)', (
    WidgetTester tester,
  ) async {
    RangeValues values = const RangeValues(0.3, 0.7);

    await tester.pumpWidget(
      MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Material(
                child: Center(
                  child: RangeSlider(
                    values: values,
                    onChanged: (RangeValues newValues) {
                      setState(() {
                        values = newValues;
                      });
                    },
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );

    // Get the bounds of the track by finding the slider edges and translating
    // inwards by the overlay radius.
    final Offset topLeft = tester.getTopLeft(find.byType(RangeSlider)).translate(24, 0);
    final Offset bottomRight = tester.getBottomRight(find.byType(RangeSlider)).translate(-24, 0);

    // Drag the end thumb to the max.
    final Offset leftTarget = topLeft + (bottomRight - topLeft) * 0.3;
    await tester.dragFrom(leftTarget, topLeft + (bottomRight - topLeft) * -0.4);
    expect(values.end, equals(1));

    // Drag the start thumb to the min.
    await tester.pumpAndSettle();
    final Offset rightTarget = topLeft + (bottomRight - topLeft) * 0.7;
    await tester.dragFrom(rightTarget, topLeft + (bottomRight - topLeft) * 0.4);
    expect(values.start, equals(0));
  });

  testWidgets('Range Slider thumbs can be dragged to the min and max (discrete LTR)', (
    WidgetTester tester,
  ) async {
    RangeValues values = const RangeValues(30, 70);

    await tester.pumpWidget(
      MaterialApp(
        home: Directionality(
          textDirection: TextDirection.ltr,
          child: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Material(
                child: Center(
                  child: RangeSlider(
                    values: values,
                    max: 100,
                    divisions: 10,
                    onChanged: (RangeValues newValues) {
                      setState(() {
                        values = newValues;
                      });
                    },
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );

    // Get the bounds of the track by finding the slider edges and translating
    // inwards by the overlay radius.
    final Offset topLeft = tester.getTopLeft(find.byType(RangeSlider)).translate(24, 0);
    final Offset bottomRight = tester.getBottomRight(find.byType(RangeSlider)).translate(-24, 0);

    // Drag the start thumb to the min.
    final Offset leftTarget = topLeft + (bottomRight - topLeft) * 0.3;
    await tester.dragFrom(leftTarget, topLeft + (bottomRight - topLeft) * -0.4);
    expect(values.start, equals(0));

    // Drag the end thumb to the max.
    await tester.pumpAndSettle();
    final Offset rightTarget = topLeft + (bottomRight - topLeft) * 0.7;
    await tester.dragFrom(rightTarget, topLeft + (bottomRight - topLeft) * 0.4);
    expect(values.end, equals(100));
  });

  testWidgets('Range Slider thumbs can be dragged to the min and max (discrete RTL)', (
    WidgetTester tester,
  ) async {
    RangeValues values = const RangeValues(30, 70);

    await tester.pumpWidget(
      MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Material(
                child: Center(
                  child: RangeSlider(
                    values: values,
                    max: 100,
                    divisions: 10,
                    onChanged: (RangeValues newValues) {
                      setState(() {
                        values = newValues;
                      });
                    },
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );

    // Get the bounds of the track by finding the slider edges and translating
    // inwards by the overlay radius.
    final Offset topLeft = tester.getTopLeft(find.byType(RangeSlider)).translate(24, 0);
    final Offset bottomRight = tester.getBottomRight(find.byType(RangeSlider)).translate(-24, 0);

    // Drag the end thumb to the max.
    final Offset leftTarget = topLeft + (bottomRight - topLeft) * 0.3;
    await tester.dragFrom(leftTarget, topLeft + (bottomRight - topLeft) * -0.4);
    expect(values.end, equals(100));

    // Drag the start thumb to the min.
    await tester.pumpAndSettle();
    final Offset rightTarget = topLeft + (bottomRight - topLeft) * 0.7;
    await tester.dragFrom(rightTarget, topLeft + (bottomRight - topLeft) * 0.4);
    expect(values.start, equals(0));
  });

  testWidgets(
    'Range Slider thumbs can be dragged together and the start thumb can be dragged apart (continuous LTR)',
    (WidgetTester tester) async {
      RangeValues values = const RangeValues(0.3, 0.7);

      await tester.pumpWidget(
        MaterialApp(
          home: Directionality(
            textDirection: TextDirection.ltr,
            child: StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) {
                return Material(
                  child: Center(
                    child: RangeSlider(
                      values: values,
                      onChanged: (RangeValues newValues) {
                        setState(() {
                          values = newValues;
                        });
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      );

      // Get the bounds of the track by finding the slider edges and translating
      // inwards by the overlay radius.
      final Offset topLeft = tester.getTopLeft(find.byType(RangeSlider)).translate(24, 0);
      final Offset bottomRight = tester.getBottomRight(find.byType(RangeSlider)).translate(-24, 0);
      final Offset middle = topLeft + bottomRight / 2;

      // Drag the start thumb towards the center.
      final Offset leftTarget = topLeft + (bottomRight - topLeft) * 0.3;
      await tester.dragFrom(leftTarget, middle - leftTarget);
      expect(values.start, moreOrLessEquals(0.5, epsilon: 0.05));

      // Drag the end thumb towards the center.
      await tester.pumpAndSettle();
      final Offset rightTarget = topLeft + (bottomRight - topLeft) * 0.7;
      await tester.dragFrom(rightTarget, middle - rightTarget);
      expect(values.end, moreOrLessEquals(0.5, epsilon: 0.05));

      // Drag the start thumb apart.
      await tester.pumpAndSettle();
      await tester.dragFrom(middle, -(bottomRight - topLeft) * 0.3);
      expect(values.start, moreOrLessEquals(0.2, epsilon: 0.05));
    },
  );

  testWidgets(
    'Range Slider thumbs can be dragged together and the start thumb can be dragged apart (continuous RTL)',
    (WidgetTester tester) async {
      RangeValues values = const RangeValues(0.3, 0.7);

      await tester.pumpWidget(
        MaterialApp(
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) {
                return Material(
                  child: Center(
                    child: RangeSlider(
                      values: values,
                      onChanged: (RangeValues newValues) {
                        setState(() {
                          values = newValues;
                        });
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      );

      // Get the bounds of the track by finding the slider edges and translating
      // inwards by the overlay radius.
      final Offset topLeft = tester.getTopLeft(find.byType(RangeSlider)).translate(24, 0);
      final Offset bottomRight = tester.getBottomRight(find.byType(RangeSlider)).translate(-24, 0);
      final Offset middle = topLeft + bottomRight / 2;

      // Drag the end thumb towards the center.
      final Offset leftTarget = topLeft + (bottomRight - topLeft) * 0.3;
      await tester.dragFrom(leftTarget, middle - leftTarget);
      expect(values.end, moreOrLessEquals(0.5, epsilon: 0.05));

      // Drag the start thumb towards the center.
      await tester.pumpAndSettle();
      final Offset rightTarget = topLeft + (bottomRight - topLeft) * 0.7;
      await tester.dragFrom(rightTarget, middle - rightTarget);
      expect(values.start, moreOrLessEquals(0.5, epsilon: 0.05));

      // Drag the start thumb apart.
      await tester.pumpAndSettle();
      await tester.dragFrom(middle, (bottomRight - topLeft) * 0.3);
      expect(values.start, moreOrLessEquals(0.2, epsilon: 0.05));
    },
  );

  testWidgets(
    'Range Slider thumbs can be dragged together and the start thumb can be dragged apart (discrete LTR)',
    (WidgetTester tester) async {
      RangeValues values = const RangeValues(30, 70);

      await tester.pumpWidget(
        MaterialApp(
          home: Directionality(
            textDirection: TextDirection.ltr,
            child: StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) {
                return Material(
                  child: Center(
                    child: RangeSlider(
                      values: values,
                      max: 100,
                      divisions: 10,
                      onChanged: (RangeValues newValues) {
                        setState(() {
                          values = newValues;
                        });
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      );

      // Get the bounds of the track by finding the slider edges and translating
      // inwards by the overlay radius.
      final Offset topLeft = tester.getTopLeft(find.byType(RangeSlider)).translate(24, 0);
      final Offset bottomRight = tester.getBottomRight(find.byType(RangeSlider)).translate(-24, 0);
      final Offset middle = topLeft + bottomRight / 2;

      // Drag the start thumb towards the center.
      final Offset leftTarget = topLeft + (bottomRight - topLeft) * 0.3;
      await tester.dragFrom(leftTarget, middle - leftTarget);
      expect(values.start, moreOrLessEquals(50, epsilon: 0.01));

      // Drag the end thumb towards the center.
      await tester.pumpAndSettle();
      final Offset rightTarget = topLeft + (bottomRight - topLeft) * 0.7;
      await tester.dragFrom(rightTarget, middle - rightTarget);
      expect(values.end, moreOrLessEquals(50, epsilon: 0.01));

      // Drag the start thumb apart.
      await tester.pumpAndSettle();
      await tester.dragFrom(middle, -(bottomRight - topLeft) * 0.3);
      expect(values.start, moreOrLessEquals(20, epsilon: 0.01));
    },
  );

  testWidgets(
    'Range Slider thumbs can be dragged together and the start thumb can be dragged apart (discrete RTL)',
    (WidgetTester tester) async {
      RangeValues values = const RangeValues(30, 70);

      await tester.pumpWidget(
        MaterialApp(
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) {
                return Material(
                  child: Center(
                    child: RangeSlider(
                      values: values,
                      max: 100,
                      divisions: 10,
                      onChanged: (RangeValues newValues) {
                        setState(() {
                          values = newValues;
                        });
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      );

      // Get the bounds of the track by finding the slider edges and translating
      // inwards by the overlay radius.
      final Offset topLeft = tester.getTopLeft(find.byType(RangeSlider)).translate(24, 0);
      final Offset bottomRight = tester.getBottomRight(find.byType(RangeSlider)).translate(-24, 0);
      final Offset middle = topLeft + bottomRight / 2;

      // Drag the end thumb towards the center.
      final Offset leftTarget = topLeft + (bottomRight - topLeft) * 0.3;
      await tester.dragFrom(leftTarget, middle - leftTarget);
      expect(values.end, moreOrLessEquals(50, epsilon: 0.01));

      // Drag the start thumb towards the center.
      await tester.pumpAndSettle();
      final Offset rightTarget = topLeft + (bottomRight - topLeft) * 0.7;
      await tester.dragFrom(rightTarget, middle - rightTarget);
      expect(values.start, moreOrLessEquals(50, epsilon: 0.01));

      // Drag the start thumb apart.
      await tester.pumpAndSettle();
      await tester.dragFrom(middle, (bottomRight - topLeft) * 0.3);
      expect(values.start, moreOrLessEquals(20, epsilon: 0.01));
    },
  );

  testWidgets(
    'Range Slider thumbs can be dragged together and the end thumb can be dragged apart (continuous LTR)',
    (WidgetTester tester) async {
      RangeValues values = const RangeValues(0.3, 0.7);

      await tester.pumpWidget(
        MaterialApp(
          home: Directionality(
            textDirection: TextDirection.ltr,
            child: StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) {
                return Material(
                  child: Center(
                    child: RangeSlider(
                      values: values,
                      onChanged: (RangeValues newValues) {
                        setState(() {
                          values = newValues;
                        });
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      );

      // Get the bounds of the track by finding the slider edges and translating
      // inwards by the overlay radius.
      final Offset topLeft = tester.getTopLeft(find.byType(RangeSlider)).translate(24, 0);
      final Offset bottomRight = tester.getBottomRight(find.byType(RangeSlider)).translate(-24, 0);
      final Offset middle = topLeft + bottomRight / 2;

      // Drag the start thumb towards the center.
      final Offset leftTarget = topLeft + (bottomRight - topLeft) * 0.3;
      await tester.dragFrom(leftTarget, middle - leftTarget);
      expect(values.start, moreOrLessEquals(0.5, epsilon: 0.05));

      // Drag the end thumb towards the center.
      await tester.pumpAndSettle();
      final Offset rightTarget = topLeft + (bottomRight - topLeft) * 0.7;
      await tester.dragFrom(rightTarget, middle - rightTarget);
      expect(values.end, moreOrLessEquals(0.5, epsilon: 0.05));

      // Drag the end thumb apart.
      await tester.pumpAndSettle();
      await tester.dragFrom(middle, (bottomRight - topLeft) * 0.3);
      expect(values.end, moreOrLessEquals(0.8, epsilon: 0.05));
    },
  );

  testWidgets(
    'Range Slider thumbs can be dragged together and the end thumb can be dragged apart (continuous RTL)',
    (WidgetTester tester) async {
      RangeValues values = const RangeValues(0.3, 0.7);

      await tester.pumpWidget(
        MaterialApp(
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) {
                return Material(
                  child: Center(
                    child: RangeSlider(
                      values: values,
                      onChanged: (RangeValues newValues) {
                        setState(() {
                          values = newValues;
                        });
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      );

      // Get the bounds of the track by finding the slider edges and translating
      // inwards by the overlay radius.
      final Offset topLeft = tester.getTopLeft(find.byType(RangeSlider)).translate(24, 0);
      final Offset bottomRight = tester.getBottomRight(find.byType(RangeSlider)).translate(-24, 0);
      final Offset middle = topLeft + bottomRight / 2;

      // Drag the end thumb towards the center.
      final Offset leftTarget = topLeft + (bottomRight - topLeft) * 0.3;
      await tester.dragFrom(leftTarget, middle - leftTarget);
      expect(values.end, moreOrLessEquals(0.5, epsilon: 0.05));

      // Drag the start thumb towards the center.
      await tester.pumpAndSettle();
      final Offset rightTarget = topLeft + (bottomRight - topLeft) * 0.7;
      await tester.dragFrom(rightTarget, middle - rightTarget);
      expect(values.start, moreOrLessEquals(0.5, epsilon: 0.05));

      // Drag the end thumb apart.
      await tester.pumpAndSettle();
      await tester.dragFrom(middle, -(bottomRight - topLeft) * 0.3);
      expect(values.end, moreOrLessEquals(0.8, epsilon: 0.05));
    },
  );

  testWidgets(
    'Range Slider thumbs can be dragged together and the end thumb can be dragged apart (discrete LTR)',
    (WidgetTester tester) async {
      RangeValues values = const RangeValues(30, 70);

      await tester.pumpWidget(
        MaterialApp(
          home: Directionality(
            textDirection: TextDirection.ltr,
            child: StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) {
                return Material(
                  child: Center(
                    child: RangeSlider(
                      values: values,
                      max: 100,
                      divisions: 10,
                      onChanged: (RangeValues newValues) {
                        setState(() {
                          values = newValues;
                        });
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      );

      // Get the bounds of the track by finding the slider edges and translating
      // inwards by the overlay radius.
      final Offset topLeft = tester.getTopLeft(find.byType(RangeSlider)).translate(24, 0);
      final Offset bottomRight = tester.getBottomRight(find.byType(RangeSlider)).translate(-24, 0);
      final Offset middle = topLeft + bottomRight / 2;

      // Drag the start thumb towards the center.
      final Offset leftTarget = topLeft + (bottomRight - topLeft) * 0.3;
      await tester.dragFrom(leftTarget, middle - leftTarget);
      expect(values.start, moreOrLessEquals(50, epsilon: 0.01));

      // Drag the end thumb towards the center.
      await tester.pumpAndSettle();
      final Offset rightTarget = topLeft + (bottomRight - topLeft) * 0.7;
      await tester.dragFrom(rightTarget, middle - rightTarget);
      expect(values.end, moreOrLessEquals(50, epsilon: 0.01));

      // Drag the end thumb apart.
      await tester.pumpAndSettle();
      await tester.dragFrom(middle, (bottomRight - topLeft) * 0.3);
      expect(values.end, moreOrLessEquals(80, epsilon: 0.01));
    },
  );

  testWidgets(
    'Range Slider thumbs can be dragged together and the end thumb can be dragged apart (discrete RTL)',
    (WidgetTester tester) async {
      RangeValues values = const RangeValues(30, 70);

      await tester.pumpWidget(
        MaterialApp(
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) {
                return Material(
                  child: Center(
                    child: RangeSlider(
                      values: values,
                      max: 100,
                      divisions: 10,
                      onChanged: (RangeValues newValues) {
                        setState(() {
                          values = newValues;
                        });
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      );

      // Get the bounds of the track by finding the slider edges and translating
      // inwards by the overlay radius.
      final Offset topLeft = tester.getTopLeft(find.byType(RangeSlider)).translate(24, 0);
      final Offset bottomRight = tester.getBottomRight(find.byType(RangeSlider)).translate(-24, 0);
      final Offset middle = topLeft + bottomRight / 2;

      // Drag the end thumb towards the center.
      final Offset leftTarget = topLeft + (bottomRight - topLeft) * 0.3;
      await tester.dragFrom(leftTarget, middle - leftTarget);
      expect(values.end, moreOrLessEquals(50, epsilon: 0.01));

      // Drag the start thumb towards the center.
      await tester.pumpAndSettle();
      final Offset rightTarget = topLeft + (bottomRight - topLeft) * 0.7;
      await tester.dragFrom(rightTarget, middle - rightTarget);
      expect(values.start, moreOrLessEquals(50, epsilon: 0.01));

      // Drag the end thumb apart.
      await tester.pumpAndSettle();
      await tester.dragFrom(middle, -(bottomRight - topLeft) * 0.3);
      expect(values.end, moreOrLessEquals(80, epsilon: 0.01));
    },
  );

  testWidgets(
    'Range Slider onChangeEnd and onChangeStart are called on an interaction initiated by tap',
    (WidgetTester tester) async {
      RangeValues values = const RangeValues(30, 70);
      RangeValues? startValues;
      RangeValues? endValues;

      await tester.pumpWidget(
        MaterialApp(
          home: Directionality(
            textDirection: TextDirection.ltr,
            child: StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) {
                return Material(
                  child: Center(
                    child: RangeSlider(
                      values: values,
                      max: 100,
                      onChanged: (RangeValues newValues) {
                        setState(() {
                          values = newValues;
                        });
                      },
                      onChangeStart: (RangeValues newValues) {
                        startValues = newValues;
                      },
                      onChangeEnd: (RangeValues newValues) {
                        endValues = newValues;
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      );

      // Get the bounds of the track by finding the slider edges and translating
      // inwards by the overlay radius.
      final Offset topLeft = tester.getTopLeft(find.byType(RangeSlider)).translate(24, 0);
      final Offset bottomRight = tester.getBottomRight(find.byType(RangeSlider)).translate(-24, 0);

      // Drag the start thumb towards the center.
      final Offset leftTarget = topLeft + (bottomRight - topLeft) * 0.3;
      expect(startValues, null);
      expect(endValues, null);
      await tester.dragFrom(leftTarget, (bottomRight - topLeft) * 0.2);
      expect(startValues!.start, moreOrLessEquals(30, epsilon: 1));
      expect(startValues!.end, moreOrLessEquals(70, epsilon: 1));
      expect(values.start, moreOrLessEquals(50, epsilon: 1));
      expect(values.end, moreOrLessEquals(70, epsilon: 1));
      expect(endValues!.start, moreOrLessEquals(50, epsilon: 1));
      expect(endValues!.end, moreOrLessEquals(70, epsilon: 1));
    },
  );

  testWidgets(
    'Range Slider onChangeEnd and onChangeStart are called on an interaction initiated by drag',
    (WidgetTester tester) async {
      RangeValues values = const RangeValues(30, 70);
      late RangeValues startValues;
      late RangeValues endValues;

      await tester.pumpWidget(
        MaterialApp(
          home: Directionality(
            textDirection: TextDirection.ltr,
            child: StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) {
                return Material(
                  child: Center(
                    child: RangeSlider(
                      values: values,
                      max: 100,
                      onChanged: (RangeValues newValues) {
                        setState(() {
                          values = newValues;
                        });
                      },
                      onChangeStart: (RangeValues newValues) {
                        startValues = newValues;
                      },
                      onChangeEnd: (RangeValues newValues) {
                        endValues = newValues;
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      );

      // Get the bounds of the track by finding the slider edges and translating
      // inwards by the overlay radius
      final Offset topLeft = tester.getTopLeft(find.byType(RangeSlider)).translate(24, 0);
      final Offset bottomRight = tester.getBottomRight(find.byType(RangeSlider)).translate(-24, 0);

      // Drag the thumbs together.
      final Offset leftTarget = topLeft + (bottomRight - topLeft) * 0.3;
      await tester.dragFrom(leftTarget, (bottomRight - topLeft) * 0.2);
      await tester.pumpAndSettle();
      final Offset rightTarget = topLeft + (bottomRight - topLeft) * 0.7;
      await tester.dragFrom(rightTarget, (bottomRight - topLeft) * -0.2);
      await tester.pumpAndSettle();
      expect(values.start, moreOrLessEquals(50, epsilon: 1));
      expect(values.end, moreOrLessEquals(51, epsilon: 1));

      // Drag the end thumb to the right.
      final Offset middleTarget = topLeft + (bottomRight - topLeft) * 0.5;
      await tester.dragFrom(middleTarget, (bottomRight - topLeft) * 0.4);
      await tester.pumpAndSettle();
      expect(startValues.start, moreOrLessEquals(50, epsilon: 1));
      expect(startValues.end, moreOrLessEquals(51, epsilon: 1));
      expect(endValues.start, moreOrLessEquals(50, epsilon: 1));
      expect(endValues.end, moreOrLessEquals(90, epsilon: 1));
    },
  );

  ThemeData buildTheme() {
    return ThemeData(
      platform: TargetPlatform.android,
      primarySwatch: Colors.blue,
      sliderTheme: const SliderThemeData(
        disabledThumbColor: Color(0xff000001),
        disabledActiveTickMarkColor: Color(0xff000002),
        disabledActiveTrackColor: Color(0xff000003),
        disabledInactiveTickMarkColor: Color(0xff000004),
        disabledInactiveTrackColor: Color(0xff000005),
        activeTrackColor: Color(0xff000006),
        activeTickMarkColor: Color(0xff000007),
        inactiveTrackColor: Color(0xff000008),
        inactiveTickMarkColor: Color(0xff000009),
        overlayColor: Color(0xff000010),
        thumbColor: Color(0xff000011),
        valueIndicatorColor: Color(0xff000012),
      ),
    );
  }

  Widget buildThemedApp({
    required ThemeData theme,
    Color? activeColor,
    Color? inactiveColor,
    int? divisions,
    bool enabled = true,
  }) {
    RangeValues values = const RangeValues(0.5, 0.75);
    final ValueChanged<RangeValues>? onChanged = !enabled
        ? null
        : (RangeValues newValues) {
            values = newValues;
          };
    return MaterialApp(
      home: Directionality(
        textDirection: TextDirection.ltr,
        child: Material(
          child: Center(
            child: Theme(
              data: theme,
              child: RangeSlider(
                values: values,
                labels: RangeLabels(values.start.toStringAsFixed(2), values.end.toStringAsFixed(2)),
                divisions: divisions,
                activeColor: activeColor,
                inactiveColor: inactiveColor,
                onChanged: onChanged,
              ),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets(
    'Range Slider uses the right theme colors for the right shapes for a default enabled slider',
    (WidgetTester tester) async {
      final ThemeData theme = buildTheme();
      final SliderThemeData sliderTheme = theme.sliderTheme;

      await tester.pumpWidget(buildThemedApp(theme: theme));

      final RenderBox sliderBox = tester.firstRenderObject<RenderBox>(find.byType(RangeSlider));

      // Check default theme for enabled widget.
      expect(
        sliderBox,
        paints
          ..rrect(color: sliderTheme.inactiveTrackColor)
          ..rrect(color: sliderTheme.inactiveTrackColor)
          ..rrect(color: sliderTheme.activeTrackColor),
      );
      expect(
        sliderBox,
        paints
          ..circle(color: sliderTheme.thumbColor)
          ..circle(color: sliderTheme.thumbColor),
      );
      expect(sliderBox, isNot(paints..circle(color: sliderTheme.disabledThumbColor)));
      expect(sliderBox, isNot(paints..rect(color: sliderTheme.disabledActiveTrackColor)));
      expect(sliderBox, isNot(paints..rect(color: sliderTheme.disabledInactiveTrackColor)));
      expect(sliderBox, isNot(paints..circle(color: sliderTheme.activeTickMarkColor)));
      expect(sliderBox, isNot(paints..circle(color: sliderTheme.inactiveTickMarkColor)));
    },
  );

  testWidgets(
    'Range Slider uses the right theme colors for the right shapes when setting the active color',
    (WidgetTester tester) async {
      const Color activeColor = Color(0xcafefeed);
      final ThemeData theme = buildTheme();
      final SliderThemeData sliderTheme = theme.sliderTheme;

      await tester.pumpWidget(buildThemedApp(theme: theme, activeColor: activeColor));

      final RenderBox sliderBox = tester.firstRenderObject<RenderBox>(find.byType(RangeSlider));

      expect(
        sliderBox,
        paints
          ..rrect(color: sliderTheme.inactiveTrackColor)
          ..rrect(color: sliderTheme.inactiveTrackColor)
          ..rrect(color: activeColor),
      );
      expect(
        sliderBox,
        paints
          ..circle(color: activeColor)
          ..circle(color: activeColor),
      );
      expect(sliderBox, isNot(paints..circle(color: sliderTheme.thumbColor)));
      expect(sliderBox, isNot(paints..circle(color: sliderTheme.disabledThumbColor)));
      expect(sliderBox, isNot(paints..rect(color: sliderTheme.disabledActiveTrackColor)));
      expect(sliderBox, isNot(paints..rect(color: sliderTheme.disabledInactiveTrackColor)));
    },
  );

  testWidgets(
    'Range Slider uses the right theme colors for the right shapes when setting the inactive color',
    (WidgetTester tester) async {
      const Color inactiveColor = Color(0xdeadbeef);
      final ThemeData theme = buildTheme();
      final SliderThemeData sliderTheme = theme.sliderTheme;

      await tester.pumpWidget(buildThemedApp(theme: theme, inactiveColor: inactiveColor));

      final RenderBox sliderBox = tester.firstRenderObject<RenderBox>(find.byType(RangeSlider));

      expect(
        sliderBox,
        paints
          ..rrect(color: inactiveColor)
          ..rrect(color: inactiveColor)
          ..rrect(color: sliderTheme.activeTrackColor),
      );
      expect(
        sliderBox,
        paints
          ..circle(color: sliderTheme.thumbColor)
          ..circle(color: sliderTheme.thumbColor),
      );
      expect(sliderBox, isNot(paints..circle(color: sliderTheme.disabledThumbColor)));
      expect(sliderBox, isNot(paints..rect(color: sliderTheme.disabledActiveTrackColor)));
      expect(sliderBox, isNot(paints..rect(color: sliderTheme.disabledInactiveTrackColor)));
    },
  );

  testWidgets(
    'Range Slider uses the right theme colors for the right shapes with active and inactive colors',
    (WidgetTester tester) async {
      const Color activeColor = Color(0xcafefeed);
      const Color inactiveColor = Color(0xdeadbeef);
      final ThemeData theme = buildTheme();
      final SliderThemeData sliderTheme = theme.sliderTheme;

      await tester.pumpWidget(
        buildThemedApp(theme: theme, activeColor: activeColor, inactiveColor: inactiveColor),
      );

      final RenderBox sliderBox = tester.firstRenderObject<RenderBox>(find.byType(RangeSlider));

      expect(
        sliderBox,
        paints
          ..rrect(color: inactiveColor)
          ..rrect(color: inactiveColor)
          ..rrect(color: activeColor),
      );
      expect(
        sliderBox,
        paints
          ..circle(color: activeColor)
          ..circle(color: activeColor),
      );
      expect(sliderBox, isNot(paints..circle(color: sliderTheme.thumbColor)));
      expect(sliderBox, isNot(paints..circle(color: sliderTheme.disabledThumbColor)));
      expect(sliderBox, isNot(paints..rect(color: sliderTheme.disabledActiveTrackColor)));
      expect(sliderBox, isNot(paints..rect(color: sliderTheme.disabledInactiveTrackColor)));
    },
  );

  testWidgets(
    'Range Slider uses the right theme colors for the right shapes for a discrete slider',
    (WidgetTester tester) async {
      final ThemeData theme = buildTheme();
      final SliderThemeData sliderTheme = theme.sliderTheme;

      await tester.pumpWidget(buildThemedApp(theme: theme, divisions: 3));

      final RenderBox sliderBox = tester.firstRenderObject<RenderBox>(find.byType(RangeSlider));

      expect(
        sliderBox,
        paints
          ..rrect(color: sliderTheme.inactiveTrackColor)
          ..rrect(color: sliderTheme.inactiveTrackColor)
          ..rrect(color: sliderTheme.activeTrackColor),
      );
      expect(
        sliderBox,
        paints
          ..circle(color: sliderTheme.inactiveTickMarkColor)
          ..circle(color: sliderTheme.inactiveTickMarkColor)
          ..circle(color: sliderTheme.activeTickMarkColor)
          ..circle(color: sliderTheme.inactiveTickMarkColor)
          ..circle(color: sliderTheme.thumbColor)
          ..circle(color: sliderTheme.thumbColor),
      );
      expect(sliderBox, isNot(paints..circle(color: sliderTheme.disabledThumbColor)));
      expect(sliderBox, isNot(paints..rect(color: sliderTheme.disabledActiveTrackColor)));
      expect(sliderBox, isNot(paints..rect(color: sliderTheme.disabledInactiveTrackColor)));
    },
  );

  testWidgets(
    'Range Slider uses the right theme colors for the right shapes for a discrete slider with active and inactive colors',
    (WidgetTester tester) async {
      const Color activeColor = Color(0xcafefeed);
      const Color inactiveColor = Color(0xdeadbeef);
      final ThemeData theme = buildTheme();
      final SliderThemeData sliderTheme = theme.sliderTheme;

      await tester.pumpWidget(
        buildThemedApp(
          theme: theme,
          activeColor: activeColor,
          inactiveColor: inactiveColor,
          divisions: 3,
        ),
      );

      final RenderBox sliderBox = tester.firstRenderObject<RenderBox>(find.byType(RangeSlider));

      expect(
        sliderBox,
        paints
          ..rrect(color: inactiveColor)
          ..rrect(color: inactiveColor)
          ..rrect(color: activeColor),
      );
      expect(
        sliderBox,
        paints
          ..circle(color: activeColor)
          ..circle(color: activeColor)
          ..circle(color: inactiveColor)
          ..circle(color: activeColor)
          ..circle(color: activeColor)
          ..circle(color: activeColor),
      );
      expect(sliderBox, isNot(paints..circle(color: sliderTheme.thumbColor)));
      expect(sliderBox, isNot(paints..circle(color: sliderTheme.disabledThumbColor)));
      expect(sliderBox, isNot(paints..rect(color: sliderTheme.disabledActiveTrackColor)));
      expect(sliderBox, isNot(paints..rect(color: sliderTheme.disabledInactiveTrackColor)));
      expect(sliderBox, isNot(paints..circle(color: sliderTheme.activeTickMarkColor)));
      expect(sliderBox, isNot(paints..circle(color: sliderTheme.inactiveTickMarkColor)));
    },
  );

  testWidgets(
    'Range Slider uses the right theme colors for the right shapes for a default disabled slider',
    (WidgetTester tester) async {
      final ThemeData theme = buildTheme();
      final SliderThemeData sliderTheme = theme.sliderTheme;

      await tester.pumpWidget(buildThemedApp(theme: theme, enabled: false));

      final RenderBox sliderBox = tester.firstRenderObject<RenderBox>(find.byType(RangeSlider));

      expect(
        sliderBox,
        paints
          ..rrect(color: sliderTheme.disabledInactiveTrackColor)
          ..rrect(color: sliderTheme.disabledInactiveTrackColor)
          ..rrect(color: sliderTheme.disabledActiveTrackColor),
      );
      expect(sliderBox, isNot(paints..circle(color: sliderTheme.thumbColor)));
      expect(sliderBox, isNot(paints..rect(color: sliderTheme.activeTrackColor)));
      expect(sliderBox, isNot(paints..rect(color: sliderTheme.inactiveTrackColor)));
    },
  );

  testWidgets(
    'Range Slider uses the right theme colors for the right shapes for a disabled slider with active and inactive colors',
    (WidgetTester tester) async {
      const Color activeColor = Color(0xcafefeed);
      const Color inactiveColor = Color(0xdeadbeef);
      final ThemeData theme = buildTheme();
      final SliderThemeData sliderTheme = theme.sliderTheme;

      await tester.pumpWidget(
        buildThemedApp(
          theme: theme,
          activeColor: activeColor,
          inactiveColor: inactiveColor,
          enabled: false,
        ),
      );

      final RenderBox sliderBox = tester.firstRenderObject<RenderBox>(find.byType(RangeSlider));

      expect(
        sliderBox,
        paints
          ..rrect(color: sliderTheme.disabledInactiveTrackColor)
          ..rrect(color: sliderTheme.disabledInactiveTrackColor)
          ..rrect(color: sliderTheme.disabledActiveTrackColor),
      );
      expect(sliderBox, isNot(paints..circle(color: sliderTheme.thumbColor)));
      expect(sliderBox, isNot(paints..rect(color: sliderTheme.activeTrackColor)));
      expect(sliderBox, isNot(paints..rect(color: sliderTheme.inactiveTrackColor)));
    },
  );

  testWidgets(
    'Range Slider uses the right theme colors for the right shapes when the value indicators are showing',
    (WidgetTester tester) async {
      final ThemeData theme = buildTheme();
      final SliderThemeData sliderTheme = theme.sliderTheme;
      RangeValues values = const RangeValues(0.5, 0.75);

      Widget buildApp({
        Color? activeColor,
        Color? inactiveColor,
        int? divisions,
        bool enabled = true,
      }) {
        final ValueChanged<RangeValues>? onChanged = !enabled
            ? null
            : (RangeValues newValues) {
                values = newValues;
              };
        return MaterialApp(
          home: Directionality(
            textDirection: TextDirection.ltr,
            child: Material(
              child: Center(
                child: Theme(
                  data: theme,
                  child: RangeSlider(
                    values: values,
                    labels: RangeLabels(
                      values.start.toStringAsFixed(2),
                      values.end.toStringAsFixed(2),
                    ),
                    divisions: divisions,
                    activeColor: activeColor,
                    inactiveColor: inactiveColor,
                    onChanged: onChanged,
                  ),
                ),
              ),
            ),
          ),
        );
      }

      await tester.pumpWidget(buildApp(divisions: 3));

      final RenderBox valueIndicatorBox = tester.renderObject(find.byType(Overlay));

      final Offset topRight = tester.getTopRight(find.byType(RangeSlider)).translate(-24, 0);
      final TestGesture gesture = await tester.startGesture(topRight);
      // Wait for value indicator animation to finish.
      await tester.pumpAndSettle();
      expect(values.end, equals(1));
      expect(
        valueIndicatorBox,
        paints
          ..path(color: Colors.black) // shadow
          ..path(color: Colors.black) // shadow
          ..path(color: sliderTheme.valueIndicatorColor)
          ..paragraph(),
      );
      await gesture.up();
      // Wait for value indicator animation to finish.
      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    'Range Slider removes value indicator from overlay if Slider gets disposed without value indicator animation completing.',
    (WidgetTester tester) async {
      RangeValues values = const RangeValues(0.5, 0.75);
      const Color fillColor = Color(0xf55f5f5f);

      Widget buildApp({
        Color? activeColor,
        Color? inactiveColor,
        int? divisions,
        bool enabled = true,
      }) {
        void onChanged(RangeValues newValues) {
          values = newValues;
        }

        return MaterialApp(
          theme: ThemeData(useMaterial3: false),
          home: Scaffold(
            // The builder is used to pass the context from the MaterialApp widget
            // to the [Navigator]. This context is required in order for the
            // Navigator to work.
            body: Builder(
              builder: (BuildContext context) {
                return Column(
                  children: <Widget>[
                    RangeSlider(
                      values: values,
                      labels: RangeLabels(
                        values.start.toStringAsFixed(2),
                        values.end.toStringAsFixed(2),
                      ),
                      divisions: divisions,
                      onChanged: onChanged,
                    ),
                    ElevatedButton(
                      child: const Text('Next'),
                      onPressed: () {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute<void>(
                            builder: (BuildContext context) {
                              return ElevatedButton(
                                child: const Text('Inner page'),
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ],
                );
              },
            ),
          ),
        );
      }

      await tester.pumpWidget(buildApp(divisions: 3));

      final RenderObject valueIndicatorBox = tester.renderObject(find.byType(Overlay));
      final Offset topRight = tester.getTopRight(find.byType(RangeSlider)).translate(-24, 0);
      final TestGesture gesture = await tester.startGesture(topRight);
      // Wait for value indicator animation to finish.
      await tester.pumpAndSettle();

      expect(
        valueIndicatorBox,
        paints
          // Represents the raised button wth next text.
          ..path(color: Colors.black)
          ..paragraph()
          // Represents the range slider.
          ..path(color: fillColor)
          ..paragraph()
          ..path(color: fillColor)
          ..paragraph(),
      );

      // Represents the Raised Button and Range Slider.
      expect(valueIndicatorBox, paintsExactlyCountTimes(#drawPath, 6));
      expect(valueIndicatorBox, paintsExactlyCountTimes(#drawParagraph, 3));

      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      expect(find.byType(RangeSlider), findsNothing);
      expect(
        valueIndicatorBox,
        isNot(
          paints
            ..path(color: fillColor)
            ..paragraph()
            ..path(color: fillColor)
            ..paragraph(),
        ),
      );

      // Represents the raised button with inner page text.
      expect(valueIndicatorBox, paintsExactlyCountTimes(#drawPath, 2));
      expect(valueIndicatorBox, paintsExactlyCountTimes(#drawParagraph, 1));

      // Don't stop holding the value indicator.
      await gesture.up();
      await tester.pumpAndSettle();
    },
  );

  testWidgets('Range Slider top thumb gets stroked when overlapping', (WidgetTester tester) async {
    RangeValues values = const RangeValues(0.3, 0.7);

    final ThemeData theme = ThemeData(
      platform: TargetPlatform.android,
      primarySwatch: Colors.blue,
      sliderTheme: const SliderThemeData(
        thumbColor: Color(0xff000001),
        overlappingShapeStrokeColor: Color(0xff000002),
      ),
    );
    final SliderThemeData sliderTheme = theme.sliderTheme;

    await tester.pumpWidget(
      MaterialApp(
        home: Directionality(
          textDirection: TextDirection.ltr,
          child: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Material(
                child: Center(
                  child: Theme(
                    data: theme,
                    child: RangeSlider(
                      values: values,
                      onChanged: (RangeValues newValues) {
                        setState(() {
                          values = newValues;
                        });
                      },
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );

    final RenderBox sliderBox = tester.firstRenderObject<RenderBox>(find.byType(RangeSlider));

    // Get the bounds of the track by finding the slider edges and translating
    // inwards by the overlay radius.
    final Offset topLeft = tester.getTopLeft(find.byType(RangeSlider)).translate(24, 0);
    final Offset bottomRight = tester.getBottomRight(find.byType(RangeSlider)).translate(-24, 0);
    final Offset middle = topLeft + bottomRight / 2;

    // Drag the thumbs towards the center.
    final Offset leftTarget = topLeft + (bottomRight - topLeft) * 0.3;
    await tester.dragFrom(leftTarget, middle - leftTarget);
    await tester.pumpAndSettle();
    final Offset rightTarget = topLeft + (bottomRight - topLeft) * 0.7;
    await tester.dragFrom(rightTarget, middle - rightTarget);
    expect(values.start, moreOrLessEquals(0.5, epsilon: 0.03));
    expect(values.end, moreOrLessEquals(0.5, epsilon: 0.03));
    await tester.pumpAndSettle();

    expect(
      sliderBox,
      paints
        ..circle(color: sliderTheme.thumbColor)
        ..circle(color: sliderTheme.overlappingShapeStrokeColor)
        ..circle(color: sliderTheme.thumbColor),
    );
  });

  testWidgets('Range Slider top value indicator gets stroked when overlapping', (
    WidgetTester tester,
  ) async {
    RangeValues values = const RangeValues(0.3, 0.7);

    final ThemeData theme = ThemeData(
      platform: TargetPlatform.android,
      primarySwatch: Colors.blue,
      sliderTheme: const SliderThemeData(
        valueIndicatorColor: Color(0xff000001),
        overlappingShapeStrokeColor: Color(0xff000002),
        showValueIndicator: ShowValueIndicator.always,
      ),
    );
    final SliderThemeData sliderTheme = theme.sliderTheme;

    await tester.pumpWidget(
      MaterialApp(
        home: Directionality(
          textDirection: TextDirection.ltr,
          child: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Material(
                child: Center(
                  child: Theme(
                    data: theme,
                    child: RangeSlider(
                      values: values,
                      labels: RangeLabels(
                        values.start.toStringAsFixed(2),
                        values.end.toStringAsFixed(2),
                      ),
                      onChanged: (RangeValues newValues) {
                        setState(() {
                          values = newValues;
                        });
                      },
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );

    final RenderBox valueIndicatorBox = tester.renderObject(find.byType(Overlay));

    // Get the bounds of the track by finding the slider edges and translating
    // inwards by the overlay radius.
    final Offset topLeft = tester.getTopLeft(find.byType(RangeSlider)).translate(24, 0);
    final Offset bottomRight = tester.getBottomRight(find.byType(RangeSlider)).translate(-24, 0);
    final Offset middle = topLeft + bottomRight / 2;

    // Drag the thumbs towards the center.
    final Offset leftTarget = topLeft + (bottomRight - topLeft) * 0.3;
    await tester.dragFrom(leftTarget, middle - leftTarget);
    await tester.pumpAndSettle();
    final Offset rightTarget = topLeft + (bottomRight - topLeft) * 0.7;
    await tester.dragFrom(rightTarget, middle - rightTarget);
    await tester.pumpAndSettle();
    expect(values.start, moreOrLessEquals(0.5, epsilon: 0.03));
    expect(values.end, moreOrLessEquals(0.5, epsilon: 0.03));
    final TestGesture gesture = await tester.startGesture(middle);
    await tester.pumpAndSettle();

    expect(
      valueIndicatorBox,
      paints
        ..path(color: Colors.black) // shadow
        ..path(color: Colors.black) // shadow
        ..path(color: sliderTheme.valueIndicatorColor)
        ..paragraph(),
    );

    await gesture.up();
  });

  testWidgets(
    'Range Slider top value indicator gets stroked when overlapping with large text scale',
    (WidgetTester tester) async {
      RangeValues values = const RangeValues(0.3, 0.7);

      final ThemeData theme = ThemeData(
        platform: TargetPlatform.android,
        primarySwatch: Colors.blue,
        sliderTheme: const SliderThemeData(
          valueIndicatorColor: Color(0xff000001),
          overlappingShapeStrokeColor: Color(0xff000002),
          showValueIndicator: ShowValueIndicator.always,
        ),
      );
      final SliderThemeData sliderTheme = theme.sliderTheme;

      await tester.pumpWidget(
        MaterialApp(
          home: Directionality(
            textDirection: TextDirection.ltr,
            child: StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) {
                return MediaQuery(
                  data: const MediaQueryData(textScaler: TextScaler.linear(2)),
                  child: Material(
                    child: Center(
                      child: Theme(
                        data: theme,
                        child: RangeSlider(
                          values: values,
                          labels: RangeLabels(
                            values.start.toStringAsFixed(2),
                            values.end.toStringAsFixed(2),
                          ),
                          onChanged: (RangeValues newValues) {
                            setState(() {
                              values = newValues;
                            });
                          },
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      );

      final RenderBox valueIndicatorBox = tester.renderObject(find.byType(Overlay));

      // Get the bounds of the track by finding the slider edges and translating
      // inwards by the overlay radius.
      final Offset topLeft = tester.getTopLeft(find.byType(RangeSlider)).translate(24, 0);
      final Offset bottomRight = tester.getBottomRight(find.byType(RangeSlider)).translate(-24, 0);
      final Offset middle = topLeft + bottomRight / 2;

      // Drag the thumbs towards the center.
      final Offset leftTarget = topLeft + (bottomRight - topLeft) * 0.3;
      await tester.dragFrom(leftTarget, middle - leftTarget);
      await tester.pumpAndSettle();
      final Offset rightTarget = topLeft + (bottomRight - topLeft) * 0.7;
      await tester.dragFrom(rightTarget, middle - rightTarget);
      await tester.pumpAndSettle();
      expect(values.start, moreOrLessEquals(0.5, epsilon: 0.03));
      expect(values.end, moreOrLessEquals(0.5, epsilon: 0.03));
      final TestGesture gesture = await tester.startGesture(middle);
      await tester.pumpAndSettle();

      expect(
        valueIndicatorBox,
        paints
          ..path(color: Colors.black) // shadow
          ..path(color: Colors.black) // shadow
          ..path(color: sliderTheme.valueIndicatorColor)
          ..paragraph(),
      );

      await gesture.up();
    },
  );

  testWidgets('Range Slider thumb gets stroked when overlapping', (WidgetTester tester) async {
    RangeValues values = const RangeValues(0.3, 0.7);

    final ThemeData theme = ThemeData(
      platform: TargetPlatform.android,
      primarySwatch: Colors.blue,
      sliderTheme: const SliderThemeData(
        valueIndicatorColor: Color(0xff000001),
        showValueIndicator: ShowValueIndicator.onlyForContinuous,
      ),
    );
    final SliderThemeData sliderTheme = theme.sliderTheme;

    await tester.pumpWidget(
      MaterialApp(
        home: Directionality(
          textDirection: TextDirection.ltr,
          child: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Material(
                child: Center(
                  child: Theme(
                    data: theme,
                    child: RangeSlider(
                      values: values,
                      labels: RangeLabels(
                        values.start.toStringAsFixed(2),
                        values.end.toStringAsFixed(2),
                      ),
                      onChanged: (RangeValues newValues) {
                        setState(() {
                          values = newValues;
                        });
                      },
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );

    // Get the bounds of the track by finding the slider edges and translating
    // inwards by the overlay radius.
    final Offset topLeft = tester.getTopLeft(find.byType(RangeSlider)).translate(24, 0);
    final Offset bottomRight = tester.getBottomRight(find.byType(RangeSlider)).translate(-24, 0);
    final Offset middle = topLeft + bottomRight / 2;

    // Drag the thumbs towards the center.
    final Offset leftTarget = topLeft + (bottomRight - topLeft) * 0.3;
    await tester.dragFrom(leftTarget, middle - leftTarget);
    await tester.pumpAndSettle();
    final Offset rightTarget = topLeft + (bottomRight - topLeft) * 0.7;
    await tester.dragFrom(rightTarget, middle - rightTarget);
    await tester.pumpAndSettle();
    expect(values.start, moreOrLessEquals(0.5, epsilon: 0.03));
    expect(values.end, moreOrLessEquals(0.5, epsilon: 0.03));
    final TestGesture gesture = await tester.startGesture(middle);
    await tester.pumpAndSettle();

    /// The first circle is the thumb, the second one is the overlapping shape
    /// circle, and the last one is the second thumb.
    expect(
      find.byType(RangeSlider),
      paints
        ..circle()
        ..circle(color: sliderTheme.overlappingShapeStrokeColor)
        ..circle(),
    );

    await gesture.up();

    expect(
      find.byType(RangeSlider),
      paints
        ..circle()
        ..circle(color: sliderTheme.overlappingShapeStrokeColor)
        ..circle(),
    );
  });

  // Regression test for https://github.com/flutter/flutter/issues/101868
  testWidgets('RangeSlider.label info should not write to semantic node', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Theme(
          data: ThemeData(),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Material(
              child: RangeSlider(
                values: const RangeValues(10.0, 12.0),
                max: 100.0,
                onChanged: (RangeValues v) {},
                labels: const RangeLabels('Begin', 'End'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(
      tester.getSemantics(find.byType(RangeSlider)),
      matchesSemantics(
        scopesRoute: true,
        children: <Matcher>[
          matchesSemantics(
            children: <Matcher>[
              matchesSemantics(
                isEnabled: true,
                isSlider: true,
                isFocusable: true,
                hasEnabledState: true,
                hasIncreaseAction: true,
                hasDecreaseAction: true,
                value: '10%',
                increasedValue: '10%',
                decreasedValue: '5%',
                label: '',
              ),
              matchesSemantics(
                isEnabled: true,
                isSlider: true,
                isFocusable: true,
                hasEnabledState: true,
                hasIncreaseAction: true,
                hasDecreaseAction: true,
                value: '12%',
                increasedValue: '17%',
                decreasedValue: '12%',
                label: '',
              ),
            ],
          ),
        ],
      ),
    );
  });

  testWidgets('Range Slider Semantics - ltr', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Theme(
          data: ThemeData(),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Material(
              child: RangeSlider(
                values: const RangeValues(10.0, 30.0),
                max: 100.0,
                onChanged: (RangeValues v) {},
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final SemanticsNode semanticsNode = tester.getSemantics(find.byType(RangeSlider));
    expect(
      semanticsNode,
      matchesSemantics(
        scopesRoute: true,
        children: <Matcher>[
          matchesSemantics(
            children: <Matcher>[
              matchesSemantics(
                isEnabled: true,
                isSlider: true,
                isFocusable: true,
                hasEnabledState: true,
                hasIncreaseAction: true,
                hasDecreaseAction: true,
                value: '10%',
                increasedValue: '15%',
                decreasedValue: '5%',
                rect: const Rect.fromLTRB(75.2, 276.0, 123.2, 324.0),
              ),
              matchesSemantics(
                isEnabled: true,
                isSlider: true,
                isFocusable: true,
                hasEnabledState: true,
                hasIncreaseAction: true,
                hasDecreaseAction: true,
                value: '30%',
                increasedValue: '35%',
                decreasedValue: '25%',
                rect: const Rect.fromLTRB(225.6, 276.0, 273.6, 324.0),
              ),
            ],
          ),
        ],
      ),
    );

    // TODO(tahatesser): This is a workaround for matching
    // the semantics node rects by avoiding floating point errors.
    // https://github.com/flutter/flutter/issues/115079
    // Get semantics node rects.
    final List<Rect> rects = <Rect>[];
    semanticsNode.visitChildren((SemanticsNode node) {
      node.visitChildren((SemanticsNode node) {
        // Round rect values to avoid floating point errors.
        rects.add(
          Rect.fromLTRB(
            node.rect.left.roundToDouble(),
            node.rect.top.roundToDouble(),
            node.rect.right.roundToDouble(),
            node.rect.bottom.roundToDouble(),
          ),
        );
        return true;
      });
      return true;
    });
    // Test that the semantics node rect sizes are correct.
    expect(rects, <Rect>[
      const Rect.fromLTRB(75.0, 276.0, 123.0, 324.0),
      const Rect.fromLTRB(226.0, 276.0, 274.0, 324.0),
    ]);
  });

  testWidgets('Range Slider Semantics - rtl', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Theme(
          data: ThemeData(),
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: Material(
              child: RangeSlider(
                values: const RangeValues(10.0, 30.0),
                max: 100.0,
                onChanged: (RangeValues v) {},
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final SemanticsNode semanticsNode = tester.getSemantics(find.byType(RangeSlider));
    expect(
      semanticsNode,
      matchesSemantics(
        scopesRoute: true,
        children: <Matcher>[
          matchesSemantics(
            children: <Matcher>[
              matchesSemantics(
                isEnabled: true,
                isSlider: true,
                isFocusable: true,
                hasEnabledState: true,
                hasIncreaseAction: true,
                hasDecreaseAction: true,
                value: '10%',
                increasedValue: '15%',
                decreasedValue: '5%',
              ),
              matchesSemantics(
                isEnabled: true,
                isSlider: true,
                isFocusable: true,
                hasEnabledState: true,
                hasIncreaseAction: true,
                hasDecreaseAction: true,
                value: '30%',
                increasedValue: '35%',
                decreasedValue: '25%',
              ),
            ],
          ),
        ],
      ),
    );

    // TODO(tahatesser): This is a workaround for matching
    // the semantics node rects by avoiding floating point errors.
    // https://github.com/flutter/flutter/issues/115079
    // Get semantics node rects.
    final List<Rect> rects = <Rect>[];
    semanticsNode.visitChildren((SemanticsNode node) {
      node.visitChildren((SemanticsNode node) {
        // Round rect values to avoid floating point errors.
        rects.add(
          Rect.fromLTRB(
            node.rect.left.roundToDouble(),
            node.rect.top.roundToDouble(),
            node.rect.right.roundToDouble(),
            node.rect.bottom.roundToDouble(),
          ),
        );
        return true;
      });
      return true;
    });
    // Test that the semantics node rect sizes are correct.
    expect(rects, <Rect>[
      const Rect.fromLTRB(526.0, 276.0, 574.0, 324.0),
      const Rect.fromLTRB(677.0, 276.0, 725.0, 324.0),
    ]);
  });

  testWidgets('Range Slider implements debugFillProperties', (WidgetTester tester) async {
    final DiagnosticPropertiesBuilder builder = DiagnosticPropertiesBuilder();

    RangeSlider(
      activeColor: Colors.blue,
      divisions: 4,
      inactiveColor: Colors.grey,
      labels: const RangeLabels('lowerValue', 'upperValue'),
      max: 100.0,
      onChanged: null,
      values: const RangeValues(25.0, 75.0),
    ).debugFillProperties(builder);

    final List<String> description = builder.properties
        .where((DiagnosticsNode node) => !node.isFiltered(DiagnosticLevel.info))
        .map((DiagnosticsNode node) => node.toString())
        .toList();

    expect(description, <String>[
      'valueStart: 25.0',
      'valueEnd: 75.0',
      'disabled',
      'min: 0.0',
      'max: 100.0',
      'divisions: 4',
      'labelStart: "lowerValue"',
      'labelEnd: "upperValue"',
      'activeColor: MaterialColor(primary value: ${const Color(0xff2196f3)})',
      'inactiveColor: MaterialColor(primary value: ${const Color(0xff9e9e9e)})',
    ]);
  });

  testWidgets(
    'Range Slider can be painted in a narrower constraint when track shape is RoundedRectRange',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Directionality(
            textDirection: TextDirection.ltr,
            child: Material(
              child: Center(
                child: SizedBox(
                  height: 10.0,
                  width: 0.0,
                  child: RangeSlider(values: const RangeValues(0.25, 0.5), onChanged: null),
                ),
              ),
            ),
          ),
        ),
      );

      final RenderObject renderObject = tester.allRenderObjects
          .where(
            (RenderObject renderObject) =>
                renderObject.runtimeType.toString() == '_RenderRangeSlider',
          )
          .first;

      expect(
        renderObject,
        paints
          // left inactive track RRect
          ..rrect(
            rrect: RRect.fromLTRBAndCorners(
              -24.0,
              3.0,
              -12.0,
              7.0,
              topLeft: const Radius.circular(2.0),
              bottomLeft: const Radius.circular(2.0),
            ),
          )
          // right inactive track RRect
          ..rrect(
            rrect: RRect.fromLTRBAndCorners(
              0.0,
              3.0,
              24.0,
              7.0,
              topRight: const Radius.circular(2.0),
              bottomRight: const Radius.circular(2.0),
            ),
          )
          // active track RRect
          ..rrect(rrect: RRect.fromLTRBR(-14.0, 2.0, 2.0, 8.0, const Radius.circular(2.0)))
          // thumbs
          ..circle(x: -12.0, y: 5.0, radius: 10.0)
          ..circle(x: 0.0, y: 5.0, radius: 10.0),
      );
    },
  );

  testWidgets(
    'Range Slider can be painted in a narrower constraint when track shape is Rectangular',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            sliderTheme: const SliderThemeData(rangeTrackShape: RectangularRangeSliderTrackShape()),
          ),
          home: Directionality(
            textDirection: TextDirection.ltr,
            child: Material(
              child: Center(
                child: SizedBox(
                  height: 10.0,
                  width: 0.0,
                  child: RangeSlider(values: const RangeValues(0.25, 0.5), onChanged: null),
                ),
              ),
            ),
          ),
        ),
      );

      final RenderObject renderObject = tester.allRenderObjects
          .where(
            (RenderObject renderObject) =>
                renderObject.runtimeType.toString() == '_RenderRangeSlider',
          )
          .first;

      //There should no gap between the inactive track and active track.
      expect(
        renderObject,
        paints
          // left inactive track RRect
          ..rect(rect: const Rect.fromLTRB(-24.0, 3.0, -12.0, 7.0))
          // active track RRect
          ..rect(rect: const Rect.fromLTRB(-12.0, 3.0, 0.0, 7.0))
          // right inactive track RRect
          ..rect(rect: const Rect.fromLTRB(0.0, 3.0, 24.0, 7.0))
          // thumbs
          ..circle(x: -12.0, y: 5.0, radius: 10.0)
          ..circle(x: 0.0, y: 5.0, radius: 10.0),
      );
    },
  );

  testWidgets('Update the divisions and values at the same time for RangeSlider', (
    WidgetTester tester,
  ) async {
    // Regress test for https://github.com/flutter/flutter/issues/65943
    Widget buildFrame(double maxValue) {
      return MaterialApp(
        home: Material(
          child: Center(
            child: RangeSlider(
              values: const RangeValues(5, 8),
              max: maxValue,
              divisions: maxValue.toInt(),
              onChanged: (RangeValues newValue) {},
            ),
          ),
        ),
      );
    }

    await tester.pumpWidget(buildFrame(10));

    final RenderObject renderObject = tester.allRenderObjects
        .where(
          (RenderObject renderObject) =>
              renderObject.runtimeType.toString() == '_RenderRangeSlider',
        )
        .first;

    // Update the divisions from 10 to 15, the thumbs should be paint at the correct position.
    await tester.pumpWidget(buildFrame(15));
    await tester.pumpAndSettle(); // Finish the animation.

    late RRect activeTrackRRect;
    expect(
      renderObject,
      paints
        ..rrect()
        ..rrect()
        ..something((Symbol method, List<dynamic> arguments) {
          if (method != #drawRRect) {
            return false;
          }
          activeTrackRRect = arguments[0] as RRect;
          return true;
        }),
    );

    const double padding = 4.0;
    // The 1st thumb should at one-third(5 / 15) of the Slider.
    // The 2nd thumb should at (8 / 15) of the Slider.
    // The left of the active track shape is the position of the 1st thumb.
    // The right of the active track shape is the position of the 2nd thumb.
    // 24.0 is the default margin, (800.0 - 24.0 - 24.0 - padding) is the slider's width.
    // Where the padding value equals to the track height.
    expect(
      nearEqual(activeTrackRRect.left, (800.0 - 24.0 - 24.0 - padding) * (5 / 15) + 24.0, 0.01),
      true,
    );
    expect(
      nearEqual(
        activeTrackRRect.right,
        (800.0 - 24.0 - 24.0 - padding) * (8 / 15) + 24.0 + padding,
        0.01,
      ),
      true,
    );
  });

  testWidgets('RangeSlider changes mouse cursor when hovered', (WidgetTester tester) async {
    const RangeValues values = RangeValues(50, 70);

    // Test default cursor.
    await tester.pumpWidget(
      MaterialApp(
        home: Directionality(
          textDirection: TextDirection.ltr,
          child: Material(
            child: Center(
              child: MouseRegion(
                cursor: SystemMouseCursors.forbidden,
                child: RangeSlider(values: values, max: 100.0, onChanged: (RangeValues values) {}),
              ),
            ),
          ),
        ),
      ),
    );

    final TestGesture gesture = await tester.createGesture(
      kind: PointerDeviceKind.mouse,
      pointer: 1,
    );
    await gesture.addPointer(location: tester.getCenter(find.byType(RangeSlider)));

    expect(
      RendererBinding.instance.mouseTracker.debugDeviceActiveCursor(1),
      SystemMouseCursors.click,
    );

    // Test custom cursor.
    await tester.pumpWidget(
      MaterialApp(
        home: Directionality(
          textDirection: TextDirection.ltr,
          child: Material(
            child: Center(
              child: MouseRegion(
                cursor: SystemMouseCursors.forbidden,
                child: RangeSlider(
                  values: values,
                  max: 100.0,
                  mouseCursor: const MaterialStatePropertyAll<MouseCursor?>(
                    SystemMouseCursors.text,
                  ),
                  onChanged: (RangeValues values) {},
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pump();
    expect(
      RendererBinding.instance.mouseTracker.debugDeviceActiveCursor(1),
      SystemMouseCursors.text,
    );
  });

  testWidgets('RangeSlider MaterialStateMouseCursor resolves correctly', (
    WidgetTester tester,
  ) async {
    RangeValues values = const RangeValues(50, 70);
    const MouseCursor disabledCursor = SystemMouseCursors.basic;
    const MouseCursor hoveredCursor = SystemMouseCursors.grab;
    const MouseCursor draggedCursor = SystemMouseCursors.move;

    Widget buildFrame({required bool enabled}) {
      return MaterialApp(
        home: Directionality(
          textDirection: TextDirection.ltr,
          child: Material(
            child: StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) {
                return Center(
                  child: MouseRegion(
                    cursor: SystemMouseCursors.forbidden,
                    child: RangeSlider(
                      mouseCursor: MaterialStateProperty.resolveWith<MouseCursor?>((
                        Set<MaterialState> states,
                      ) {
                        if (states.contains(MaterialState.disabled)) {
                          return disabledCursor;
                        }
                        if (states.contains(MaterialState.dragged)) {
                          return draggedCursor;
                        }
                        if (states.contains(MaterialState.hovered)) {
                          return hoveredCursor;
                        }

                        return SystemMouseCursors.none;
                      }),
                      values: values,
                      max: 100.0,
                      onChanged: enabled
                          ? (RangeValues newValues) {
                              setState(() {
                                values = newValues;
                              });
                            }
                          : null,
                      onChangeStart: enabled ? (RangeValues newValues) {} : null,
                      onChangeEnd: enabled ? (RangeValues newValues) {} : null,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      );
    }

    final TestGesture gesture = await tester.createGesture(
      kind: PointerDeviceKind.mouse,
      pointer: 1,
    );
    await gesture.addPointer(location: Offset.zero);

    await tester.pumpWidget(buildFrame(enabled: false));
    expect(RendererBinding.instance.mouseTracker.debugDeviceActiveCursor(1), disabledCursor);

    await tester.pumpWidget(buildFrame(enabled: true));
    await gesture.moveTo(tester.getCenter(find.byType(RangeSlider))); // start hover
    await tester.pumpAndSettle();
    expect(RendererBinding.instance.mouseTracker.debugDeviceActiveCursor(1), hoveredCursor);

    await tester.timedDrag(
      find.byType(RangeSlider),
      const Offset(20.0, 0.0),
      const Duration(milliseconds: 100),
    );
    expect(RendererBinding.instance.mouseTracker.debugDeviceActiveCursor(1), draggedCursor);
  });

  testWidgets('RangeSlider can be hovered and has correct hover color', (
    WidgetTester tester,
  ) async {
    tester.binding.focusManager.highlightStrategy = FocusHighlightStrategy.alwaysTraditional;
    RangeValues values = const RangeValues(50, 70);
    final ThemeData theme = ThemeData();

    Widget buildApp({bool enabled = true}) {
      return MaterialApp(
        home: Directionality(
          textDirection: TextDirection.ltr,
          child: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Material(
                child: Center(
                  child: RangeSlider(
                    values: values,
                    max: 100.0,
                    onChanged: enabled
                        ? (RangeValues newValues) {
                            setState(() {
                              values = newValues;
                            });
                          }
                        : null,
                  ),
                ),
              );
            },
          ),
        ),
      );
    }

    await tester.pumpWidget(buildApp());

    // RangeSlider does not have overlay when enabled and not hovered.
    await tester.pumpAndSettle();
    expect(
      Material.of(tester.element(find.byType(RangeSlider))),
      isNot(paints..circle(color: theme.colorScheme.primary.withOpacity(0.12))),
    );

    // Start hovering.
    final TestGesture gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer();
    await gesture.moveTo(tester.getCenter(find.byType(RangeSlider)));

    // RangeSlider has overlay when enabled and hovered.
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();
    expect(
      Material.of(tester.element(find.byType(RangeSlider))),
      paints..circle(color: theme.colorScheme.primary.withOpacity(0.12)),
    );

    // RangeSlider does not have an overlay when disabled and hovered.
    await tester.pumpWidget(buildApp(enabled: false));
    await tester.pumpAndSettle();
    expect(
      Material.of(tester.element(find.byType(RangeSlider))),
      isNot(paints..circle(color: theme.colorScheme.primary.withOpacity(0.12))),
    );
  });

  testWidgets('RangeSlider can be focused using keyboard focus', (WidgetTester tester) async {
    RangeValues values = const RangeValues(20, 80);
    await tester.pumpWidget(
      MaterialApp(
        home: Directionality(
          textDirection: TextDirection.ltr,
          child: Material(
            child: StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) {
                return Center(
                  child: RangeSlider(
                    values: values,
                    max: 100,
                    onChanged: (RangeValues newValues) {
                      setState(() {
                        values = newValues;
                      });
                    },
                    onChangeStart: (RangeValues newValues) {},
                    onChangeEnd: (RangeValues newValues) {},
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
    // Focus on the start thumb
    final Finder rangeSliderFinder = find.byType(RangeSlider);
    expect(rangeSliderFinder, findsOneWidget);
    final FocusNode startFocusNode =
        (tester.firstState(find.byType(RangeSlider)) as dynamic).startFocusNode as FocusNode;
    final FocusNode endFocusNode =
        (tester.firstState(find.byType(RangeSlider)) as dynamic).endFocusNode as FocusNode;

    startFocusNode.requestFocus();
    await tester.pumpAndSettle();
    expect(FocusManager.instance.primaryFocus, startFocusNode);

    // Tab to focus on the end thumb
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    expect(FocusManager.instance.primaryFocus, endFocusNode);
  });

  testWidgets('Keyboard focus also changes semantics focus', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Theme(
          data: ThemeData(),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Material(
              child: RangeSlider(
                values: const RangeValues(10.0, 30.0),
                max: 100.0,
                onChanged: (RangeValues v) {},
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    final FocusNode startFocusNode =
        (tester.firstState(find.byType(RangeSlider)) as dynamic).startFocusNode as FocusNode;
    final FocusNode endFocusNode =
        (tester.firstState(find.byType(RangeSlider)) as dynamic).endFocusNode as FocusNode;
    // Focus on the start thumb
    startFocusNode.requestFocus();
    await tester.pumpAndSettle();
    expect(FocusManager.instance.primaryFocus, startFocusNode);

    final SemanticsNode semanticsNode = tester.getSemantics(find.byType(RangeSlider));
    expect(
      semanticsNode,
      matchesSemantics(
        scopesRoute: true,
        children: <Matcher>[
          matchesSemantics(
            children: <Matcher>[
              matchesSemantics(
                isEnabled: true,
                isSlider: true,
                isFocusable: true,
                isFocused: true,
                hasEnabledState: true,
                hasIncreaseAction: true,
                hasDecreaseAction: true,
                value: '10%',
                increasedValue: '15%',
                decreasedValue: '5%',
                rect: const Rect.fromLTRB(75.2, 276.0, 123.2, 324.0),
              ),
              matchesSemantics(
                isEnabled: true,
                isSlider: true,
                isFocusable: true,
                hasEnabledState: true,
                hasIncreaseAction: true,
                hasDecreaseAction: true,
                value: '30%',
                increasedValue: '35%',
                decreasedValue: '25%',
                rect: const Rect.fromLTRB(225.6, 276.0, 273.6, 324.0),
              ),
            ],
          ),
        ],
      ),
    );

    // Tab to focus on the end thumb
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    expect(FocusManager.instance.primaryFocus, endFocusNode);

    expect(
      semanticsNode,
      matchesSemantics(
        scopesRoute: true,
        children: <Matcher>[
          matchesSemantics(
            children: <Matcher>[
              matchesSemantics(
                isEnabled: true,
                isSlider: true,
                isFocusable: true,
                hasEnabledState: true,
                hasIncreaseAction: true,
                hasDecreaseAction: true,
                value: '10%',
                increasedValue: '15%',
                decreasedValue: '5%',
                rect: const Rect.fromLTRB(75.2, 276.0, 123.2, 324.0),
              ),
              matchesSemantics(
                isEnabled: true,
                isSlider: true,
                isFocusable: true,
                isFocused: true,
                hasEnabledState: true,
                hasIncreaseAction: true,
                hasDecreaseAction: true,
                value: '30%',
                increasedValue: '35%',
                decreasedValue: '25%',
                rect: const Rect.fromLTRB(225.6, 276.0, 273.6, 324.0),
              ),
            ],
          ),
        ],
      ),
    );
  });

  testWidgets('RangeSlider is draggable and has correct dragged color', (
    WidgetTester tester,
  ) async {
    tester.binding.focusManager.highlightStrategy = FocusHighlightStrategy.alwaysTraditional;
    RangeValues values = const RangeValues(50, 70);
    final ThemeData theme = ThemeData();

    Widget buildApp({bool enabled = true}) {
      return MaterialApp(
        home: Directionality(
          textDirection: TextDirection.ltr,
          child: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Material(
                child: Center(
                  child: RangeSlider(
                    values: values,
                    max: 100.0,
                    onChanged: enabled
                        ? (RangeValues newValues) {
                            setState(() {
                              values = newValues;
                            });
                          }
                        : null,
                  ),
                ),
              );
            },
          ),
        ),
      );
    }

    await tester.pumpWidget(buildApp());

    // RangeSlider does not have overlay when enabled and not dragged.
    await tester.pumpAndSettle();
    expect(
      Material.of(tester.element(find.byType(RangeSlider))),
      isNot(paints..circle(color: theme.colorScheme.primary.withOpacity(0.12))),
    );

    // Start dragging.
    final TestGesture drag = await tester.startGesture(tester.getCenter(find.byType(RangeSlider)));
    await tester.pump(kPressTimeout);

    // Less than configured touch slop, more than default touch slop
    await drag.moveBy(const Offset(19.0, 0));
    await tester.pump();

    // RangeSlider has overlay when enabled and dragged.
    expect(
      Material.of(tester.element(find.byType(RangeSlider))),
      paints..circle(color: theme.colorScheme.primary.withOpacity(0.12)),
    );
  });

  testWidgets('RangeSlider overlayColor supports hovered and dragged states', (
    WidgetTester tester,
  ) async {
    tester.binding.focusManager.highlightStrategy = FocusHighlightStrategy.alwaysTraditional;
    RangeValues values = const RangeValues(50, 70);
    const Color hoverColor = Color(0xffff0000);
    const Color draggedColor = Color(0xff0000ff);

    Widget buildApp({bool enabled = true}) {
      return MaterialApp(
        home: Directionality(
          textDirection: TextDirection.ltr,
          child: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Material(
                child: Center(
                  child: RangeSlider(
                    values: values,
                    max: 100.0,
                    overlayColor: MaterialStateProperty.resolveWith<Color?>((
                      Set<MaterialState> states,
                    ) {
                      if (states.contains(MaterialState.hovered)) {
                        return hoverColor;
                      }
                      if (states.contains(MaterialState.dragged)) {
                        return draggedColor;
                      }

                      return null;
                    }),
                    onChanged: enabled
                        ? (RangeValues newValues) {
                            setState(() {
                              values = newValues;
                            });
                          }
                        : null,
                    onChangeStart: enabled ? (RangeValues newValues) {} : null,
                    onChangeEnd: enabled ? (RangeValues newValues) {} : null,
                  ),
                ),
              );
            },
          ),
        ),
      );
    }

    await tester.pumpWidget(buildApp());

    // RangeSlider does not have overlay when enabled and not hovered.
    await tester.pumpAndSettle();
    expect(
      Material.of(tester.element(find.byType(RangeSlider))),
      isNot(paints..circle(color: hoverColor)),
    );

    // Hover on the range slider but outside the thumb.
    final TestGesture gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer();
    await gesture.moveTo(tester.getTopLeft(find.byType(RangeSlider)));

    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();
    expect(
      Material.of(tester.element(find.byType(RangeSlider))),
      isNot(paints..circle(color: hoverColor)),
    );

    // Hover on the thumb.
    await gesture.moveTo(tester.getCenter(find.byType(RangeSlider)));
    await tester.pumpAndSettle();
    expect(
      Material.of(tester.element(find.byType(RangeSlider))),
      paints..circle(color: hoverColor),
    );

    // Hover on the slider but outside the thumb.
    await gesture.moveTo(tester.getBottomRight(find.byType(RangeSlider)));
    await tester.pumpAndSettle();
    expect(
      Material.of(tester.element(find.byType(RangeSlider))),
      isNot(paints..circle(color: hoverColor)),
    );

    // Reset range slider values.
    values = const RangeValues(50, 70);

    // RangeSlider does not have overlay when enabled and not dragged.
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();
    expect(
      Material.of(tester.element(find.byType(RangeSlider))),
      isNot(paints..circle(color: draggedColor)),
    );

    // Start dragging.
    final TestGesture drag = await tester.startGesture(tester.getCenter(find.byType(RangeSlider)));
    await tester.pump(kPressTimeout);

    // Less than configured touch slop, more than default touch slop.
    await drag.moveBy(const Offset(19.0, 0));
    await tester.pump();

    // RangeSlider has overlay when enabled and dragged.
    expect(
      Material.of(tester.element(find.byType(RangeSlider))),
      paints..circle(color: draggedColor),
    );

    // Stop dragging.
    await drag.up();
    await tester.pumpAndSettle();
    expect(
      Material.of(tester.element(find.byType(RangeSlider))),
      isNot(paints..circle(color: draggedColor)),
    );
  });

  testWidgets('RangeSlider onChangeStart and onChangeEnd fire once', (WidgetTester tester) async {
    // Regression test for https://github.com/flutter/flutter/issues/128433

    int startFired = 0;
    int endFired = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Directionality(
          textDirection: TextDirection.ltr,
          child: Material(
            child: Center(
              child: GestureDetector(
                onHorizontalDragUpdate: (_) {},
                child: RangeSlider(
                  values: const RangeValues(40, 80),
                  max: 100,
                  onChanged: (RangeValues newValue) {},
                  onChangeStart: (RangeValues value) {
                    startFired += 1;
                  },
                  onChangeEnd: (RangeValues value) {
                    endFired += 1;
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.timedDragFrom(
      tester.getTopLeft(find.byType(RangeSlider)),
      const Offset(100.0, 0.0),
      const Duration(milliseconds: 500),
    );

    expect(startFired, equals(1));
    expect(endFired, equals(1));
  });

  testWidgets('RangeSlider in a ListView does not throw an exception', (WidgetTester tester) async {
    // Regression test for https://github.com/flutter/flutter/issues/126648

    await tester.pumpWidget(
      MaterialApp(
        home: Directionality(
          textDirection: TextDirection.ltr,
          child: Material(
            child: ListView(
              children: <Widget>[
                const SizedBox(height: 600, child: Placeholder()),
                RangeSlider(
                  values: const RangeValues(40, 80),
                  max: 100,
                  onChanged: (RangeValues newValue) {},
                ),
              ],
            ),
          ),
        ),
      ),
    );

    // No exception should be thrown.
    expect(tester.takeException(), null);
  });

  // This is a regression test for https://github.com/flutter/flutter/issues/141953.
  testWidgets('Semantic nodes do not throw an error after clearSemantics', (
    WidgetTester tester,
  ) async {
    SemanticsTester semantics = SemanticsTester(tester);

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: MaterialApp(
          home: Scaffold(
            body: RangeSlider(
              values: const RangeValues(40, 80),
              max: 100,
              onChanged: (RangeValues newValue) {},
            ),
          ),
        ),
      ),
    );

    // Dispose the semantics to trigger clearSemantics.
    semantics.dispose();
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);

    // Initialize the semantics again.
    semantics = SemanticsTester(tester);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);

    semantics.dispose();
  }, semanticsEnabled: false);

  testWidgets('Value indicator appears when it should', (WidgetTester tester) async {
    final ThemeData baseTheme = ThemeData(
      platform: TargetPlatform.android,
      primarySwatch: Colors.blue,
    );
    SliderThemeData theme = baseTheme.sliderTheme.copyWith(valueIndicatorColor: Colors.red);
    RangeValues value = const RangeValues(1, 5);
    Widget buildApp({required SliderThemeData sliderTheme, int? divisions, bool enabled = true}) {
      final ValueChanged<RangeValues>? onChanged = enabled ? (RangeValues d) => value = d : null;
      return MaterialApp(
        home: Material(
          child: Center(
            child: Theme(
              data: baseTheme,
              child: SliderTheme(
                data: sliderTheme,
                child: RangeSlider(
                  values: value,
                  max: 10,
                  labels: RangeLabels(value.start.toString(), value.end.toString()),
                  divisions: divisions,
                  onChanged: onChanged,
                ),
              ),
            ),
          ),
        ),
      );
    }

    Future<void> expectValueIndicator({
      required bool isVisible,
      required SliderThemeData theme,
      int? divisions,
      bool enabled = true,
      bool dragged = true,
    }) async {
      // Discrete enabled widget.
      await tester.pumpWidget(buildApp(sliderTheme: theme, divisions: divisions, enabled: enabled));
      final Offset center = tester.getCenter(find.byType(RangeSlider));
      TestGesture? gesture;
      if (dragged) {
        gesture = await tester.startGesture(center);
      }
      // Wait for value indicator animation to finish.
      await tester.pumpAndSettle();

      // _RenderValueIndicator is the last render object in the tree.
      final RenderObject valueIndicatorBox = tester.allRenderObjects.last;
      expect(
        valueIndicatorBox,
        isVisible
            ? (paints
                ..path(color: theme.valueIndicatorColor)
                ..paragraph())
            : isNot(
                paints
                  ..path(color: theme.valueIndicatorColor)
                  ..paragraph(),
              ),
      );
      if (dragged) {
        await gesture!.up();
      }
    }

    // Default (showValueIndicator set to onlyForDiscrete).
    await expectValueIndicator(isVisible: true, theme: theme, divisions: 10);
    await expectValueIndicator(isVisible: false, theme: theme, divisions: 10, enabled: false);
    await expectValueIndicator(isVisible: false, theme: theme);
    await expectValueIndicator(isVisible: false, theme: theme, enabled: false);
    await expectValueIndicator(isVisible: false, theme: theme, divisions: 10, dragged: false);
    await expectValueIndicator(
      isVisible: false,
      theme: theme,
      divisions: 3,
      enabled: false,
      dragged: false,
    );
    await expectValueIndicator(isVisible: false, theme: theme, dragged: false);
    await expectValueIndicator(isVisible: false, theme: theme, enabled: false, dragged: false);

    // With showValueIndicator set to onlyForContinuous.
    theme = theme.copyWith(showValueIndicator: ShowValueIndicator.onlyForContinuous);
    await expectValueIndicator(isVisible: false, theme: theme, divisions: 10);
    await expectValueIndicator(isVisible: false, theme: theme, divisions: 10, enabled: false);
    await expectValueIndicator(isVisible: true, theme: theme);
    await expectValueIndicator(isVisible: false, theme: theme, enabled: false);
    await expectValueIndicator(isVisible: false, theme: theme, divisions: 10, dragged: false);
    await expectValueIndicator(
      isVisible: false,
      theme: theme,
      divisions: 3,
      enabled: false,
      dragged: false,
    );
    await expectValueIndicator(isVisible: false, theme: theme, dragged: false);
    await expectValueIndicator(isVisible: false, theme: theme, enabled: false, dragged: false);

    // discrete enabled widget with showValueIndicator set to onDrag.
    theme = theme.copyWith(showValueIndicator: ShowValueIndicator.onDrag);
    await expectValueIndicator(isVisible: true, theme: theme, divisions: 10);
    await expectValueIndicator(isVisible: false, theme: theme, divisions: 10, enabled: false);
    await expectValueIndicator(isVisible: true, theme: theme);
    await expectValueIndicator(isVisible: false, theme: theme, enabled: false);
    await expectValueIndicator(isVisible: false, theme: theme, divisions: 10, dragged: false);
    await expectValueIndicator(
      isVisible: false,
      theme: theme,
      divisions: 3,
      enabled: false,
      dragged: false,
    );
    await expectValueIndicator(isVisible: false, theme: theme, dragged: false);
    await expectValueIndicator(isVisible: false, theme: theme, enabled: false, dragged: false);

    // discrete enabled widget with showValueIndicator set to never.
    theme = theme.copyWith(showValueIndicator: ShowValueIndicator.never);
    await expectValueIndicator(isVisible: false, theme: theme, divisions: 10);
    await expectValueIndicator(isVisible: false, theme: theme, divisions: 10, enabled: false);
    await expectValueIndicator(isVisible: false, theme: theme);
    await expectValueIndicator(isVisible: false, theme: theme, enabled: false);
    await expectValueIndicator(isVisible: false, theme: theme, divisions: 10, dragged: false);
    await expectValueIndicator(
      isVisible: false,
      theme: theme,
      divisions: 3,
      enabled: false,
      dragged: false,
    );
    await expectValueIndicator(isVisible: false, theme: theme, dragged: false);
    await expectValueIndicator(isVisible: false, theme: theme, enabled: false, dragged: false);

    // discrete enabled widget with showValueIndicator set to alwaysVisible.
    theme = theme.copyWith(showValueIndicator: ShowValueIndicator.alwaysVisible);
    await expectValueIndicator(isVisible: true, theme: theme, divisions: 3);
    await expectValueIndicator(isVisible: true, theme: theme, divisions: 3, enabled: false);
    await expectValueIndicator(isVisible: true, theme: theme);
    await expectValueIndicator(isVisible: true, theme: theme, enabled: false);
    await expectValueIndicator(isVisible: true, theme: theme, divisions: 3, dragged: false);
    await expectValueIndicator(
      isVisible: true,
      theme: theme,
      divisions: 3,
      enabled: false,
      dragged: false,
    );
    await expectValueIndicator(isVisible: true, theme: theme, dragged: false);
    await expectValueIndicator(isVisible: true, theme: theme, enabled: false, dragged: false);
  });

  testWidgets('RangeSlider overlay appears correctly for specific thumb interactions', (
    WidgetTester tester,
  ) async {
    tester.binding.focusManager.highlightStrategy = FocusHighlightStrategy.alwaysTraditional;
    RangeValues values = const RangeValues(50, 70);
    const Color hoverColor = Color(0xffff0000);
    const Color dragColor = Color(0xff0000ff);

    Widget buildApp() {
      return MaterialApp(
        home: Directionality(
          textDirection: TextDirection.ltr,
          child: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Material(
                child: Center(
                  child: RangeSlider(
                    values: values,
                    max: 100.0,
                    overlayColor: WidgetStateProperty.resolveWith<Color?>((
                      Set<WidgetState> states,
                    ) {
                      if (states.contains(WidgetState.hovered)) {
                        return hoverColor;
                      }
                      if (states.contains(WidgetState.dragged)) {
                        return dragColor;
                      }

                      return null;
                    }),
                    onChanged: (RangeValues newValues) {
                      setState(() {
                        values = newValues;
                      });
                    },
                    onChangeStart: (RangeValues newValues) {},
                    onChangeEnd: (RangeValues newValues) {},
                  ),
                ),
              );
            },
          ),
        ),
      );
    }

    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    // Initial state - no overlay.
    expect(
      Material.of(tester.element(find.byType(RangeSlider))),
      isNot(paints..circle(color: dragColor)),
    );

    // Drag start thumb to left.
    final Offset topThumbLocation = tester.getCenter(find.byType(RangeSlider));
    final TestGesture dragStartThumb = await tester.startGesture(topThumbLocation);
    await tester.pump(kPressTimeout);
    await dragStartThumb.moveBy(const Offset(-20.0, 0));
    await tester.pumpAndSettle();

    // Verify overlay is visible and shadow is visible on single thumb.
    expect(
      Material.of(tester.element(find.byType(RangeSlider))),
      paints
        ..circle(color: dragColor)
        ..path(color: Colors.black, style: PaintingStyle.stroke, strokeWidth: 2.0)
        ..path(color: Colors.black, style: PaintingStyle.stroke, strokeWidth: 12.0),
    );

    // Move back and release.
    await dragStartThumb.moveBy(const Offset(20.0, 0));
    await dragStartThumb.up();
    await tester.pumpAndSettle();

    // Verify overlay and shadow disappears
    expect(
      Material.of(tester.element(find.byType(RangeSlider))),
      isNot(
        paints
          ..circle(color: dragColor)
          ..path(color: Colors.black, style: PaintingStyle.stroke, strokeWidth: 2.0)
          ..path(color: Colors.black, style: PaintingStyle.stroke, strokeWidth: 2.0),
      ),
    );

    // Drag end thumb and return to original position.
    final Offset bottomThumbLocation = tester
        .getCenter(find.byType(RangeSlider))
        .translate(220.0, 0.0);
    final TestGesture dragEndThumb = await tester.startGesture(bottomThumbLocation);
    await tester.pump(kPressTimeout);
    await dragEndThumb.moveBy(const Offset(20.0, 0));
    await tester.pump(kPressTimeout);
    await dragEndThumb.moveBy(const Offset(-20.0, 0));
    await dragEndThumb.up();
    await tester.pumpAndSettle();

    // Verify overlay disappears.
    expect(
      Material.of(tester.element(find.byType(RangeSlider))),
      isNot(paints..circle(color: dragColor)),
    );

    // Hover on start thumb.
    final TestGesture gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer();
    await gesture.moveTo(topThumbLocation);
    await tester.pumpAndSettle();

    // Verify overlay appears only for start thumb and no shadow is visible.
    expect(
      Material.of(tester.element(find.byType(RangeSlider))),
      paints
        ..circle(color: hoverColor)
        ..path(color: Colors.black, style: PaintingStyle.stroke, strokeWidth: 2.0)
        ..path(color: Colors.black, style: PaintingStyle.stroke, strokeWidth: 2.0),
    );

    final RenderObject renderObject = tester.renderObject(find.byType(RangeSlider));
    // 2 thumbs and 1 overlay.
    expect(renderObject, paintsExactlyCountTimes(#drawCircle, 3));

    // Move away from thumb
    await gesture.moveTo(tester.getTopRight(find.byType(RangeSlider)));
    await tester.pumpAndSettle();

    // Verify overlay disappears
    expect(
      Material.of(tester.element(find.byType(RangeSlider))),
      isNot(paints..circle(color: hoverColor)),
    );
  });

  testWidgets('RangeSlider.padding can override the default RangeSlider padding', (
    WidgetTester tester,
  ) async {
    Widget buildRangeSlider({EdgeInsetsGeometry? padding}) {
      return MaterialApp(
        home: Material(
          child: Center(
            child: IntrinsicHeight(
              child: RangeSlider(
                padding: padding,
                values: const RangeValues(0, 1.0),
                onChanged: (RangeValues values) {},
              ),
            ),
          ),
        ),
      );
    }

    RenderBox sliderRenderBox() {
      return tester.allRenderObjects.firstWhere(
            (RenderObject object) => object.runtimeType.toString() == '_RenderRangeSlider',
          )
          as RenderBox;
    }

    // Test RangeSlider height and tracks spacing with zero padding.
    await tester.pumpWidget(buildRangeSlider(padding: EdgeInsets.zero));
    await tester.pumpAndSettle();

    // The height equals to the default thumb height.
    expect(sliderRenderBox().size, const Size(800, 20));
    expect(
      find.byType(RangeSlider),
      paints
        // Inactive track.
        ..rrect(
          rrect: RRect.fromLTRBAndCorners(
            10.0,
            8.0,
            10.0,
            12.0,
            topLeft: const Radius.circular(2.0),
            bottomLeft: const Radius.circular(2.0),
          ),
        )
        // Inactive track.
        ..rrect(
          rrect: RRect.fromLTRBAndCorners(
            790.0,
            8.0,
            790.0,
            12.0,
            topRight: const Radius.circular(2.0),
            bottomRight: const Radius.circular(2.0),
          ),
        )
        // Active track.
        ..rrect(rrect: RRect.fromLTRBR(8.0, 7.0, 792.0, 13.0, const Radius.circular(2.0))),
    );

    // Test RangeSlider height and tracks spacing with directional padding.
    const double startPadding = 100;
    const double endPadding = 20;
    await tester.pumpWidget(
      buildRangeSlider(
        padding: const EdgeInsetsDirectional.only(start: startPadding, end: endPadding),
      ),
    );
    await tester.pumpAndSettle();

    expect(sliderRenderBox().size, const Size(800 - startPadding - endPadding, 20));
    expect(
      find.byType(RangeSlider),
      paints
        // Inactive track.
        ..rrect(
          rrect: RRect.fromLTRBAndCorners(
            10.0,
            8.0,
            10.0,
            12.0,
            topLeft: const Radius.circular(2.0),
            bottomLeft: const Radius.circular(2.0),
          ),
        )
        // Inactive track.
        ..rrect(
          rrect: RRect.fromLTRBAndCorners(
            670.0,
            8.0,
            670.0,
            12.0,
            topRight: const Radius.circular(2.0),
            bottomRight: const Radius.circular(2.0),
          ),
        )
        // Active track.
        ..rrect(rrect: RRect.fromLTRBR(8.0, 7.0, 672.0, 13.0, const Radius.circular(2.0))),
    );

    // Test RangeSlider height and tracks spacing with top and bottom padding.
    const double topPadding = 100;
    const double bottomPadding = 20;
    const double trackHeight = 20;
    await tester.pumpWidget(
      buildRangeSlider(
        padding: const EdgeInsetsDirectional.only(top: topPadding, bottom: bottomPadding),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      tester.getSize(find.byType(RangeSlider)),
      const Size(800, topPadding + trackHeight + bottomPadding),
    );
    expect(sliderRenderBox().size, const Size(800, 20));
    expect(
      find.byType(RangeSlider),
      paints
        // Inactive track.
        ..rrect(
          rrect: RRect.fromLTRBAndCorners(
            10.0,
            8.0,
            10.0,
            12.0,
            topLeft: const Radius.circular(2.0),
            bottomLeft: const Radius.circular(2.0),
          ),
        )
        // Inactive track.
        ..rrect(
          rrect: RRect.fromLTRBAndCorners(
            790.0,
            8.0,
            790.0,
            12.0,
            topRight: const Radius.circular(2.0),
            bottomRight: const Radius.circular(2.0),
          ),
        )
        // Active track.
        ..rrect(rrect: RRect.fromLTRBR(8.0, 7.0, 792.0, 13.0, const Radius.circular(2.0))),
    );
  });

  // Regression test for hhttps://github.com/flutter/flutter/issues/161805
  testWidgets('Discrete RangeSlider does not apply thumb padding in a non-rounded track shape', (
    WidgetTester tester,
  ) async {
    // The default track left and right padding.
    const double sliderPadding = 24.0;
    final ThemeData theme = ThemeData(
      sliderTheme: const SliderThemeData(
        // Thumb padding is applied based on the track height.
        trackHeight: 100,
        rangeTrackShape: RectangularRangeSliderTrackShape(),
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: Material(
          child: SizedBox(
            width: 300,
            child: RangeSlider(
              values: const RangeValues(0, 100),
              max: 100,
              divisions: 100,
              onChanged: (RangeValues value) {},
            ),
          ),
        ),
      ),
    );

    final MaterialInkController material = Material.of(tester.element(find.byType(RangeSlider)));

    expect(
      material,
      paints
        // Start thumb.
        ..circle(x: sliderPadding, y: 300.0, color: theme.colorScheme.primary)
        // End thumb.
        ..circle(x: 800.0 - sliderPadding, y: 300.0, color: theme.colorScheme.primary),
    );
  });

  testWidgets('Default RangeSlider when year2023 is false', (WidgetTester tester) async {
    final ThemeData theme = ThemeData();
    final ColorScheme colorScheme = theme.colorScheme;
    final Color activeTrackColor = colorScheme.primary;
    final Color inactiveTrackColor = colorScheme.secondaryContainer;
    final Color disabledActiveTrackColor = colorScheme.onSurface.withOpacity(0.38);
    final Color disabledInactiveTrackColor = colorScheme.onSurface.withOpacity(0.12);
    final Color activeTickMarkColor = colorScheme.onPrimary;
    final Color inactiveTickMarkColor = colorScheme.onSecondaryContainer;
    final Color disabledActiveTickMarkColor = colorScheme.onInverseSurface;
    final Color disabledInactiveTickMarkColor = colorScheme.onSurface;
    final Color thumbColor = colorScheme.primary;
    final Color disabledThumbColor = colorScheme.onSurface.withOpacity(0.38);
    final Color valueIndicatorColor = colorScheme.inverseSurface;
    RangeValues values = const RangeValues(25.0, 75.0);
    Widget buildApp({int? divisions, bool enabled = true}) {
      final ValueChanged<RangeValues>? onChanged = !enabled
          ? null
          : (RangeValues newValues) {
              values = newValues;
            };
      return MaterialApp(
        home: Material(
          child: Center(
            child: Theme(
              data: theme,
              child: RangeSlider(
                year2023: false,
                values: values,
                max: 100,
                labels: RangeLabels(values.start.round().toString(), values.end.round().toString()),
                divisions: divisions,
                onChanged: onChanged,
              ),
            ),
          ),
        ),
      );
    }

    await tester.pumpWidget(buildApp());

    final MaterialInkController material = Material.of(tester.element(find.byType(RangeSlider)));

    // Test default track shape.
    const Radius trackOuterCornerRadius = Radius.circular(8.0);
    const Radius trackInnerCornerRadius = Radius.circular(2.0);
    expect(
      material,
      paints
        // Inactive track.
        ..rrect(
          rrect: RRect.fromLTRBAndCorners(
            24.0,
            292.0,
            206.0,
            308.0,
            topLeft: trackOuterCornerRadius,
            topRight: trackInnerCornerRadius,
            bottomRight: trackInnerCornerRadius,
            bottomLeft: trackOuterCornerRadius,
          ),
          color: inactiveTrackColor,
        )
        // Inactive track.
        ..rrect(
          rrect: RRect.fromLTRBAndCorners(
            594.0,
            292.0,
            776.0,
            308.0,
            topLeft: trackInnerCornerRadius,
            topRight: trackOuterCornerRadius,
            bottomRight: trackOuterCornerRadius,
            bottomLeft: trackInnerCornerRadius,
          ),
          color: inactiveTrackColor,
        )
        // Active track.
        ..rrect(
          rrect: RRect.fromLTRBR(218.0, 292.0, 582.0, 308.0, trackInnerCornerRadius),
          color: activeTrackColor,
        ),
    );

    // Test default colors for enabled slider.
    expect(
      material,
      paints
        ..circle()
        ..circle()
        ..rrect(color: thumbColor)
        ..rrect(color: thumbColor),
    );
    expect(
      material,
      isNot(
        paints
          ..circle()
          ..circle()
          ..rrect(color: disabledThumbColor)
          ..rrect(color: disabledThumbColor),
      ),
    );
    expect(material, isNot(paints..rrect(color: disabledActiveTrackColor)));
    expect(material, isNot(paints..rrect(color: disabledInactiveTrackColor)));

    // Test defaults colors for discrete slider.
    await tester.pumpWidget(buildApp(divisions: 4));
    expect(
      material,
      paints
        ..rrect(color: inactiveTrackColor)
        ..rrect(color: inactiveTrackColor)
        ..rrect(color: activeTrackColor)
        ..circle(color: inactiveTickMarkColor)
        ..circle(color: activeTickMarkColor)
        ..circle(color: inactiveTickMarkColor),
    );
    expect(material, isNot(paints..rrect(color: disabledThumbColor)));
    expect(material, isNot(paints..rrect(color: disabledActiveTrackColor)));
    expect(material, isNot(paints..rrect(color: disabledInactiveTrackColor)));

    // Test defaults colors for disabled slider.
    await tester.pumpWidget(buildApp(enabled: false));
    await tester.pumpAndSettle();
    expect(
      material,
      paints
        ..rrect(color: disabledInactiveTrackColor)
        ..rrect(color: disabledInactiveTrackColor)
        ..rrect(color: disabledActiveTrackColor)
        ..rrect(color: disabledThumbColor)
        ..rrect(color: disabledThumbColor),
    );
    expect(
      material,
      isNot(
        paints
          ..rrect(color: thumbColor)
          ..rrect(color: thumbColor),
      ),
    );
    expect(material, isNot(paints..rrect(color: activeTrackColor)));
    expect(material, isNot(paints..rrect(color: inactiveTrackColor)));

    // Test defaults colors for disabled discrete slider.
    await tester.pumpWidget(buildApp(divisions: 4, enabled: false));
    expect(
      material,
      paints
        ..rrect(color: disabledInactiveTrackColor)
        ..rrect(color: disabledInactiveTrackColor)
        ..rrect(color: disabledActiveTrackColor)
        ..circle(color: disabledInactiveTickMarkColor)
        ..circle(color: disabledActiveTickMarkColor)
        ..circle(color: disabledInactiveTickMarkColor)
        ..rrect(color: disabledThumbColor)
        ..rrect(color: disabledThumbColor),
    );
    expect(
      material,
      isNot(
        paints
          ..rrect(color: thumbColor)
          ..rrect(color: thumbColor),
      ),
    );
    expect(material, isNot(paints..rrect(color: activeTrackColor)));
    expect(material, isNot(paints..rrect(color: inactiveTrackColor)));

    await tester.pumpWidget(buildApp(divisions: 4));
    await tester.pumpAndSettle();

    final Offset topLeft = tester.getTopLeft(find.byType(RangeSlider));
    final TestGesture gesture = await tester.startGesture(topLeft);
    // Wait for value indicator animation to finish.
    await tester.pumpAndSettle();

    final RenderBox valueIndicatorBox = tester.renderObject(find.byType(Overlay));
    expect(
      valueIndicatorBox,
      paints
        ..scale()
        ..rrect(color: valueIndicatorColor),
    );
    await gesture.up();
  });

  testWidgets('RangeSlider value indicator text when year2023 is false', (
    WidgetTester tester,
  ) async {
    const RangeValues values = RangeValues(25.0, 75.0);
    final List<InlineSpan> log = <InlineSpan>[];
    final LoggingRangeSliderValueIndicatorShape loggingValueIndicatorShape =
        LoggingRangeSliderValueIndicatorShape(log);
    final ThemeData theme = ThemeData(
      sliderTheme: SliderThemeData(rangeValueIndicatorShape: loggingValueIndicatorShape),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: Material(
          child: Center(
            child: RangeSlider(
              year2023: false,
              values: values,
              max: 100,
              labels: RangeLabels(values.start.round().toString(), values.end.round().toString()),
              divisions: 4,
              onChanged: (RangeValues value) {},
            ),
          ),
        ),
      ),
    );
    final Offset topLeft = tester.getTopLeft(find.byType(RangeSlider));
    final TestGesture gesture = await tester.startGesture(topLeft);
    await tester.pumpAndSettle();

    expect(log.last.toPlainText(), '25');
    expect(log.last.style!.fontSize, 14.0);
    expect(log.last.style!.color, theme.colorScheme.onInverseSurface);

    await gesture.up();
    await tester.pumpAndSettle();
  });

  testWidgets('RangeSlider supports DropRangeSliderValueIndicatorShape', (
    WidgetTester tester,
  ) async {
    const RangeValues values = RangeValues(25.0, 75.0);
    const Color valueIndicatorColor = Color(0XFFFF0000);
    final ThemeData theme = ThemeData(
      sliderTheme: const SliderThemeData(
        rangeValueIndicatorShape: DropRangeSliderValueIndicatorShape(),
        valueIndicatorColor: valueIndicatorColor,
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: Material(
          child: Center(
            child: RangeSlider(
              year2023: false,
              values: values,
              max: 100,
              labels: RangeLabels(values.start.round().toString(), values.end.round().toString()),
              divisions: 4,
              onChanged: (RangeValues value) {},
            ),
          ),
        ),
      ),
    );
    final Offset topLeft = tester.getTopLeft(find.byType(RangeSlider));
    final TestGesture gesture = await tester.startGesture(topLeft);
    await tester.pumpAndSettle();

    final RenderBox valueIndicatorBox = tester.renderObject(find.byType(Overlay));
    expect(valueIndicatorBox, paints..path(color: valueIndicatorColor));

    await gesture.up();
    await tester.pumpAndSettle();
  });

  testWidgets('Value indicator appears on tap', (WidgetTester tester) async {
    final ThemeData theme = buildTheme();
    final SliderThemeData sliderTheme = theme.sliderTheme;
    const RangeValues discreteValues = RangeValues(20, 40);
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: Material(
          child: RangeSlider(
            labels: RangeLabels(
              discreteValues.start.round().toString(),
              discreteValues.end.round().toString(),
            ),
            values: discreteValues,
            divisions: 5,
            max: 100,
            onChanged: (RangeValues values) {},
          ),
        ),
      ),
    );
    await tester.tap(find.byType(RangeSlider));
    await tester.pumpAndSettle();
    final RenderBox valueIndicatorBox = tester.renderObject(find.byType(Overlay));
    expect(
      valueIndicatorBox,
      paints
        ..path(color: Colors.black) // shadow
        ..path(color: Colors.black) // shadow
        ..path(color: sliderTheme.valueIndicatorColor)
        ..paragraph(),
    );
  });
}

// A value indicator shape to log labelPainter text.
class LoggingRangeSliderValueIndicatorShape extends RangeSliderValueIndicatorShape {
  LoggingRangeSliderValueIndicatorShape(this.logLabel);

  final List<InlineSpan> logLabel;

  @override
  Size getPreferredSize(
    bool isEnabled,
    bool isDiscrete, {
    required TextPainter labelPainter,
    required double textScaleFactor,
  }) {
    return const Size(10.0, 10.0);
  }

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    bool? isDiscrete,
    bool? isOnTop,
    required TextPainter labelPainter,
    double? textScaleFactor,
    Size? sizeWithOverflow,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    TextDirection? textDirection,
    double? value,
    Thumb? thumb,
  }) {
    logLabel.add(labelPainter.text!);
  }
}
