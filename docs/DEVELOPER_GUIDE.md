# 📖 دليل المطور - Arabic HTTP Studio

هذا الدليل مخصص للمطورين الذين يرغبون في المساهمة في المشروع أو توسيعه.

## 📋 جدول المحتويات

1. [هيكل المشروع](#هيكل-المشروع)
2. [طبقات التطبيق](#طبقات-التطبيق)
3. [كيفية إضافة ميزة جديدة](#كيفية-إضافة-ميزة-جديدة)
4. [كيفية إضافة مزود AI جديد](#كيفية-إضافة-مزود-ai-جديد)
5. [كيفية إضافة شاشة جديدة](#كيفية-إضافة-شاشة-جديدة)
6. [كيفية إنشاء اختبار جديد](#كيفية-إنشاء-اختبار-جديد)
7. [كيفية إنشاء Plugin جديد](#كيفية-إنشاء-plugin-جديد)

---

## هيكل المشروع

```
lib/
├── main.dart                          # نقطة الدخول
├── app/
│   └── app.dart                       # التطبيق الرئيسي
├── core/                              # الطبقة الأساسية
│   ├── constants/                     # الثوابت
│   ├── database/                      # إعداد قاعدة البيانات
│   ├── error/                         # معالجة الأخطاء
│   ├── network/                       # خدمات الشبكة
│   │   ├── network_service.dart       # خدمة HTTP (Dio)
│   │   └── websocket_service.dart     # خدمة WebSocket و SSE
│   ├── router/                        # التنقل (GoRouter)
│   ├── services/                      # الخدمات الأساسية
│   │   ├── backup_service.dart        # النسخ الاحتياطي
│   │   ├── dynamic_color_service.dart # الألوان الديناميكية
│   │   ├── encryption_service.dart    # التشفير
│   │   └── initialization_service.dart # التهيئة
│   ├── theme/                         # الثيم
│   │   ├── app_theme.dart             # ثيم Material 3
│   │   └── app_animations.dart        # الرسوم المتحركة
│   └── utils/                         # الأدوات المساعدة
│       ├── app_utils.dart             # أدوات عامة
│       ├── cache_manager.dart         # إدارة الذاكرة المؤقتة
│       ├── debounce_throttle.dart     # debounce و throttle
│       ├── isolate_service.dart       # العمليات في الخلفية
│       └── pagination.dart            # التحميل التدريجي
├── features/                          # الميزات (كل ميزة مستقلة)
│   ├── ai/                            # الذكاء الاصطناعي
│   │   ├── contracts/                 # العقود والواجهات
│   │   ├── models/                    # النماذج
│   │   ├── providers/                 # مزودي AI
│   │   ├── services/                  # خدمات AI
│   │   ├── screens/                   # الشاشات
│   │   └── widgets/                   # الـ widgets
│   ├── authentication/                # المصادقة
│   ├── collections/                   # المجموعات والمشاريع
│   ├── developer_tools/               # أدوات المطور
│   ├── environment/                   # البيئات
│   ├── export/                        # الاستيراد والتصدير
│   ├── favorites/                     # المفضلة
│   ├── history/                       # المحفوظات
│   ├── home/                          # الصفحة الرئيسية
│   ├── logs/                          # السجلات
│   ├── plugins/                       # نظام الإضافات
│   │   ├── contracts/                 # عقود الإضافات
│   │   ├── models/                    # نماذج الإضافات
│   │   └── registry/                  # سجل الإضافات
│   ├── request/                       # منشئ الطلب
│   ├── settings/                      # الإعدادات
│   ├── tools/                         # الأدوات
│   │   ├── compare/                   # أدوات المقارنة
│   │   ├── crypto/                    # أدوات التشفير
│   │   ├── encoding/                  # أدوات الترميز
│   │   ├── file_explorer/             # مستكشف الملفات
│   │   ├── json/                      # أدوات JSON
│   │   ├── reports/                   # التقارير
│   │   ├── sessions/                  # إدارة الجلسات
│   │   └── xml/                       # أدوات XML
│   ├── variables/                     # المتغيرات
│   └── websocket/                     # WebSocket
└── widgets/                           # الـ widgets المشتركة
    ├── code_editor.dart               # محرر الكود
    ├── common_widgets.dart            # widgets عامة
    └── main_shell.dart                # الهيكل الرئيسي
```

---

## طبقات التطبيق

يتبع المشروع **Clean Architecture** مع الفصل التالي:

### 1. طبقة العرض (Presentation Layer)
- **Screens**: شاشات Flutter
- **Widgets**: مكونات قابلة لإعادة الاستخدام
- **Providers**: مزودي Riverpod لإدارة الحالة

### 2. طبقة المنطق (Domain Layer)
- **Services**: منطق الأعمال
- **Contracts**: واجهات وعقود
- **Models**: نماذج البيانات

### 3. طبقة البيانات (Data Layer)
- **Repositories**: الوصول للبيانات
- **Database**: قاعدة البيانات (Hive)
- **Network**: خدمات الشبكة

### قواعد الاعتماد
- العرض يعتمد على المنطق
- المنطق يعتمد على البيانات
- البيانات لا تعتمد على أي طبقة أعلى
- استخدم Dependency Injection عبر Riverpod

---

## كيفية إضافة ميزة جديدة

لإضافة ميزة جديدة، اتبع هذه الخطوات:

### 1. إنشاء هيكل المجلدات

```bash
mkdir -p lib/features/my_feature/{models,repositories,services,screens,widgets,providers}
```

### 2. إنشاء النموذج (Model)

```dart
// lib/features/my_feature/models/my_model.dart
import 'dart:convert';

class MyModel {
  MyModel({
    required this.id,
    required this.name,
  });

  final String id;
  final String name;

  Map<String, dynamic> toJson() => {'id': id, 'name': name};
  String toJsonString() => jsonEncode(toJson());

  factory MyModel.fromJson(Map<String, dynamic> json) => MyModel(
        id: json['id'] as String,
        name: json['name'] as String,
      );
  factory MyModel.fromJsonString(String s) =>
      MyModel.fromJson(jsonDecode(s) as Map<String, dynamic>);
}
```

### 3. إنشاء المستودع (Repository)

```dart
// lib/features/my_feature/repositories/my_repository.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../../../core/error/app_error.dart';
import '../models/my_model.dart';

class MyRepository {
  MyRepository(this._box);
  final Box<String> _box;

  List<MyModel> getAll() => _box.values.map(MyModel.fromJsonString).toList();

  Future<void> save(MyModel model) async {
    await _box.put(model.id, model.toJsonString());
  }
}

final myRepositoryProvider = Provider<MyRepository>((ref) {
  return MyRepository(Hive.box<String>('my_feature'));
});
```

### 4. إنشاء الشاشة (Screen)

```dart
// lib/features/my_feature/screens/my_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/my_repository.dart';

class MyScreen extends ConsumerWidget {
  const MyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(myRepositoryProvider).getAll();
    return Scaffold(
      appBar: AppBar(title: const Text('ميزتي')),
      body: ListView.builder(
        itemCount: items.length,
        itemBuilder: (context, index) => ListTile(
          title: Text(items[index].name),
        ),
      ),
    );
  }
}
```

### 5. إضافة المسار (Route)

```dart
// في lib/core/router/app_router.dart
GoRoute(
  path: '/my-feature',
  name: 'myFeature',
  builder: (context, state) => const MyScreen(),
),
```

### 6. فتح صندوق Hive

```dart
// في lib/core/database/hive_setup.dart
await Hive.openBox<String>('my_feature');
```

---

## كيفية إضافة مزود AI جديد

لإضافة مزود ذكاء اصطناعي جديد:

### 1. تنفيذ واجهة AiProvider

```dart
// lib/features/ai/providers/my_ai_provider.dart
import '../contracts/ai_provider.dart';

class MyAiProvider implements AiProvider {
  MyAiProvider(this._config);
  final AiProviderConfig _config;

  @override
  String get id => 'my_ai';

  @override
  String get displayName => 'My AI Service';

  @override
  String get description => 'وصف المزود';

  @override
  bool get requiresApiKey => true;

  @override
  bool get isConfigured => _config.apiKey.isNotEmpty;

  @override
  int get maxTokens => 4000;

  @override
  String? validateConfiguration() {
    return _config.apiKey.isEmpty ? 'مفتاح API مطلوب' : null;
  }

  @override
  Future<AiResponse> chat({
    required String systemPrompt,
    required String userMessage,
    String? context,
    int? maxTokens,
    double? temperature,
  }) async {
    // تنفيذ منطق الاتصال بالخدمة
    throw UnimplementedError();
  }

  @override
  Stream<String> chatStream({
    required String systemPrompt,
    required String userMessage,
    String? context,
    int? maxTokens,
    double? temperature,
  }) async* {
    // تنفيذ البث
    throw UnimplementedError();
  }

  @override
  Future<bool> testConnection() async {
    return true;
  }

  @override
  void dispose() {}
}
```

### 2. تسجيل المزود

```dart
// عند تهيئة التطبيق
AiProviderRegistry.instance.register(MyAiProvider(config));
```

---

## كيفية إضافة شاشة جديدة

1. أنشئ الشاشة في `lib/features/my_feature/screens/`
2. أضف المسار في `lib/core/router/app_router.dart`
3. أضف رابطًا في الشاشة المناسبة (مثل Tools Hub)

---

## كيفية إنشاء اختبار جديد

### اختبار وحدة (Unit Test)

```dart
// test/unit/my_service_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:arabic_http_studio/features/my_feature/services/my_service.dart';

void main() {
  group('MyService', () {
    test('should do something', () {
      final service = MyService();
      expect(service.doSomething(), expectedResult);
    });
  });
}
```

### اختبار Widget

```dart
// test/widget/my_widget_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:arabic_http_studio/features/my_feature/widgets/my_widget.dart';

void main() {
  testWidgets('MyWidget displays correctly', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: MyWidget()));
    expect(find.text('Hello'), findsOneWidget);
  });
}
```

---

## كيفية إنشاء Plugin جديد

لإنشاء إضافة (Plugin):

### 1. تنفيذ واجهة AppPlugin

```dart
// lib/features/plugins/my_plugin.dart
import 'contracts/plugin.dart';

class MyPlugin implements AppPlugin {
  @override
  String get id => 'my_plugin';

  @override
  String get displayName => 'My Plugin';

  @override
  String get description => 'وصف الإضافة';

  @override
  String get version => '1.0.0';

  @override
  String? get author => 'اسمك';

  @override
  void register(PluginContext context) {
    context.registerTool(ToolDefinition(
      id: 'my_tool',
      displayName: 'My Tool',
      description: 'أداة مخصصة',
      icon: Icons.extension,
      category: 'custom',
      builder: (context) => const MyToolScreen(),
    ));
  }

  @override
  Future<void> initialize() async {
    // التهيئة
  }

  @override
  Future<void> dispose() async {
    // التنظيف
  }
}
```

### 2. تسجيل الإضافة

```dart
// عند بدء التطبيق
final pluginContext = PluginContext(
  registerTool: (tool) => PluginRegistry.instance.addTool('my_plugin', tool),
  registerAiProvider: (provider) => AiProviderRegistry.instance.register(provider),
  registerExportFormat: (format) => PluginRegistry.instance.addExportFormat('my_plugin', format),
  registerImportFormat: (format) => PluginRegistry.instance.addImportFormat('my_plugin', format),
  registerScreen: (screen) => PluginRegistry.instance.addScreen('my_plugin', screen),
  registerSettingsSection: (section) => PluginRegistry.instance.addSettingsSection('my_plugin', section),
  getSetting: (key) => null,
  setSetting: (key, value) async {},
);

await PluginRegistry.instance.registerPlugin(MyPlugin(), pluginContext);
```

---

## أفضل الممارسات

### الكود
- ✅ اتبع أسلوب الكود الموجود
- ✅ وثق جميع الدوال العامة
- ✅ استخدم أسماء واضحة ومعبرة
- ✅ لا تكرر الكود (DRY)
- ✅ افصل المسؤوليات (SRP)

### الأداء
- ✅ استخدم `const` حيثما أمكن
- ✅ استخدم Isolates للعمليات الثقيلة
- ✅ استخدم Cache للبيانات المتكررة
- ✅ استخدم Pagination للقوائم الطويلة
- ✅ استخدم Debounce للأحداث المتكررة

### الأمان
- ✅ استخدم flutter_secure_storage للبيانات الحساسة
- ✅ شفّر الأسرار قبل تخزينها
- ✅ لا تسجل البيانات الحساسة في السجلات
- ✅ تحقق من المدخلات

### الاختبارات
- ✅ اكتب اختبارات لكل ميزة جديدة
- ✅ حافظ على تغطية > 80%
- ✅ اختبر الحالات الحدية
- ✅ استخدم أسماء واضحة للاختبارات
