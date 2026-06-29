# 🚀 Arabic HTTP Studio v2.0 - Enterprise Edition

<p align="center">
  <strong>منصة احترافية لإدارة طلبات HTTP و WebSocket مع الذكاء الاصطناعي</strong>
</p>

<p align="center">
  <a href="#المميزات">المميزات</a> •
  <a href="#التثبيت">التثبيت</a> •
  <a href="#الاستخدام">الاستخدام</a> •
  <a href="#للمطورين">للمطورين</a> •
  <a href="#المساهمة">المساهمة</a>
</p>

---

## 📖 نظرة عامة

**Arabic HTTP Studio** هو منصة احترافية لإدارة طلبات HTTP و WebSocket، مصممة للمطورين والشركات. يدعم التطبيق الذكاء الاصطناعي، نظام الإضافات، إدارة الجلسات، وأدوات تطوير متقدمة - كل ذلك بواجهة عربية احترافية كاملة.

### 🏆 لماذا Arabic HTTP Studio؟

- ✅ **منصة متكاملة**: كل ما تحتاجه في مكان واحد
- ✅ **ذكاء اصطناعي مدمج**: مساعد ذكي لتحليل وتحسين طلباتك
- ✅ **قابل للتوسع**: نظام إضافات يسمح بإضافة ميزات جديدة
- ✅ **مؤسسي**: جاهز للاستخدام التجاري على نطاق واسع
- ✅ **عربي بالكامل**: واجهة عربية احترافية مع دعم RTL

---

## ✨ المميزات

### 🤖 الذكاء الاصطناعي (AI)

منصة AI اختيارية تدعم أي مزود OpenAI-compatible:

- **شرح أخطاء HTTP** تلقائيًا
- **اقتراح إصلاحات** للطلبات الفاشلة
- **تحسين الرؤوس** (Headers)
- **اقتراح إعدادات المصادقة**
- **شرح أكواد الاستجابة**
- **تلخيص الاستجابات** الطويلة
- **إنشاء طلبات** من وصف نصي
- **توليد كود** بـ 12 لغة برمجة
- **البحث في السجل** باللغة الطبيعية

**المزودون المدعومون:**
- OpenAI (GPT-3.5, GPT-4)
- Azure OpenAI
- النماذج المحلية (Ollama, vLLM, LM Studio)
- أي نقطة نهاية متوافقة مع OpenAI

### 🔌 نظام الإضافات (Plugins)

بنية قابلة للتوسع تسمح بـ:
- تسجيل أدوات جديدة
- تسجيل مزودي AI مخصصين
- تسجيل صيغ تصدير/استيراد
- تسجيل شاشات مخصصة
- تسجيل أقسام إعدادات

### 🌐 طلبات HTTP
- جميع الطرق: `GET`, `POST`, `PUT`, `PATCH`, `DELETE`, `HEAD`, `OPTIONS`
- Headers, Cookies, Query Parameters
- أنواع المتن: JSON, XML, Form, Multipart, Binary, Text
- HTTP/1.1, HTTP/2, HTTP/3
- TLS مع الشهادات المخصصة
- Proxy: HTTP و SOCKS5
- Server-Sent Events (SSE)
- DNS مخصص وإعادة المحاولة

### 🔐 المصادقة
- Bearer Token, Basic Auth, Digest Auth, API Key, JWT, Custom Auth

### 🔌 WebSocket
- اتصال كامل مع إعادة اتصال تلقائي
- Ping/Pong، رسائل ثنائية ونصية
- سجل الرسائل مع البحث والتصفية

### 💻 محرر الكود الاحترافي
- إبراز الصيغة (JSON, XML, HTML, JavaScript, YAML)
- أرقام الأسطر، البحث والاستبدال
- Undo/Redo، Beautify/Minify، Validation

### 📊 توليد الكود (12 لغة)
cURL, Dart (Dio), JavaScript (Fetch), Python, Java, Kotlin, PHP, Node.js, Go, Rust, C#, JavaScript (Axios)

### 📁 إدارة المشاريع
- Workspace → Project → Folder → Collection → Request
- Tags, Notes, Pinned Items, Recent Items

### 🛠️ أدوات المطور
- **Performance Monitor**: FPS, Memory, CPU, Widget Count
- **Network Inspector**: فحص جميع الطلبات
- **Crash Logs**: سجل الأعطال
- **Storage Viewer**: مستعرض Hive
- **Memory Viewer**: تحليل الذاكرة

### 🔧 أدوات JSON
- Formatter, Validator, Compare, Tree Viewer, Search, Statistics

### 🔧 أدوات XML
- Formatter, Validator, Tree Viewer, Compare

### 🔐 أدوات الترميز والتشفير
- Base64, URL, Unicode, Hex
- MD5, SHA-1, SHA-256, SHA-512, HMAC

### 📋 إدارة الجلسات
- حفظ، استعادة، تسمية، مقارنة الجلسات

### 🔄 المقارنة
- مقارنة طلبين، استجابتين، JSON، Text Diff

### 📁 مستكشف الملفات
- تصفح، معاينة، استيراد، تصدير، إعادة تسمية، تكرار، حذف

### 📊 التقارير
- تقارير شاملة (طلب، استجابة، أداء، أخطاء، ملاحظات)
- تصدير إلى Markdown و HTML

