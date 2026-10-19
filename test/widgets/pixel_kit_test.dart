import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fogcatcher/widgets/pixel_kit.dart';

void main() {
  testWidgets('PixelButton exposes a tappable button semantics node', (
    t,
  ) async {
    final handle = t.ensureSemantics();
    var n = 0;
    await t.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: PixelButton(label: 'Go', onPressed: () => n++),
          ),
        ),
      ),
    );
    final node = t.getSemantics(find.bySemanticsLabel('Go'));
    expect(node.flagsCollection.isButton, isTrue);
    expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
    t.semantics.tap(find.semantics.byLabel('Go'));
    expect(n, 1);
    handle.dispose();
  });
}
