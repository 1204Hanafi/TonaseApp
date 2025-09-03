import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:intl/intl.dart';
import 'package:tonase_app/main.dart' as app;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tonase_app/utils/file_saver.dart';
import 'package:tonase_app/utils/pdf_exporter.dart';

class TestReportAssets {
  static Map<String, dynamic> lastReport = {};
}

class TestFileSaver implements FileSaver {
  @override
  Future<void> saveExcel(List<int> bytes, String filename) async {
    debugPrint("✅ [Mock] File Excel berhasil disimpan: $filename");
  }
}

class TestPdfExporter implements PdfExporter {
  @override
  Future<void> exportPdf(Uint8List bytes, String filename) async {
    debugPrint("✅ [Mock] PDF berhasil diekspor: $filename");
  }
}

Future<void> saveReportAsAssetTemp(
  String reportContent, {
  String? filename,
}) async {
  final now = DateTime.now();
  final fn =
      filename ?? 'report_${now.toIso8601String().replaceAll(':', '-')}.txt';
  final tempDir = Directory.systemTemp.createTempSync('tonase_test_');
  final file = File(p.join(tempDir.path, fn));
  await file.writeAsString(reportContent);
  debugPrint('✅ Report disimpan di: ${file.path}');
}

void main() {
  // 1. Inisialisasi integration binding
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // 2. Struktur data untuk hasil & detail tiap fitur
  final featureResults = <String, bool>{
    'Autentikasi Pengguna': false,
    'Input Data Tonase': false,
    'Manajemen Area': false,
    'Manajemen Customer': false,
    'HomePage': false,
    'Rekap Harian & Ekspor': false,
    'History & Unmark': false,
  };
  final featureDetails = {for (var f in featureResults.keys) f: <String>[]};

  // 3. Setup app dengan mock
  late FileSaver fileSaver;
  late PdfExporter pdfExporter;
  setUpAll(() async {
    fileSaver = TestFileSaver();
    pdfExporter = TestPdfExporter();
    await app.main(fileSaver: fileSaver, pdfExporter: pdfExporter);
  });

  // 4. Helper login
  Future<void> login(
    WidgetTester tester, {
    required String logFeature, // nama fitur yang akan dikasi log
  }) async {
    // Isi email
    await tester.enterText(
      find.byKey(const Key('email-field')),
      'usertonaseinput001@gmail.com',
    );
    await tester.pumpAndSettle(const Duration(seconds: 1));

    // Isi password
    await tester.enterText(
      find.byKey(const Key('password-field')),
      'password123',
    );
    await tester.pumpAndSettle(const Duration(seconds: 1));

    // Tutup keyboard
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle(const Duration(seconds: 1));

    // Tap tombol login
    await tester.tap(find.byKey(const Key('login-button')));
    await tester.pumpAndSettle(const Duration(seconds: 3));

    // Log ke featureDetails sesuai fitur ini
    featureDetails[logFeature]!.add('Login berhasil');
  }

  // 5. Group utama untuk 7 fitur testing
  group('Pengujian Fungsional Suitability', () {
    testWidgets('1. Autentikasi Pengguna', (tester) async {
      const feature = 'Autentikasi Pengguna';

      try {
        // Start app
        app.main();
        await tester.pumpAndSettle(const Duration(seconds: 3));
        featureDetails[feature]!.add('Aplikasi berhasil dimulai');

        // Registrasi
        await tester.tap(find.byKey(const Key('register-button')));
        await tester.pumpAndSettle(const Duration(seconds: 2));
        featureDetails[feature]!.add('Navigasi ke halaman registrasi');

        await tester.enterText(
          find.byKey(const Key('register-email-field')),
          'usertonaseinput001@gmail.com',
        );
        await tester.pumpAndSettle(const Duration(seconds: 1));
        await tester.enterText(
          find.byKey(const Key('register-password-field')),
          'password123',
        );
        await tester.pumpAndSettle(const Duration(seconds: 1));
        await tester.enterText(
          find.byKey(const Key('register-confirm-field')),
          'password123',
        );
        await tester.pumpAndSettle(const Duration(seconds: 1));
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pumpAndSettle(const Duration(seconds: 1));
        await tester.tap(find.byKey(const Key('submit-register-button')));
        await tester.pumpAndSettle(const Duration(seconds: 3));
        expect(find.textContaining('TONASE'), findsOneWidget);
        featureDetails[feature]!.add('Registrasi sukses => HomePage');

        // Logout & Login dengan akun Registrasi
        await tester.tap(find.byKey(const Key('menu-button')));
        await tester.pumpAndSettle(const Duration(seconds: 1));
        await tester.tap(find.byKey(const Key('logout-button')));
        await tester.pumpAndSettle(const Duration(seconds: 3));
        expect(find.textContaining('Masuk'), findsOneWidget);
        featureDetails[feature]!.add('Logout berhasil => halaman login');

        await login(tester, logFeature: feature);
        expect(find.textContaining('TONASE'), findsOneWidget);
        featureDetails[feature]!.add('Login sukses => HomePage');

        // Logout & Reset Password
        await tester.tap(find.byKey(const Key('menu-button')));
        await tester.pumpAndSettle(const Duration(seconds: 1));
        await tester.tap(find.byKey(const Key('logout-button')));
        await tester.pumpAndSettle(const Duration(seconds: 3));
        expect(find.textContaining('Masuk'), findsOneWidget);
        featureDetails[feature]!.add('Logout berhasil => halaman login');

        await tester.tap(find.byKey(const Key('forgot-password-button')));
        await tester.pumpAndSettle(const Duration(seconds: 3));
        featureDetails[feature]!.add('Navigasi ke halaman Reset Password');

        await tester.enterText(
          find.byKey(const Key('reset-email-key')),
          'usertonaseinput001@gmail.com',
        );
        await tester.pumpAndSettle(const Duration(seconds: 1));
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pumpAndSettle(const Duration(seconds: 1));
        await tester.tap(find.byKey(const Key('submit-reset-button')));
        await tester.pumpAndSettle(const Duration(seconds: 3));
        expect(find.textContaining('Email Terkirim'), findsOneWidget);
        featureDetails[feature]!.add('Reset password sukses');

        // Tandai sukses
        featureResults[feature] = true;
      } catch (e) {
        rethrow;
      }
    });

    testWidgets('2. Input Data Tonase', (tester) async {
      const feature = 'Input Data Tonase';
      try {
        // Start app & login
        app.main();
        await tester.pumpAndSettle(const Duration(seconds: 3));
        featureDetails[feature]!.add('Aplikasi berhasil dimulai');

        await login(tester, logFeature: feature);
        expect(find.textContaining('TONASE'), findsOneWidget);
        // featureDetails[feature]!.add('Login berhasil');

        // Navigasi ke halaman input tonase
        await tester.tap(find.byKey(const Key('add-tonase-button')));
        await tester.pumpAndSettle(const Duration(seconds: 2));
        featureDetails[feature]!.add('Navigasi ke halaman input tonase');

        // Input tanggal
        await tester.tap(find.byKey(const Key('date-field')));
        await tester.pumpAndSettle();
        await tester.tap(find.text('OK'));
        await tester.pumpAndSettle(const Duration(seconds: 2));
        featureDetails[feature]!.add('Input tanggal berhasil');

        // Input No SJ
        await tester.enterText(
          find.byKey(const Key('sj-number-field')),
          '01-0001',
        );
        await tester.pumpAndSettle(const Duration(seconds: 1));
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pumpAndSettle(const Duration(seconds: 1));
        featureDetails[feature]!.add('Input nomor surat jalan berhasil');

        // Input customer dengan autosuggest
        await tester.enterText(
          find.byKey(const Key('customer-field')),
          'MORO SENENG',
        );
        await tester.pumpAndSettle(const Duration(seconds: 2));
        await tester.tap(find.byKey(const Key('selected-customer')));
        await tester.pumpAndSettle(const Duration(seconds: 2));
        featureDetails[feature]!.add(
          'Memilih pelanggan (autosuggest) berhasil',
        );

        // Input total koli
        await tester.enterText(find.byKey(const Key('koli-count-field')), '3');
        await tester.pumpAndSettle(const Duration(seconds: 1));
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pumpAndSettle(const Duration(seconds: 1));
        featureDetails[feature]!.add('Input jumlah koli berhasil');

        // Input berat per koli
        final weightFields = find.byKey(const Key('weight-field'));
        await tester.enterText(weightFields.at(0), '10');
        await tester.enterText(weightFields.at(1), '12');
        await tester.enterText(weightFields.at(2), '8');
        await tester.pumpAndSettle(const Duration(seconds: 2));
        featureDetails[feature]!.add('Input berat tiap koli berhasil');

        // Simpan data
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pumpAndSettle(const Duration(seconds: 1));
        await tester.ensureVisible(find.byKey(const Key('save-tonase-button')));
        await tester.tap(find.byKey(const Key('save-tonase-button')));
        await tester.pumpAndSettle(const Duration(seconds: 3));

        expect(find.textContaining('Data berhasil disimpan!'), findsOneWidget);
        featureDetails[feature]!.add('Data tonase berhasil disimpan');

        // Tandai sukses
        featureResults[feature] = true;
      } catch (e) {
        rethrow;
      }
    });

    testWidgets('3. Manajemen Area', (tester) async {
      const feature = 'Manajemen Area';

      try {
        // Start app & login
        app.main();
        await tester.pumpAndSettle(const Duration(seconds: 3));
        featureDetails[feature]!.add('Aplikasi berhasil dimulai');

        await login(tester, logFeature: feature);
        expect(find.textContaining('TONASE'), findsOneWidget);
        // featureDetails[feature]!.add('Login berhasil');

        // Navigasi ke halaman Area
        await tester.tap(find.byKey(const Key('menu-button')));
        await tester.pumpAndSettle(const Duration(seconds: 1));
        await tester.tap(find.byKey(const Key('area-menu-button')));
        await tester.pumpAndSettle(const Duration(seconds: 2));
        featureDetails[feature]!.add('Navigasi ke halaman Area');

        // Tambah Area
        await tester.tap(find.byKey(const Key('add-area-button')));
        await tester.pumpAndSettle(const Duration(seconds: 1));

        await tester.enterText(find.byKey(const Key('area-id-field')), '01');
        await tester.pumpAndSettle(const Duration(milliseconds: 500));
        await tester.enterText(
          find.byKey(const Key('area-name-field')),
          'TEST',
        );
        await tester.pumpAndSettle(const Duration(milliseconds: 500));

        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pumpAndSettle(const Duration(milliseconds: 500));

        await tester.ensureVisible(find.byKey(const Key('save-area-button')));
        await tester.tap(find.byKey(const Key('save-area-button')));
        await tester.pumpAndSettle(const Duration(seconds: 3));
        expect(find.textContaining('Berhasil ditambahkan'), findsOneWidget);
        featureDetails[feature]!.add('Tambah area berhasil');

        // Edit Area
        await tester.tap(find.byKey(const Key('select-action')).first);
        await tester.pumpAndSettle(const Duration(seconds: 1));
        await tester.tap(find.byKey(const Key('edit-area-button')).first);
        await tester.pumpAndSettle(const Duration(seconds: 2));

        await tester.enterText(
          find.byKey(const Key('area-name-field')),
          'TEST AREA',
        );
        await tester.pumpAndSettle(const Duration(milliseconds: 500));
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pumpAndSettle(const Duration(milliseconds: 500));

        await tester.ensureVisible(find.byKey(const Key('save-area-button')));
        await tester.tap(find.byKey(const Key('save-area-button')));
        await tester.pumpAndSettle(const Duration(seconds: 2));
        expect(find.textContaining('Berhasil diperbarui'), findsOneWidget);
        featureDetails[feature]!.add('Edit area berhasil');

        // Hapus Area
        await tester.tap(find.byKey(const Key('select-action')).first);
        await tester.pumpAndSettle(const Duration(seconds: 1));
        await tester.tap(find.byKey(const Key('delete-area-button')).first);
        await tester.pumpAndSettle(const Duration(seconds: 1));

        await tester.tap(find.byKey(const Key('confirm-delete-button')));
        await tester.pumpAndSettle(const Duration(seconds: 3));
        expect(find.textContaining('Berhasil dihapus'), findsOneWidget);
        featureDetails[feature]!.add('Hapus area berhasil');

        // Tandai sukses
        featureResults[feature] = true;
      } catch (e) {
        rethrow;
      }
    });

    testWidgets('4. Manajemen Customer', (tester) async {
      const feature = 'Manajemen Customer';

      try {
        // Start app & login
        app.main();
        await tester.pumpAndSettle(const Duration(seconds: 3));
        featureDetails[feature]!.add('Aplikasi berhasil dimulai');

        await login(tester, logFeature: feature);
        expect(find.textContaining('TONASE'), findsOneWidget);

        // Navigasi ke halaman Customer
        await tester.tap(find.byKey(const Key('menu-button')));
        await tester.pumpAndSettle(const Duration(seconds: 1));
        await tester.tap(find.byKey(const Key('customer-menu-button')));
        await tester.pumpAndSettle(const Duration(seconds: 2));
        featureDetails[feature]!.add('Navigasi ke halaman Customer');

        // Tambah Customer
        await tester.tap(find.byKey(const Key('add-customer-button')));
        await tester.pumpAndSettle(const Duration(seconds: 1));

        await tester.enterText(
          find.byKey(const Key('customer-id-field')),
          '00001',
        );
        await tester.pumpAndSettle(const Duration(milliseconds: 500));

        await tester.enterText(
          find.byKey(const Key('customer-name-field')),
          'TEST CUSTOMER',
        );
        await tester.pumpAndSettle(const Duration(milliseconds: 500));

        await tester.enterText(
          find.byKey(const Key('customer-city-field')),
          'BLORA',
        );
        await tester.pumpAndSettle(const Duration(milliseconds: 500));

        await tester.tap(find.byKey(const Key('dropdown-area')));
        await tester.pumpAndSettle();
        final areaOption = find.text('BLORA').last;
        expect(areaOption, findsOneWidget);
        await tester.tap(areaOption);
        await tester.pumpAndSettle(const Duration(milliseconds: 500));

        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pumpAndSettle(const Duration(milliseconds: 500));

        await tester.ensureVisible(
          find.byKey(const Key('save-customer-button')),
        );
        await tester.tap(find.byKey(const Key('save-customer-button')));

        for (int i = 0; i < 15; i++) {
          await tester.pump(const Duration(seconds: 1));
          if (find
              .textContaining('Berhasil ditambahkan')
              .evaluate()
              .isNotEmpty) {
            break;
          }
        }
        expect(find.textContaining('Berhasil ditambahkan'), findsOneWidget);
        featureDetails[feature]!.add('Tambah customer berhasil');

        // Edit Customer
        await tester.pumpAndSettle(const Duration(seconds: 2));
        final scrollable = find.byType(SingleChildScrollView).first;
        await tester.drag(scrollable, const Offset(-1000, 0));
        await tester.pumpAndSettle(const Duration(seconds: 2));

        await tester.tap(find.byKey(const Key('select-action')).first);
        await tester.pumpAndSettle(const Duration(seconds: 1));
        await tester.tap(find.byKey(const Key('edit-customer-button')).first);
        await tester.pumpAndSettle(const Duration(seconds: 2));

        await tester.enterText(
          find.byKey(const Key('customer-name-field')),
          'TEST CUSTOMER JEPARA',
        );
        await tester.pumpAndSettle(const Duration(milliseconds: 500));

        await tester.enterText(
          find.byKey(const Key('customer-city-field')),
          'JEPARA',
        );
        await tester.pumpAndSettle(const Duration(milliseconds: 500));

        await tester.tap(find.byKey(const Key('dropdown-area')));
        await tester.pumpAndSettle(const Duration(milliseconds: 500));
        final editAreaOption = find.text('JEPARA').last;
        expect(editAreaOption, findsOneWidget);
        await tester.tap(editAreaOption);
        await tester.pumpAndSettle(const Duration(milliseconds: 500));

        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pumpAndSettle(const Duration(milliseconds: 500));

        await tester.ensureVisible(
          find.byKey(const Key('save-customer-button')),
        );
        await tester.tap(find.byKey(const Key('save-customer-button')));
        for (int i = 0; i < 15; i++) {
          await tester.pump(const Duration(seconds: 1));
          if (find
              .textContaining('Berhasil diperbarui')
              .evaluate()
              .isNotEmpty) {
            break;
          }
        }
        expect(find.textContaining('Berhasil diperbarui'), findsOneWidget);
        featureDetails[feature]!.add('Edit customer berhasil');

        // Hapus Customer
        await tester.pumpAndSettle(const Duration(seconds: 2));
        await tester.drag(scrollable, const Offset(-1000, 0));
        await tester.pumpAndSettle(const Duration(seconds: 2));

        await tester.tap(find.byKey(const Key('select-action')).first);
        await tester.pumpAndSettle(const Duration(milliseconds: 500));
        await tester.tap(find.byKey(const Key('delete-customer-button')).first);
        await tester.pumpAndSettle(const Duration(seconds: 2));
        await tester.tap(find.byKey(const Key('confirm-delete-button')));
        for (int i = 0; i < 15; i++) {
          await tester.pump(const Duration(seconds: 1));
          if (find
              .textContaining('Berhasil diperbarui')
              .evaluate()
              .isNotEmpty) {
            break;
          }
        }
        expect(find.textContaining('Berhasil dihapus'), findsOneWidget);
        featureDetails[feature]!.add('Hapus customer berhasil');

        // Tandai sukses
        featureResults[feature] = true;
      } catch (e) {
        rethrow;
      }
    });

    testWidgets('5. HomePage Functionality', (tester) async {
      const feature = 'HomePage';

      try {
        app.main();
        await tester.pumpAndSettle(const Duration(seconds: 3));
        featureDetails[feature]!.add('Aplikasi berhasil dimulai');

        await login(tester, logFeature: feature);
        expect(find.textContaining('TONASE'), findsOneWidget);
        // featureDetails[feature]!.add('Login berhasil');

        // Filter Tanggal
        await tester.tap(find.byKey(const Key('date-filter-field')));
        await tester.pumpAndSettle(const Duration(seconds: 2));
        await tester.tap(find.text('Save').last);
        await tester.pumpAndSettle(const Duration(seconds: 2));
        featureDetails[feature]!.add('Filter tanggal berhasil');

        // Clear Filter
        await tester.tap(find.byKey(const Key('clear-button')));
        await tester.pumpAndSettle(const Duration(seconds: 2));

        // Filter Area
        await tester.tap(find.byKey(const Key('area-dropdown-filter')));
        await tester.pumpAndSettle();
        final areaOption = find.text('JEPARA').last;
        expect(areaOption, findsOneWidget);
        await tester.tap(areaOption);
        await tester.pumpAndSettle(const Duration(seconds: 2));
        expect(find.textContaining('JEPARA'), findsWidgets);
        featureDetails[feature]!.add('Filter area berhasil');

        // Clear Filter
        await tester.tap(find.byKey(const Key('clear-button')));
        await tester.pumpAndSettle(const Duration(seconds: 2));

        // Pencarian
        await tester.enterText(
          find.byKey(const Key('search-field')),
          '07-0001',
        );
        await tester.pumpAndSettle(const Duration(seconds: 1));
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pumpAndSettle(const Duration(seconds: 2));
        expect(find.textContaining('07-0001'), findsWidgets);
        await tester.tap(find.byKey(const Key('clear-search')));
        await tester.pumpAndSettle(const Duration(seconds: 2));
        featureDetails[feature]!.add('Pencarian data berhasil');

        // Detail Per Koli
        final checkbox = find.descendant(
          of: find.byKey(const Key('home-data-table')),
          matching: find.byType(Checkbox),
        );
        expect(checkbox, findsWidgets);
        await tester.tap(checkbox.last);
        await tester.pumpAndSettle(const Duration(seconds: 2));

        // Scroll Horizontal & Tampilkan Aksi
        final scrollable = find.byType(SingleChildScrollView).first;
        await tester.drag(scrollable, const Offset(-1000, 0));
        await tester.pumpAndSettle(const Duration(seconds: 2));

        await tester.tap(find.byKey(const Key('select-action')).first);
        await tester.pumpAndSettle(const Duration(seconds: 2));
        expect(find.byKey(const Key('viewDetails-button')), findsOneWidget);
        expect(find.byKey(const Key('edit-button')), findsOneWidget);
        expect(find.byKey(const Key('delete-button')), findsOneWidget);

        await tester.tap(find.byKey(const Key('viewDetails-button')).first);
        await tester.pumpAndSettle(const Duration(seconds: 2));
        expect(find.textContaining('Detail Tonase'), findsOneWidget);
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('close-viewDetails')));
        await tester.pumpAndSettle(const Duration(seconds: 2));
        expect(find.textContaining('Data Tonase'), findsOneWidget);
        featureDetails[feature]!.add('Melihat detail per koli berhasil');

        // Mark as Sent
        await tester.drag(scrollable, const Offset(1000, 0));
        await tester.pumpAndSettle(const Duration(seconds: 2));

        await tester.tap(checkbox.first);
        await tester.pumpAndSettle(const Duration(seconds: 1));
        await tester.tap(find.byKey(const Key('mark-button')));
        await tester.pumpAndSettle(const Duration(seconds: 2));
        expect(find.textContaining('Data Berhasil di Kirim.'), findsOneWidget);
        featureDetails[feature]!.add('Data berhasil di-mark as sent');

        // Navigasi ke AreaPage
        await tester.tap(find.byKey(const Key('menu-button')));
        await tester.pumpAndSettle(const Duration(seconds: 1));
        await tester.tap(find.byKey(const Key('area-menu-button')));
        await tester.pumpAndSettle(const Duration(seconds: 2));
        featureDetails[feature]!.add('Navigasi ke halaman Area berhasil');
        await tester.tap(find.byType(BackButton));
        await tester.pumpAndSettle();

        // Navigasi ke CustomerPage
        await tester.tap(find.byKey(const Key('menu-button')));
        await tester.pumpAndSettle(const Duration(seconds: 1));
        await tester.tap(find.byKey(const Key('customer-menu-button')));
        await tester.pumpAndSettle(const Duration(seconds: 2));
        featureDetails[feature]!.add('Navigasi ke halaman Customer berhasil');
        await tester.tap(find.byType(BackButton));
        await tester.pumpAndSettle();

        // Navigasi ke RekapPage
        await tester.tap(find.byKey(const Key('menu-button')));
        await tester.pumpAndSettle(const Duration(seconds: 1));
        await tester.tap(find.byKey(const Key('rekap-menu-button')));
        await tester.pumpAndSettle(const Duration(seconds: 2));
        featureDetails[feature]!.add('Navigasi ke halaman Rekap berhasil');
        await tester.tap(find.byType(BackButton));
        await tester.pumpAndSettle();

        // Navigasi ke HistoriPage
        await tester.tap(find.byKey(const Key('menu-button')));
        await tester.pumpAndSettle(const Duration(seconds: 1));
        await tester.tap(find.byKey(const Key('histori-menu-button')));
        await tester.pumpAndSettle(const Duration(seconds: 2));
        featureDetails[feature]!.add('Navigasi ke halaman Histori berhasil');
        await tester.tap(find.byType(BackButton));
        await tester.pumpAndSettle();

        // Tandai sukses
        featureResults[feature] = true;
      } catch (e) {
        rethrow;
      }
    });

    testWidgets('6. Rekap Harian & Ekspor Laporan', (tester) async {
      const feature = 'Rekap Harian & Ekspor';

      try {
        app.main();
        await tester.pumpAndSettle(const Duration(seconds: 3));
        featureDetails[feature]!.add('Aplikasi berhasil dimulai');

        await login(tester, logFeature: feature);
        expect(find.textContaining('TONASE'), findsOneWidget);
        // featureDetails[feature]!.add('Login berhasil');

        // Navigasi ke Rekap
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('menu-button')));
        await tester.pumpAndSettle(const Duration(seconds: 1));
        await tester.tap(find.byKey(const Key('rekap-menu-button')));
        await tester.pumpAndSettle(const Duration(seconds: 2));
        featureDetails[feature]!.add('Navigasi ke halaman Rekap berhasil');

        // Ekspor PDF
        await tester.tap(find.byKey(const Key('export-button')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('pdf-export-button')));
        await tester.pumpAndSettle();
        await tester.pump(const Duration(seconds: 1));
        expect(
          find.textContaining('File PDF berhasil disimpan'),
          findsOneWidget,
        );
        featureDetails[feature]!.add('Ekspor PDF berhasil');

        // Ekspor Excel
        await tester.pumpAndSettle(const Duration(seconds: 5));
        await tester.ensureVisible(find.byKey(const Key('export-button')));
        await tester.tap(find.byKey(const Key('export-button')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('excel-export-button')));
        await tester.pumpAndSettle();
        await tester.pump(const Duration(seconds: 1));
        expect(
          find.textContaining('File Excel berhasil disimpan'),
          findsOneWidget,
        );
        featureDetails[feature]!.add('Ekspor Excel berhasil');

        // Tandai sukses
        featureResults[feature] = true;
      } catch (e) {
        rethrow;
      }
    });

    testWidgets('7. History & Unmark', (tester) async {
      const feature = 'History & Unmark';

      try {
        app.main();
        await tester.pumpAndSettle(const Duration(seconds: 3));
        featureDetails[feature]!.add('Aplikasi berhasil dimulai');

        await login(tester, logFeature: feature);
        expect(find.textContaining('TONASE'), findsOneWidget);
        // featureDetails[feature]!.add('Login berhasil dan masuk ke HomePage');

        // Navigasi ke halaman histori
        await tester.tap(find.byKey(const Key('menu-button')));
        await tester.pumpAndSettle(const Duration(seconds: 1));
        await tester.tap(find.byKey(const Key('histori-menu-button')));
        await tester.pumpAndSettle(const Duration(seconds: 2));
        featureDetails[feature]!.add('Navigasi ke halaman History berhasil');

        // Unmark data
        final historyTable = find.byKey(const Key('histori-data-table'));
        final checkboxUnmark = find
            .descendant(of: historyTable, matching: find.byType(Checkbox))
            .first;
        await tester.scrollUntilVisible(
          checkboxUnmark,
          50.0,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();
        await tester.tap(checkboxUnmark);
        await tester.pumpAndSettle(const Duration(seconds: 2));

        await tester.tap(find.byKey(const Key('unmark-button')));
        await tester.pumpAndSettle();
        await tester.pump(const Duration(seconds: 5));
        expect(find.textContaining('Berhasil Unmark Data.'), findsOneWidget);
        await tester.pumpAndSettle(const Duration(seconds: 2));
        expect(find.textContaining('Data Tonase'), findsOneWidget);
        featureDetails[feature]!.add('Unmark data berhasil');

        // Tandai sukses
        featureResults[feature] = true;
      } catch (e) {
        rethrow;
      }
    });
  });

  // 6. Cetak SUMMARY REPORT
  tearDownAll(() async {
    final summary = StringBuffer();
    final now = DateTime.now();
    final timestamp = DateFormat('dd-MM-yyyy HH-mm-ss').format(now);

    summary.writeln('============== LAPORAN INTEGRATION TESTS ==============');
    summary.writeln();
    summary.writeln('Tanggal & Waktu Pengujian: $timestamp');
    summary.writeln();
    summary.writeln('-------------------------------------------------------');
    summary.writeln('| No | Fitur Utama                        |  Hasil    |');
    summary.writeln('-------------------------------------------------------');

    var no = 1;
    featureResults.forEach((feature, passed) {
      final status = passed ? 'Berhasil' : 'Gagal';
      summary.writeln(
        '${no.toString().padRight(3)} ${feature.padRight(40)} $status',
      );
      for (var d in featureDetails[feature]!) {
        summary.writeln('     • $d');
      }
      no++;
    });

    final output = summary.toString();
    debugPrint(output);

    // Simpan ke file (gunakan utilitas saveReportAsAsset jika sudah ada)
    debugPrint(output);
    await saveReportAsAssetTemp(
      output,
      filename: 'Integration Test $timestamp.txt',
    );
  });
}
