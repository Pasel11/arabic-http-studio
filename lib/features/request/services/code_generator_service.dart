import '../../request/models/http_request.dart';
import '../../../core/utils/app_utils.dart';

/// Service for generating code in multiple programming languages
class CodeGeneratorService {
  CodeGeneratorService._();
  static final CodeGeneratorService instance = CodeGeneratorService._();

  /// Generate code for the specified language
  String generate(HttpRequestModel request, String language) {
    switch (language.toLowerCase()) {
      case 'curl':
        return generateCurl(request);
      case 'dart':
        return generateDart(request);
      case 'fetch':
        return generateFetch(request);
      case 'python':
        return generatePython(request);
      case 'java':
        return generateJava(request);
      case 'kotlin':
        return generateKotlin(request);
      case 'php':
        return generatePhp(request);
      case 'nodejs':
      case 'node':
        return generateNodeJs(request);
      case 'go':
        return generateGo(request);
      case 'rust':
        return generateRust(request);
      case 'csharp':
      case 'c#':
        return generateCSharp(request);
      case 'javascript':
      case 'js':
        return generateJavaScript(request);
      default:
        throw ArgumentError('Unsupported language: $language');
    }
  }

  /// Generate cURL command
  String generateCurl(HttpRequestModel request) {
    final buffer = StringBuffer();
    buffer.writeln("curl -X ${request.method} \\");
    buffer.writeln('  "${request.fullUrl}" \\');

    // Headers
    for (final header in request.headers.where((h) => h.enabled)) {
      buffer.writeln('  -H "${header.key}: ${header.value}" \\');
    }

    // Auth headers
    if (request.auth != null) {
      final authHeaders = request.auth!.getAdditionalHeaders();
      for (final entry in authHeaders.entries) {
        buffer.writeln('  -H "${entry.key}: ${entry.value}" \\');
      }
    }

    // Body
    if (request.body != null && request.body!.type != 'none') {
      final body = request.body!;
      if (body.type == 'json' || body.type == 'text' || body.type == 'xml' || body.type == 'html') {
        buffer.writeln("  -d '${body.rawContent ?? ''}' \\");
      } else if (body.type == 'form' && body.formFields != null) {
        for (final field in body.formFields!.where((f) => f.enabled)) {
          buffer.writeln('  -F "${field.key}=${field.value}" \\');
        }
      } else if (body.type == 'multipart' && body.fileFields != null) {
        for (final field in body.formFields?.where((f) => f.enabled) ?? <FormFieldItem>[]) {
          buffer.writeln('  -F "${field.key}=${field.value}" \\');
        }
        for (final file in body.fileFields!.where((f) => f.enabled)) {
          buffer.writeln('  -F "${file.key}=@${file.filePath}" \\');
        }
      }
    }

    // Remove trailing backslash and newline
    final result = buffer.toString().trimRight();
    if (result.endsWith('\\')) {
      return result.substring(0, result.length - 1).trimRight();
    }
    return result;
  }

  /// Generate Dart Dio code
  String generateDart(HttpRequestModel request) {
    final buffer = StringBuffer();
    buffer.writeln("import 'package:dio/dio.dart';");
    buffer.writeln();
    buffer.writeln('Future<void> sendRequest() async {');
    buffer.writeln('  final dio = Dio();');
    buffer.writeln();
    buffer.writeln('  final options = Options(');
    buffer.writeln("    method: '${request.method}',");
    if (request.headers.where((h) => h.enabled).isNotEmpty || request.auth != null) {
      buffer.writeln('    headers: {');
      for (final header in request.headers.where((h) => h.enabled)) {
        buffer.writeln("      '${header.key}': '${_escapeString(header.value)}',");
      }
      if (request.auth != null) {
        for (final entry in request.auth!.getAdditionalHeaders().entries) {
          buffer.writeln("      '${entry.key}': '${_escapeString(entry.value)}',");
        }
      }
      buffer.writeln('    },');
    }
    buffer.writeln('  );');
    buffer.writeln();
    buffer.writeln('  try {');
    buffer.writeln('    final response = await dio.request(');
    buffer.writeln("      '${_escapeString(request.fullUrl)}',");
    if (request.body != null && request.body!.rawContent != null) {
      buffer.writeln("      data: '''${request.body!.rawContent}''',");
    }
    buffer.writeln('      options: options,');
    buffer.writeln('    );');
    buffer.writeln();
    buffer.writeln("    print('Status: \${response.statusCode}');");
    buffer.writeln("    print('Response: \${response.data}');");
    buffer.writeln('  } catch (e) {');
    buffer.writeln("    print('Error: \$e');");
    buffer.writeln('  }');
    buffer.writeln('}');

    return buffer.toString();
  }

