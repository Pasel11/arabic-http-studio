import 'package:flutter_test/flutter_test.dart';
import 'package:arabic_http_studio/features/request/models/http_request.dart';
import 'package:arabic_http_studio/features/request/services/code_generator_service.dart';

void main() {
  group('CodeGeneratorService', () {
    final service = CodeGeneratorService.instance;

    final testRequest = HttpRequestModel(
      id: 'test-id',
      name: 'Test Request',
      method: 'GET',
      url: 'https://api.example.com/users',
      headers: [
        HeaderItem(key: 'Content-Type', value: 'application/json'),
        HeaderItem(key: 'Authorization', value: 'Bearer token123'),
      ],
      queryParams: [
        QueryParam(key: 'page', value: '1'),
        QueryParam(key: 'limit', value: '10'),
      ],
    );

    test('generateCurl produces valid cURL command', () {
      final curl = service.generateCurl(testRequest);

      expect(curl, contains('curl'));
      expect(curl, contains('-X GET'));
      expect(curl, contains('https://api.example.com/users'));
      expect(curl, contains('-H "Content-Type: application/json"'));
      expect(curl, contains('-H "Authorization: Bearer token123"'));
    });

    test('generateDart produces Dart code', () {
      final dart = service.generateDart(testRequest);

      expect(dart, contains("import 'package:dio/dio.dart'"));
      expect(dart, contains('Dio()'));
      expect(dart, contains("'GET'"));
      expect(dart, contains('https://api.example.com/users'));
    });

    test('generateFetch produces JavaScript Fetch code', () {
      final fetch = service.generateFetch(testRequest);

      expect(fetch, contains("fetch("));
      expect(fetch, contains("method: 'GET'"));
      expect(fetch, contains('https://api.example.com/users'));
    });

    test('generatePython produces Python code', () {
      final python = service.generatePython(testRequest);

      expect(python, contains('import requests'));
      expect(python, contains('"GET"'));
      expect(python, contains('https://api.example.com/users'));
    });

    test('generateJava produces Java code', () {
      final java = service.generateJava(testRequest);

      expect(java, contains('import okhttp3.*'));
      expect(java, contains('OkHttpClient'));
      expect(java, contains('"GET"'));
    });

    test('generateKotlin produces Kotlin code', () {
      final kotlin = service.generateKotlin(testRequest);

      expect(kotlin, contains('import okhttp3.*'));
      expect(kotlin, contains('OkHttpClient()'));
      expect(kotlin, contains('"GET"'));
    });

    test('generatePhp produces PHP code', () {
      final php = service.generatePhp(testRequest);

      expect(php, contains('<?php'));
      expect(php, contains('curl_init'));
      expect(php, contains('"GET"'));
    });

    test('generateNodeJs produces Node.js code', () {
      final nodejs = service.generateNodeJs(testRequest);

      expect(nodejs, contains("require('http')"));
      expect(nodejs, contains("'GET'"));
    });

    test('generateGo produces Go code', () {
      final go = service.generateGo(testRequest);

      expect(go, contains('package main'));
      expect(go, contains('"GET"'));
      expect(go, contains('http.NewRequest'));
    });

    test('generateRust produces Rust code', () {
      final rust = service.generateRust(testRequest);

      expect(rust, contains('use reqwest'));
      expect(rust, contains('"GET"'));
    });

    test('generateCSharp produces C# code', () {
      final csharp = service.generateCSharp(testRequest);

      expect(csharp, contains('using System'));
      expect(csharp, contains('HttpClient'));
    });

    test('generateJavaScript produces JavaScript Axios code', () {
      final js = service.generateJavaScript(testRequest);

      expect(js, contains('axios'));
      expect(js, contains("method: 'GET'"));
    });

    test('generate throws on unsupported language', () {
      expect(
        () => service.generate(testRequest, 'unsupported'),
        throwsArgumentError,
      );
    });

    test('generates code with POST method and body', () {
      final postRequest = HttpRequestModel(
        id: 'test-id',
        name: 'POST Test',
        method: 'POST',
        url: 'https://api.example.com/users',
        headers: [HeaderItem(key: 'Content-Type', value: 'application/json')],
        body: BodyItem(
          type: 'json',
          rawContent: '{"name": "John", "email": "john@example.com"}',
        ),
      );

      final curl = service.generateCurl(postRequest);

      expect(curl, contains('-X POST'));
      expect(curl, contains('-d'));
      expect(curl, contains('"name": "John"'));
    });
  });
}
