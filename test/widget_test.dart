import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:decentradonate/app.dart';

/// Smoke test dasar: pastikan app bisa di-build tanpa exception dan
/// judul Home Screen muncul. Perluas test ini di Stage 2 saat repository
/// dan provider nyata sudah ada (mis. test ViewState transitions).
void main() {
  testWidgets('App boots and shows Home title', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: DecentradonateApp()));
    await tester.pumpAndSettle();

    expect(find.text('Kampanye Donasi'), findsOneWidget);
  });
}
