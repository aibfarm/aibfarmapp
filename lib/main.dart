import 'dart:convert';
import 'package:flutter/foundation.dart' as foundation;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:aibfarm_app/screens/dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String? token = prefs.getString('auth_token'); // 保持原来的键名
  bool isTokenValid = false;
  List<String> debugLogs = ["启动: 检查本地 token..."];

  if (token != null) {
    debugLogs.add("找到 token: $token");
    try {
      final response = await http.get(
        Uri.parse('https://dashboard.aibfarm.com/hello'),
        headers: {'Authorization': 'Bearer $token'},
      );
      debugLogs.add("Token 验证状态码: ${response.statusCode}");
      debugLogs.add("Token 验证响应: ${response.body}");
      isTokenValid = response.statusCode == 200;
    } catch (e) {
      debugLogs.add("Token 验证错误: $e");
      isTokenValid = false;
    }
  } else {
    debugLogs.add("未找到本地 token");
  }

  runApp(MyApp(initialRoute: isTokenValid ? '/dashboard' : '/login', debugLogs: debugLogs));
}

class MyApp extends StatelessWidget {
  final String initialRoute;
  final List<String> debugLogs;

  MyApp({required this.initialRoute, required this.debugLogs});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AIBFarm App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.white,
      ),
      initialRoute: initialRoute,
      routes: {
        '/login': (context) => LoginPage(debugLogs: debugLogs),
        '/dashboard': (context) => const DashboardScreen(), // 改为使用DashboardScreen
      },
    );
  }
}

class LoginPage extends StatefulWidget {
  final List<String> debugLogs;

  LoginPage({required this.debugLogs});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool isLoading = false;

  void updateDebugInfo(String newInfo) {
    if (foundation.kDebugMode) {
      setState(() {
        widget.debugLogs.add(newInfo);
        if (widget.debugLogs.length > 50) widget.debugLogs.removeAt(0);
      });
    }
  }

  Future<void> _login() async {
    setState(() {
      isLoading = true;
    });
    updateDebugInfo("开始登录...");
    String username = _usernameController.text;
    String password = _passwordController.text;

    if (username.isEmpty || password.isEmpty) {
      updateDebugInfo("错误: 用户名或密码为空");
      setState(() {
        isLoading = false;
      });
      return;
    }

    updateDebugInfo("用户名: $username, 密码: $password");

    try {
      final response = await http.post(
        Uri.parse('https://dashboard.aibfarm.com/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'password': password}),
      );

      updateDebugInfo("响应状态码: ${response.statusCode}");
      updateDebugInfo("响应内容: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String token = data['token'];
        updateDebugInfo("登录成功，token: $token");

        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', token); // 保持原来的键名
        // 保存用户信息到DashboardScreen需要的格式
        await prefs.setString('token', token); // 同时保存为DashboardScreen需要的键名
        if (data['user'] != null) {
          await prefs.setString('user', jsonEncode(data['user']));
        } else {
          // 如果API没有返回用户信息，创建一个基本的用户对象
          await prefs.setString('user', jsonEncode({'name': username}));
        }

        Navigator.pushReplacementNamed(context, '/dashboard');
      } else {
        updateDebugInfo("登录失败: ${response.body}");
      }
    } catch (e) {
      updateDebugInfo("网络错误: $e");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('登录页面')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _usernameController,
              decoration: InputDecoration(labelText: '用户名'),
            ),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(labelText: '密码'),
              obscureText: true,
            ),
            SizedBox(height: 20),
            isLoading
                ? CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _login,
                    child: Text('登录'),
                  ),
            if (foundation.kDebugMode)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  color: Colors.black12,
                  height: 150,
                  child: SingleChildScrollView(
                    child: SelectableText(
                      widget.debugLogs.join('\n'),
                      style: TextStyle(color: Colors.red, fontSize: 14),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}