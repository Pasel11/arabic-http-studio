import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:arabic_http_studio/widgets/common_widgets.dart';

void main() {
  group('CommonWidgets', () {
    testWidgets('EmptyStateWidget displays correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyStateWidget(
              icon: Icons.inbox,
              title: 'لا توجد بيانات',
              message: 'ابدأ بإضافة عنصر جديد',
            ),
          ),
        ),
      );

      expect(find.text('لا توجد بيانات'), findsOneWidget);
      expect(find.text('ابدأ بإضافة عنصر جديد'), findsOneWidget);
      expect(find.byIcon(Icons.inbox), findsOneWidget);
    });

    testWidgets('EmptyStateWidget with action displays button', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmptyStateWidget(
              icon: Icons.add,
              title: 'عنوان',
              message: 'رسالة',
              actionLabel: 'إضافة',
              onAction: () {},
            ),
          ),
        ),
      );

      expect(find.text('إضافة'), findsOneWidget);
    });

    testWidgets('ErrorStateWidget displays error message', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ErrorStateWidget(
              message: 'حدث خطأ في الاتصال',
            ),
          ),
        ),
      );

      expect(find.text('حدث خطأ'), findsOneWidget);
      expect(find.text('حدث خطأ في الاتصال'), findsOneWidget);
    });

    testWidgets('LoadingWidget displays spinner', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LoadingWidget(message: 'جاري التحميل...'),
          ),
        ),
      );

      expect(find.text('جاري التحميل...'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('MethodBadge displays method name', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MethodBadge(method: 'GET'),
          ),
        ),
      );

      expect(find.text('GET'), findsOneWidget);
    });

    testWidgets('StatusBadge displays status code', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StatusBadge(statusCode: 200),
          ),
        ),
      );

      expect(find.text('200'), findsOneWidget);
    });

    testWidgets('ConfirmationDialog shows and returns true on confirm',
        (tester) async {
      bool? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () async {
                  result = await ConfirmationDialog.show(
                    context,
                    title: 'تأكيد',
                    message: 'هل أنت متأكد؟',
                  );
                },
                child: const Text('Show'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show'));
      await tester.pumpAndSettle();

      expect(find.text('تأكيد'), findsOneWidget);
      expect(find.text('هل أنت متأكد؟'), findsOneWidget);

      await tester.tap(find.text('تأكيد'));
      await tester.pumpAndSettle();

      expect(result, isTrue);
    });

    testWidgets('ConfirmationDialog returns false on cancel', (tester) async {
      bool? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () async {
                  result = await ConfirmationDialog.show(
                    context,
                    title: 'تأكيد',
                    message: 'هل أنت متأكد؟',
                    cancelText: 'إلغاء',
                  );
                },
                child: const Text('Show'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('إلغاء'));
      await tester.pumpAndSettle();

      expect(result, isFalse);
    });
  });
}
