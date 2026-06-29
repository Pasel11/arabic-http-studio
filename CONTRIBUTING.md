# Contributing to Arabic HTTP Studio

شكرًا لاهتمامك بالمساهمة في **Arabic HTTP Studio**! 🎉

هذا المستند يشرح كيفية المساهمة في المشروع. يرجى قراءته بعناية قبل البدء.

## 📋 جدول المحتويات

- [قواعد السلوك](#قواعد-السلوك)
- [كيف أساهم؟](#كيف-أساهم)
- [إعداد بيئة التطوير](#إعداد-بيئة-التطوير)
- [قواعد الكود](#قواعد-الكود)
- [عملية Pull Request](#عملية-pull-request)
- [الإبلاغ عن الأخطاء](#الإبلاغ-عن-الأخطاء)
- [اقتراح ميزات جديدة](#اقتراح-ميزات-جديدة)

## 🤝 قواعد السلوك

المشاركة في هذا المشروع تخضع لـ [مدونة قواعد السلوك](CODE_OF_CONDUCT.md). ب participating، أنت توافق على الالتزام بهذه القواعد.

## 🚀 كيف أساهم؟

### الإبلاغ عن الأخطاء

1. تحقق من [الأخطاء الموجودة](https://github.com/your-username/arabic-http-studio/issues) لتجنب التكرار
2. أنشئ issue جديد باستخدام قالب [Bug Report](.github/ISSUE_TEMPLATE/bug_report.md)
3. اشرح المشكلة بوضوح مع خطوات إعادة الإنتاج

### اقتراح ميزات

1. تحقق من [الميزات المقترحة](https://github.com/your-username/arabic-http-studio/issues?q=is%3Aissue+label%3Aenhancement)
2. أنشئ issue جديد باستخدام قالب [Feature Request](.github/ISSUE_TEMPLATE/feature_request.md)
3. اشرح الميزة وأهميتها

### المساهمة بالكود

1. Fork المشروع
2. أنشئ فرعًا للميزة (`git checkout -b feature/amazing-feature`)
3. اكتب الكود مع الاختبارات
4. تأكد من نجاح `flutter analyze` و `flutter test`
5. Commit التغييرات (`git commit -m 'Add amazing feature'`)
6. Push للفرع (`git push origin feature/amazing-feature`)
7. افتح Pull Request

## 🛠️ إعداد بيئة التطوير

### المتطلبات

- Flutter 3.16.0 أو أحدث
- Dart 3.2.0 أو أحدث
- Android Studio / VS Code
- Java 17

### الخطوات

```bash
# استنساخ المشروع
git clone https://github.com/your-username/arabic-http-studio.git
cd arabic-http-studio

# تثبيت التبعيات
flutter pub get

# توليد الكود (إذا لزم الأمر)
dart run build_runner build --delete-conflicting-outputs

# تشغيل التطبيق
flutter run

# تشغيل الاختبارات
flutter test

# تحليل الكود
flutter analyze
```

## 📝 قواعد الكود

### أسلوب الكود

- اتبع [Dart Style Guide](https://dart.dev/guides/language/effective-dart/style)
- استخدم `dart format` لتنسيق الكود
- لا تترك كودًا معطلاً أو تعليقات غير ضرورية
- وثق جميع الدوال والclasses العامة

### التسمية

- **Classes**: PascalCase (`HttpRequestModel`)
- **Variables/Functions**: camelCase (`sendRequest`)
- **Constants**: lowerCamelCase (`defaultTimeout`)
- **Files**: snake_case (`http_request.dart`)

### البنية

- اتبع Clean Architecture
- استخدم Repository Pattern
- افصل بين طبقات البيانات والمنطق والعرض
- استخدم Riverpod لإدارة الحالة

### الاختبارات

- اكتب اختبارات لكل ميزة جديدة
- حافظ على تغطية الاختبارات > 80%
- استخدم أسماء واضحة للاختبارات
- اختبر الحالات الحدية

```dart
// مثال على اختبار جيد
test('should return true when URL is valid HTTP', () {
  expect(AppUtils.isValidUrl('http://example.com'), isTrue);
});
```

### الأمان

- لا تضع أي بيانات حساسة في الكود
- استخدم flutter_secure_storage للبيانات الحساسة
- تحقق من المدخلات
- لا تستخدم بروتوكولات غير آمنة

## 🔄 عملية Pull Request

### قبل الإرسال

- [ ] الكود يمر بـ `flutter analyze` بدون أخطاء
- [ ] جميع الاختبارات تنجح `flutter test`
- [ ] تم تنسيق الكود `dart format`
- [ ] تم تحديث التوثيق إذا لزم الأمر
- [ ] تمت إضافة اختبارات للميزات الجديدة

### قالب Pull Request

استخدم [قالب Pull Request](.github/PULL_REQUEST_TEMPLATE.md) عند الإرسال.

### مراجعة الكود

- انتظر مراجعة المُحافظين
- استجب للتعليقات بسرعة
- قد يُطلب منك إجراء تعديلات
- كن محترمًا ومنفتحًا للنقد البناء

## 🏷️ إصدار الإصدارات

نتبع [Semantic Versioning](https://semver.org/):

- **MAJOR**: تغييرات غير متوافقة
- **MINOR**: ميزات جديدة متوافقة
- **PATCH**: إصلاحات الأخطاء

## 📞 التواصل

- [GitHub Issues](https://github.com/your-username/arabic-http-studio/issues)
- [GitHub Discussions](https://github.com/your-username/arabic-http-studio/discussions)

---

شكرًا لمساهمتك في جعل Arabic HTTP Studio أفضل! 🙏
