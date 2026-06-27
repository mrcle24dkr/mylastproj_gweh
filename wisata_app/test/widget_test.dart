// This is a basic Flutter widget test adjusted for WisataApp.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

// import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:wisata_app/main.dart';
import 'package:wisata_app/login_page.dart';
import 'package:wisata_app/providers/theme_provider.dart';

void main() {
  testWidgets('Aplikasi berhasil memuat Halaman Login', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    // Kita bungkus dengan ChangeNotifierProvider agar ThemeProvider tidak error saat test
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (context) => ThemeProvider(),
        child: const WisataApp(halamanPertama: LoginPage()), 
      ),
    );

    // Membiarkan animasi rendering selesai
    await tester.pumpAndSettle();

    // Verifikasi bahwa aplikasi tidak lagi menampilkan counter '0'
    expect(find.text('0'), findsNothing);

    // Verifikasi bahwa aplikasi berhasil memuat halaman LoginPage sebagai halaman pertama
    expect(find.byType(LoginPage), findsOneWidget);
  });
}