  /// Generate JavaScript Fetch API code
  String generateFetch(HttpRequestModel request) {
    final buffer = StringBuffer();
    buffer.writeln("const url = '${request.fullUrl}';");
    buffer.writeln();

    final hasBody = request.body != null && request.body!.rawContent != null;
    buffer.writeln('const options = {');
    buffer.writeln("  method: '${request.method}',");

    if (request.headers.where((h) => h.enabled).isNotEmpty || request.auth != null) {
      buffer.writeln('  headers: {');
      for (final header in request.headers.where((h) => h.enabled)) {
        buffer.writeln("    '${header.key}': '${_escapeString(header.value)}',");
      }
      if (request.auth != null) {
        for (final entry in request.auth!.getAdditionalHeaders().entries) {
          buffer.writeln("    '${entry.key}': '${_escapeString(entry.value)}',");
        }
      }
      buffer.writeln('  },');
    }

    if (hasBody) {
      buffer.writeln('  body: JSON.stringify(${request.body!.rawContent}),');
    }

    buffer.writeln('};');
    buffer.writeln();
    buffer.writeln('fetch(url, options)');
    buffer.writeln('  .then(response => response.json())');
    buffer.writeln('  .then(data => console.log(data))');
    buffer.writeln("  .catch(error => console.error('Error:', error));");

    return buffer.toString();
  }