### 💾 الاستيراد والتصدير
- **تصدير**: JSON, YAML, CSV, TXT, ZIP, Markdown, HTML, OpenAPI 3.0, Swagger 2.0, Postman
- **استيراد**: OpenAPI, Swagger, Postman, JSON, YAML, CSV, TXT

### 💽 النسخ الاحتياطي
- نسخ محلي، استعادة، تصدير/استيراد، نسخ تلقائي

### 🎨 الواجهة
- Material 3 / Material You مع Dynamic Color
- دعم كامل للعربية (RTL) والإنجليزية (LTR)
- وضع ليلي/نهاري، Animations احترافية
- Responsive لجميع الأحجام

### ⚡ الأداء
- Isolates للعمليات الثقيلة
- Cache ذكي (LRU + Timed)
- Pagination، Debounce & Throttle، Lazy Loading

### 🏗️ البنية
- Clean Architecture
- Repository Pattern
- Dependency Injection (Riverpod)
- نظام Plugins قابل للتوسع

---

## 📦 التثبيت

### المتطلبات
- Flutter 3.16.0+
- Dart 3.2.0+
- Android Studio / VS Code
- Java 17 (للأندرويد)

### الخطوات

```bash
git clone https://github.com/your-username/arabic-http-studio.git
cd arabic-http-studio
flutter pub get
flutter run
```

### البناء للإنتاج

```bash
# Android APK
flutter build apk --release --split-per-abi

# Android App Bundle
flutter build appbundle --release

# iOS
flutter build ios --release
```

---

## 📚 الاستخدام

### تفعيل الذكاء الاصطناعي
1. اذهب إلى **الإعدادات > الذكاء الاصطناعي**
2. فعّل الميزة وأدخل مفتاح API
3. اختبر الاتصال
4. استخدم المساعد الذكي من شاشة الأدوات

### استخدام الأدوات
1. اضغط على تبويب **الأدوات** في الـ Bottom Navigation
2. اختر الفئة المطلوبة (JSON, XML, Encoding, إلخ)
3. استخدم الأداة

### إدارة الجلسات
1. أنشئ جلسة جديدة من شاشة الجلسات
2. أضف الطلبات إليها
3. احفظ الجلسة لاستعادتها لاحقًا
4. قارن الجلسات لتحليل الفروقات

---

## 🔧 للمطورين

راجع الوثائق التالية:
- [دليل المطور](docs/DEVELOPER_GUIDE.md) - كيفية إضافة ميزات جديدة
- [خارطة الطريق](docs/ROADMAP.md) - خطط التطوير المستقبلية
- [CHANGELOG](CHANGELOG.md) - سجل التغييرات
- [دليل المساهمة](CONTRIBUTING.md) - كيفية المساهمة

### إضافة ميزة جديدة
راجع [دليل المطور](docs/DEVELOPER_GUIDE.md#كيفية-إضافة-ميزة-جديدة) للتعليمات الكاملة.

### إضافة مزود AI جديد
راجع [دليل المطور](docs/DEVELOPER_GUIDE.md#كيفية-إضافة-مزود-ai-جديد).

### إنشاء Plugin
راجع [دليل المطور](docs/DEVELOPER_GUIDE.md#كيفية-إنشاء-plugin-جديد).

---

## 🧪 الاختبارات

```bash
# جميع الاختبارات
flutter test

# اختبارات الوحدة
flutter test test/unit/

# اختبارات الـ Widget
flutter test test/widget/

# مع التغطية
flutter test --coverage
```

---

## 🔄 CI/CD

GitHub Actions تقوم بـ:
- ✅ `flutter analyze` على كل push
- ✅ `flutter test` على كل push
- ✅ بناء APK Debug و Release
- ✅ بناء App Bundle و iOS
- ✅ إنشاء Release عند Tag جديد
- ✅ Dependabot لتحديث التبعيات

---

## 🛡️ الأمان

- 🔒 **تشفير AES-256** للبيانات الحساسة
- 🔒 **flutter_secure_storage** لمفاتيح API
- 🔒 **Android Keystore / iOS Keychain** للتخزين الآمن
- 🔒 لا يتم تسجيل البيانات الحساسة في السجلات

راجع [SECURITY.md](SECURITY.md) للإبلاغ عن الثغرات.

---

## 📊 إحصائيات المشروع

| المؤشر | القيمة |
|--------|--------|
| الإصدار | 2.0.0 |
| ملفات Dart | 110+ |
| الاختبارات | 18+ |
| الشاشات | 18+ |
| الخدمات | 20+ |
| لغات توليد الكود | 12 |
| صيغ التصدير | 10 |
| الميزات | 100+ |

---

## 🤝 المساهمة

راجع [CONTRIBUTING.md](CONTRIBUTING.md) للإرشادات الكاملة.

---

## 📄 الترخيص

هذا المشروع مرخص تحت رخصة MIT - انظر [LICENSE](LICENSE).

---

## 📞 التواصل

- **GitHub Issues**: للإبلاغ عن الأخطاء
- **GitHub Discussions**: للنقاشات والمقترحات
- **Security**: security@arabic-http-studio.com

---

<p align="center">صُنع بـ ❤️ للمطورين العرب</p>
