# 🔧 SABOHUB Debug System

Hệ thống debug toàn diện cho SABOHUB Flutter Web App với Chrome DevTools integration.

## 🚀 Tính năng chính

### 1. **Multi-Level Logging**
- ✅ Verbose, Debug, Info, Warning, Error, Critical
- ✅ Colored output trong Chrome Console
- ✅ Icons và timestamps
- ✅ Structured data logging

### 2. **Web Console Integration** 
- ✅ Tự động log vào Chrome DevTools
- ✅ Grouped logs với expand/collapse
- ✅ Custom console commands
- ✅ Export logs functionality

### 3. **HTTP Request/Response Logging**
- ✅ Automatic Dio interceptor
- ✅ Request/Response headers và body
- ✅ Performance timing
- ✅ Error tracking
- ✅ Sensitive data sanitization

### 4. **In-App Debug Console**
- ✅ Floating debug console widget
- ✅ Real-time log filtering
- ✅ Search functionality
- ✅ Export logs
- ✅ Performance metrics

### 5. **Performance Monitoring**
- ✅ Widget lifecycle timing
- ✅ API response times
- ✅ Navigation performance
- ✅ Memory usage tracking

## 📦 Setup và Installation

### 1. Thêm vào pubspec.yaml
```yaml
dependencies:
  dio: ^5.0.0
  # Các dependencies khác...
```

### 2. Initialize trong main.dart
```dart
import 'package:flutter/foundation.dart';
import 'lib/examples/debug_system_example.dart';

void main() {
  // Initialize debug system
  if (kDebugMode) {
    DebugSystemExample.initializeDebugSystem();
    MainAppIntegration.initializeLifecycleObserver();
  }
  
  runApp(MainAppIntegration.buildApp());
}
```

### 3. Wrap app với Debug Overlay
```dart
MaterialApp(
  builder: (context, child) {
    if (child == null) return const SizedBox.shrink();
    
    // Add debug overlay in debug mode
    if (kDebugMode) {
      return DebugOverlay(child: child);
    }
    
    return child;
  },
  home: YourHomePage(),
)
```

## 🎯 Cách sử dụng

### 1. **Basic Logging**
```dart
import '../utils/debug_utils.dart';

// Global logging
DebugUtils.info('User logged in', data: {
  'userId': 123,
  'email': 'user@example.com',
  'timestamp': DateTime.now().toIso8601String(),
});

DebugUtils.error('Login failed', exception: e, stackTrace: stackTrace);
```

### 2. **Using Debug Mixin trong Services**
```dart
class UserService with DebugMixin {
  Future<User> login(String email, String password) async {
    debugInfo('Login attempt', data: {'email': email});
    
    try {
      // Your login logic
      final user = await api.login(email, password);
      
      debugInfo('Login successful', data: {
        'userId': user.id,
        'role': user.role,
      });
      
      return user;
    } catch (e, stackTrace) {
      debugError('Login failed', exception: e, stackTrace: stackTrace);
      rethrow;
    }
  }
}
```

### 3. **HTTP Logging với Dio**
```dart
// Setup HTTP client với debug logging
final dio = DebugDio.create(
  options: BaseOptions(
    baseUrl: 'https://api.sabohub.com',
    connectTimeout: Duration(seconds: 30),
  ),
  logRequestHeaders: true,
  logRequestBody: true,
  logResponseBody: true,
  logOnlyErrors: false, // Set true trong production
);

// Sử dụng như Dio bình thường
final response = await dio.get('/users');
```

### 4. **Widget Debug Wrapper**
```dart
class MyWidget extends StatefulWidget with DebugMixin {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Text('Hello World'),
    ).withDebug(
      name: 'MyWidget',
      enablePerformanceLogging: true,
    );
  }
}
```

### 5. **Performance Logging**
```dart
class DataService with DebugMixin {
  Future<List<User>> fetchUsers() async {
    final stopwatch = Stopwatch()..start();
    
    try {
      final users = await api.getUsers();
      
      stopwatch.stop();
      debugPerformance('Fetch Users', stopwatch.elapsed, data: {
        'userCount': users.length,
        'cacheHit': false,
      });
      
      return users;
    } catch (e) {
      stopwatch.stop();
      debugError('Fetch users failed', 
        exception: e, 
        data: {'duration': stopwatch.elapsed.inMilliseconds}
      );
      rethrow;
    }
  }
}
```

### 6. **State Change Logging**
```dart
class CounterBloc with DebugMixin {
  int _count = 0;
  
  void increment() {
    final oldValue = _count;
    _count++;
    
    debugState('counter', oldValue, _count, action: 'increment');
    
    if (_count % 10 == 0) {
      debugWarning('Counter milestone reached', data: {
        'value': _count,
        'isSignificant': true,
      });
    }
  }
}
```

## 🎮 Chrome DevTools Usage

### 1. **Mở Chrome DevTools Console**
- Nhấn F12 hoặc Ctrl+Shift+I
- Chuyển tới tab "Console"

### 2. **Filter Logs theo Level**
```javascript
// Trong console, filter theo level
console.filter = 'error';  // Chỉ hiện errors
console.filter = 'info';   // Chỉ hiện info logs
console.filter = '';       // Hiện tất cả
```

### 3. **Export Logs**
```javascript
// Export logs to JSON file
SABOHUB_DEBUG.exportLogs();

// Get all logs
const logs = SABOHUB_DEBUG.getLogs();
console.table(logs);

// Get only errors
const errors = SABOHUB_DEBUG.getErrors();
console.table(errors);

// Clear logs
SABOHUB_DEBUG.clearLogs();
```