  /// Generate Python Requests code
  String generatePython(HttpRequestModel request) {
    final buffer = StringBuffer();
    buffer.writeln('import requests');
    buffer.writeln('import json');
    buffer.writeln();
    buffer.writeln('url = "${request.fullUrl}"');
    buffer.writeln();

    if (request.headers.where((h) => h.enabled).isNotEmpty || request.auth != null) {
      buffer.writeln('headers = {');
      for (final header in request.headers.where((h) => h.enabled)) {
        buffer.writeln('    "${header.key}": "${_escapeString(header.value)}",');
      }
      if (request.auth != null) {
        for (final entry in request.auth!.getAdditionalHeaders().entries) {
          buffer.writeln('    "${entry.key}": "${_escapeString(entry.value)}",");
        }
      }
      buffer.writeln('}');
      buffer.writeln();
    }

    if (hasBody(request)) {
      if (request.body!.type == 'json') {
        buffer.writeln('payload = json.dumps(${request.body!.rawContent})');
      } else {
        buffer.writeln('payload = "${_escapeString(request.body!.rawContent ?? '')}"');
      }
      buffer.writeln();
    }

    buffer.writeln('response = requests.request(');
    buffer.writeln('    method="${request.method}",');
    buffer.writeln('    url=url,');
    if (request.headers.where((h) => h.enabled).isNotEmpty) {
      buffer.writeln('    headers=headers,');
    }
    if (hasBody(request)) {
      buffer.writeln('    data=payload,');
    }
    buffer.writeln(')');
    buffer.writeln();
    buffer.writeln('print(response.status_code)');
    buffer.writeln('print(response.text)');

    return buffer.toString();
  }

  /// Generate Java OkHttp code
  String generateJava(HttpRequestModel request) {
    final buffer = StringBuffer();
    buffer.writeln('import okhttp3.*;');
    buffer.writeln();
    buffer.writeln('public class Main {');
    buffer.writeln('    public static void main(String[] args) {');
    buffer.writeln('        OkHttpClient client = new OkHttpClient();');
    buffer.writeln();
    buffer.writeln('        Request.Builder requestBuilder = new Request.Builder()');
    buffer.writeln('                .url("${request.fullUrl}")');
    buffer.writeln('                .method("${request.method}", null);');
    buffer.writeln();

    for (final header in request.headers.where((h) => h.enabled)) {
      buffer.writeln('        requestBuilder.addHeader("${header.key}", "${_escapeString(header.value)}");');
    }
    if (request.auth != null) {
      for (final entry in request.auth!.getAdditionalHeaders().entries) {
        buffer.writeln('        requestBuilder.addHeader("${entry.key}", "${_escapeString(entry.value)}");');
      }
    }

    if (hasBody(request)) {
      buffer.writeln();
      buffer.writeln('        RequestBody body = RequestBody.create(');
      buffer.writeln('            "${_escapeString(request.body!.rawContent ?? '')}",');
      buffer.writeln('            MediaType.parse("${request.body!.type == 'json' ? 'application/json' : 'text/plain'}")');
      buffer.writeln('        );');
      buffer.writeln('        requestBuilder.method("${request.method}", body);');
    }

    buffer.writeln();
    buffer.writeln('        Request request = requestBuilder.build();');
    buffer.writeln();
    buffer.writeln('        try (Response response = client.newCall(request).execute()) {');
    buffer.writeln('            System.out.println(response.code());');
    buffer.writeln('            System.out.println(response.body().string());');
    buffer.writeln('        } catch (Exception e) {');
    buffer.writeln('            e.printStackTrace();');
    buffer.writeln('        }');
    buffer.writeln('    }');
    buffer.writeln('}');

    return buffer.toString();
  }

  /// Generate Kotlin code
  String generateKotlin(HttpRequestModel request) {
    final buffer = StringBuffer();
    buffer.writeln('import okhttp3.*');
    buffer.writeln('import java.io.IOException');
    buffer.writeln();
    buffer.writeln('fun main() {');
    buffer.writeln('    val client = OkHttpClient()');
    buffer.writeln();
    buffer.writeln('    val requestBuilder = Request.Builder()');
    buffer.writeln('        .url("${request.fullUrl}")');
    buffer.writeln('        .method("${request.method}", null)');
    buffer.writeln();

    for (final header in request.headers.where((h) => h.enabled)) {
      buffer.writeln('        .addHeader("${header.key}", "${_escapeString(header.value)}")');
    }
    if (request.auth != null) {
      for (final entry in request.auth!.getAdditionalHeaders().entries) {
        buffer.writeln('        .addHeader("${entry.key}", "${_escapeString(entry.value)}")');
      }
    }

    buffer.writeln();
    buffer.writeln('    val request = requestBuilder.build()');
    buffer.writeln();
    buffer.writeln('    client.newCall(request).enqueue(object : Callback {');
    buffer.writeln('        override fun onFailure(call: Call, e: IOException) {');
    buffer.writeln('            e.printStackTrace()');
    buffer.writeln('        }');
    buffer.writeln();
    buffer.writeln('        override fun onResponse(call: Call, response: Response) {');
    buffer.writeln('            println(response.code)');
    buffer.writeln('            response.body?.string()?.let { println(it) }');
    buffer.writeln('        }');
    buffer.writeln('    })');
    buffer.writeln('}');

    return buffer.toString();
  }

  /// Generate PHP code
  String generatePhp(HttpRequestModel request) {
    final buffer = StringBuffer();
    buffer.writeln('<?php');
    buffer.writeln();
    buffer.writeln('\$ch = curl_init();');
    buffer.writeln();
    buffer.writeln('curl_setopt(\$ch, CURLOPT_URL, "${request.fullUrl}");');
    buffer.writeln('curl_setopt(\$ch, CURLOPT_RETURNTRANSFER, true);');
    buffer.writeln('curl_setopt(\$ch, CURLOPT_CUSTOMREQUEST, "${request.method}");');
    buffer.writeln();

    if (request.headers.where((h) => h.enabled).isNotEmpty || request.auth != null) {
      buffer.writeln('\$headers = [');
      for (final header in request.headers.where((h) => h.enabled)) {
        buffer.writeln('    "${header.key}: ${_escapeString(header.value)}",');
      }
      if (request.auth != null) {
        for (final entry in request.auth!.getAdditionalHeaders().entries) {
          buffer.writeln('    "${entry.key}: ${_escapeString(entry.value)}",');
        }
      }
      buffer.writeln('];');
      buffer.writeln('curl_setopt(\$ch, CURLOPT_HTTPHEADER, \$headers);');
      buffer.writeln();
    }

    if (hasBody(request)) {
      buffer.writeln("curl_setopt(\$ch, CURLOPT_POSTFIELDS, '${_escapeString(request.body!.rawContent ?? '')}');");
      buffer.writeln();
    }

    buffer.writeln('\$response = curl_exec(\$ch);');
    buffer.writeln('\$httpCode = curl_getinfo(\$ch, CURLINFO_HTTP_CODE);');
    buffer.writeln();
    buffer.writeln('echo "Status: \$httpCode\\n";');
    buffer.writeln('echo \$response . "\\n";');
    buffer.writeln();
    buffer.writeln('curl_close(\$ch);');

    return buffer.toString();
  }

  /// Generate Node.js code
  String generateNodeJs(HttpRequestModel request) {
    final buffer = StringBuffer();
    buffer.writeln("const http = require('http');");
    buffer.writeln("const https = require('https');");
    buffer.writeln();
    buffer.writeln("const url = new URL('${request.fullUrl}');");
    buffer.writeln("const client = url.protocol === 'https:' ? https : http;");
    buffer.writeln();
    buffer.writeln('const options = {');
    buffer.writeln('    hostname: url.hostname,');
    buffer.writeln('    port: url.port,');
    buffer.writeln('    path: url.pathname + url.search,');
    buffer.writeln("    method: '${request.method}',");
    if (request.headers.where((h) => h.enabled).isNotEmpty) {
      buffer.writeln('    headers: {');
      for (final header in request.headers.where((h) => h.enabled)) {
        buffer.writeln("        '${header.key}': '${_escapeString(header.value)}',");
      }
      buffer.writeln('    },');
    }
    buffer.writeln('};');
    buffer.writeln();
    buffer.writeln("const req = client.request(options, (res) => {");
    buffer.writeln("    let data = '';");
    buffer.writeln("    res.on('data', (chunk) => { data += chunk; });");
    buffer.writeln("    res.on('end', () => {");
    buffer.writeln('        console.log(`Status: \${res.statusCode}`);');
    buffer.writeln('        console.log(data);');
    buffer.writeln('    });');
    buffer.writeln('});');
    buffer.writeln();

    if (hasBody(request)) {
      buffer.writeln("req.write('${_escapeString(request.body!.rawContent ?? '')}');");
      buffer.writeln();
    }

    buffer.writeln("req.on('error', (error) => {");
    buffer.writeln('    console.error(error);');
    buffer.writeln('});');
    buffer.writeln();
    buffer.writeln('req.end();');

    return buffer.toString();
  }

  /// Generate Go code
  String generateGo(HttpRequestModel request) {
    final buffer = StringBuffer();
    buffer.writeln('package main');
    buffer.writeln();
    buffer.writeln('import (');
    buffer.writeln('    "fmt"');
    buffer.writeln('    "io"');
    buffer.writeln('    "net/http"');
    buffer.writeln('    "strings"');
    buffer.writeln(')');
    buffer.writeln();
    buffer.writeln('func main() {');
    buffer.writeln('    url := "${request.fullUrl}"');
    if (hasBody(request)) {
      buffer.writeln('    body := strings.NewReader(`${request.body!.rawContent ?? ''}`)');
    }
    buffer.writeln();
    if (hasBody(request)) {
      buffer.writeln('    req, err := http.NewRequest("${request.method}", url, body)');
    } else {
      buffer.writeln('    req, err := http.NewRequest("${request.method}", url, nil)');
    }
    buffer.writeln('    if err != nil {');
    buffer.writeln('        panic(err)');
    buffer.writeln('    }');
    buffer.writeln();

    for (final header in request.headers.where((h) => h.enabled)) {
      buffer.writeln('    req.Header.Set("${header.key}", "${_escapeString(header.value)}")');
    }
    if (request.auth != null) {
      for (final entry in request.auth!.getAdditionalHeaders().entries) {
        buffer.writeln('    req.Header.Set("${entry.key}", "${_escapeString(entry.value)}")');
      }
    }

    buffer.writeln();
    buffer.writeln('    client := &http.Client{}');
    buffer.writeln('    resp, err := client.Do(req)');
    buffer.writeln('    if err != nil {');
    buffer.writeln('        panic(err)');
    buffer.writeln('    }');
    buffer.writeln('    defer resp.Body.Close()');
    buffer.writeln();
    buffer.writeln('    bodyBytes, _ := io.ReadAll(resp.Body)');
    buffer.writeln('    fmt.Println("Status:", resp.Status)');
    buffer.writeln('    fmt.Println("Response:", string(bodyBytes))');
    buffer.writeln('}');

    return buffer.toString();
  }

  /// Generate Rust code
  String generateRust(HttpRequestModel request) {
    final buffer = StringBuffer();
    buffer.writeln('use reqwest;');
    buffer.writeln('use std::error::Error;');
    buffer.writeln();
    buffer.writeln('#[tokio::main]');
    buffer.writeln('async fn main() -> Result<(), Box<dyn Error>> {');
    buffer.writeln('    let client = reqwest::Client::new();');
    buffer.writeln();
    buffer.writeln('    let mut request = client.request("${request.method}", "${request.fullUrl}");');
    buffer.writeln();

    for (final header in request.headers.where((h) => h.enabled)) {
      buffer.writeln('    request = request.header("${header.key}", "${_escapeString(header.value)}");');
    }
    if (request.auth != null) {
      for (final entry in request.auth!.getAdditionalHeaders().entries) {
        buffer.writeln('    request = request.header("${entry.key}", "${_escapeString(entry.value)}");');
      }
    }

    if (hasBody(request)) {
      buffer.writeln('    request = request.body(r#"${request.body!.rawContent ?? ''}"#.to_string());');
    }

    buffer.writeln();
    buffer.writeln('    let response = request.send().await?;');
    buffer.writeln('    println!("Status: {}", response.status());');
    buffer.writeln('    let body = response.text().await?;');
    buffer.writeln('    println!("Response: {}", body);');
    buffer.writeln();
    buffer.writeln('    Ok(())');
    buffer.writeln('}');

    return buffer.toString();
  }

  /// Generate C# code
  String generateCSharp(HttpRequestModel request) {
    final buffer = StringBuffer();
    buffer.writeln('using System;');
    buffer.writeln('using System.Net.Http;');
    buffer.writeln('using System.Threading.Tasks;');
    buffer.writeln();
    buffer.writeln('class Program');
    buffer.writeln('{');
    buffer.writeln('    static async Task Main(string[] args)');
    buffer.writeln('    {');
    buffer.writeln('        using var client = new HttpClient();');
    buffer.writeln();

    if (request.headers.where((h) => h.enabled).isNotEmpty) {
      for (final header in request.headers.where((h) => h.enabled)) {
        buffer.writeln('        client.DefaultRequestHeaders.Add("${header.key}", "${_escapeString(header.value)}");');
      }
    }
    if (request.auth != null) {
      for (final entry in request.auth!.getAdditionalHeaders().entries) {
        buffer.writeln('        client.DefaultRequestHeaders.Add("${entry.key}", "${_escapeString(entry.value)}");');
      }
    }

    buffer.writeln();
    buffer.writeln('        try');
    buffer.writeln('        {');

    if (hasBody(request)) {
      buffer.writeln('            var content = new StringContent(@"${request.body!.rawContent ?? ''}", System.Text.Encoding.UTF8, "application/json");');
      buffer.writeln('            var response = await client.${_getMethodAsync(request.method)}("${request.fullUrl}", content);');
    } else {
      buffer.writeln('            var response = await client.${_getMethodAsync(request.method)}("${request.fullUrl}");');
    }

    buffer.writeln('            Console.WriteLine($"Status: {(int)response.StatusCode} {response.StatusCode}");');
    buffer.writeln('            var body = await response.Content.ReadAsStringAsync();');
    buffer.writeln('            Console.WriteLine($"Response: {body}");');
    buffer.writeln('        }');
    buffer.writeln('        catch (Exception ex)');
    buffer.writeln('        {');
    buffer.writeln('            Console.WriteLine($"Error: {ex.Message}");');
    buffer.writeln('        }');
    buffer.writeln('    }');
    buffer.writeln('}');

    return buffer.toString();
  }

  String _getMethodAsync(String method) {
    switch (method.toUpperCase()) {
      case 'GET':
        return 'GetAsync';
      case 'POST':
        return 'PostAsync';
      case 'PUT':
        return 'PutAsync';
      case 'PATCH':
        return 'PatchAsync';
      case 'DELETE':
        return 'DeleteAsync';
      default:
        return 'SendAsync';
    }
  }

  /// Generate JavaScript (Axios) code
  String generateJavaScript(HttpRequestModel request) {
    final buffer = StringBuffer();
    buffer.writeln("const axios = require('axios');");
    buffer.writeln();
    buffer.writeln('const config = {');
    buffer.writeln("    method: '${request.method}',");
    buffer.writeln("    url: '${request.fullUrl}',");

    if (request.headers.where((h) => h.enabled).isNotEmpty || request.auth != null) {
      buffer.writeln('    headers: {');
      for (final header in request.headers.where((h) => h.enabled)) {
        buffer.writeln("        '${header.key}': '${_escapeString(header.value)}',");
      }
      if (request.auth != null) {
        for (final entry in request.auth!.getAdditionalHeaders().entries) {
          buffer.writeln("        '${entry.key}': '${_escapeString(entry.value)}',");
        }
      }
      buffer.writeln('    },');
    }

    if (hasBody(request)) {
      buffer.writeln('    data: ${request.body!.rawContent},');
    }

    buffer.writeln('};');
    buffer.writeln();
    buffer.writeln('axios(config)');
    buffer.writeln('    .then(response => {');
    buffer.writeln('        console.log(`Status: \${response.status}`);');
    buffer.writeln('        console.log(response.data);');
    buffer.writeln('    })');
    buffer.writeln('    .catch(error => {');
    buffer.writeln('        console.error(error);');
    buffer.writeln('    });');

    return buffer.toString();
  }

  bool hasBody(HttpRequestModel request) {
    return request.body != null &&
        request.body!.type != 'none' &&
        request.body!.rawContent != null &&
        request.body!.rawContent!.isNotEmpty;
  }

  String _escapeString(String value) {
    return value
        .replaceAll('\\', '\\\\')
        .replaceAll('"', '\\"')
        .replaceAll("'", "\\'")
        .replaceAll('\n', '\\n')
        .replaceAll('\r', '\\r')
        .replaceAll('\t', '\\t');
  }
}