### 4. **Change Debug Level**
```javascript
// Set minimum log level
SABOHUB_DEBUG.setLevel('debug');    // verbose, debug, info, warning, error, critical
SABOHUB_DEBUG.setLevel('error');    // Chỉ hiện errors và critical
```

## 🎨 In-App Debug Console

### 1. **Mở Debug Console**
- Click vào Debug FAB (floating action button) màu xanh/đỏ
- Hoặc long press vào bất kỳ widget nào
- Hoặc gọi `DebugProvider().showConsole()`

### 2. **Console Commands**
```
clear           - Clear all logs
level <level>   - Filter by level (verbose, debug, info, warning, error, critical)
tag <tag>       - Filter by tag
export          - Export logs to clipboard
help            - Show available commands
```

### 3. **Features**
- ✅ Real-time log filtering
- ✅ Search logs
- ✅ Show only errors toggle
- ✅ Auto-scroll toggle
- ✅ Expandable log details
- ✅ Copy logs to clipboard

## 🔧 Configuration

### 1. **Debug Service Settings**
```dart
DebugService().initialize(
  enabled: kDebugMode,
  minLevel: DebugLevel.debug,
  showInWebConsole: true,
  saveToStorage: true,
  maxLogs: 1000,
);
```

### 2. **HTTP Interceptor Settings**
```dart
DebugDio.create(
  logRequestHeaders: true,    // Log request headers
  logRequestBody: true,       // Log request body
  logResponseHeaders: false,  // Skip response headers
  logResponseBody: true,      // Log response body
  logOnlyErrors: false,       // Log all requests hoặc chỉ errors
);
```

### 3. **Production Setup**
```dart
// Trong production, chỉ log errors
DebugService().initialize(
  enabled: kReleaseMode ? false : true,
  minLevel: DebugLevel.error,
  showInWebConsole: false,
  saveToStorage: false,
);
```

## 📊 Performance Monitoring

### 1. **Widget Performance**
```dart
MyWidget().withDebug(
  name: 'MyWidget',
  enablePerformanceLogging: true,
);
```

### 2. **API Performance**
```dart
// Tự động log với HTTP interceptor
// Hoặc manual:
DebugUtils.info('API Call', data: {
  'endpoint': '/users',
  'method': 'GET',
  'duration': '250ms',
  'statusCode': 200,
});
```

### 3. **Memory Monitoring**
```dart
// Log memory usage
DebugUtils.logMemoryUsage();
```

## 🚨 Troubleshooting

### 1. **Debug Console không hiện**
- Kiểm tra `kDebugMode` = true
- Đảm bảo `DebugOverlay` đã được wrap
- Gọi `DebugProvider().showConsole()`

### 2. **Logs không hiện trong Chrome**
- Mở DevTools Console (F12)
- Kiểm tra `showInWebConsole: true`
- Clear console và refresh page

### 3. **HTTP logs không hoạt động**
- Đảm bảo sử dụng `DebugDio.create()`
- Hoặc add manual interceptor vào Dio instance

### 4. **Performance impact**
- Chỉ enable trong debug mode
- Set `logOnlyErrors: true` nếu cần thiết
- Giới hạn `maxLogs` để tránh memory leak

## 🎯 Best Practices

### 1. **Structured Logging**
```dart
// Good ✅
debugInfo('User action', data: {
  'action': 'button_click',
  'buttonId': 'submit_form',
  'userId': user.id,
  'timestamp': DateTime.now().toIso8601String(),
});

// Bad ❌
debugInfo('User clicked submit button');
```

### 2. **Error Context**
```dart
// Good ✅
try {
  await api.uploadFile(file);
} catch (e, stackTrace) {
  debugError('File upload failed', 
    exception: e, 
    stackTrace: stackTrace,
    data: {
      'fileName': file.name,
      'fileSize': file.size,
      'uploadAttempt': attempt,
    }
  );
}

// Bad ❌
debugError('Upload failed');
```

### 3. **Performance Tracking**
```dart
// Good ✅
final stopwatch = Stopwatch()..start();
await heavyOperation();
stopwatch.stop();

debugPerformance('Heavy Operation', stopwatch.elapsed, data: {
  'itemCount': items.length,
  'complexity': 'high',
  'cacheUsed': true,
});
```

### 4. **Tag Organization**
```dart
// Organize bằng feature/module
debugInfo('Message', tag: 'Auth');
debugInfo('Message', tag: 'API');
debugInfo('Message', tag: 'UI');
debugInfo('Message', tag: 'Database');
```

## 🔄 Testing Debug System

### 1. **Generate Test Logs**
```dart
import '../examples/debug_system_example.dart';

// Generate various log levels
DebugCommands.generateTestLogs();

// Simulate errors
DebugCommands.simulateErrors();
```

### 2. **Test Console Commands**
```
// Trong debug console:
help                    // Show available commands
clear                   // Clear logs
level error            // Show only errors
tag HTTP               // Show only HTTP logs
export                 // Export to clipboard
```

## 📋 Integration Checklist

- [ ] Add debug services to project
- [ ] Initialize in main.dart
- [ ] Wrap app với DebugOverlay
- [ ] Setup HTTP client với DebugDio
- [ ] Add DebugMixin to services
- [ ] Test debug console functionality
- [ ] Test Chrome DevTools integration
- [ ] Configure for production
- [ ] Document team usage guidelines

---

## 🎉 Kết luận

Hệ thống debug này sẽ giúp team SABOHUB:

1. **Phát hiện lỗi nhanh hơn** với detailed logging
2. **Monitor performance** real-time
3. **Debug API issues** dễ dàng với HTTP logging
4. **Track user behavior** với navigation và state logging
5. **Optimize app performance** với timing metrics

**Happy Debugging! 🐛🔧**