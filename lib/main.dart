import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_application_base/core/app/app_init_info.dart';
import 'package:flutter_application_base/flutter_application_base.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:new_api_chat/chat/chat_detail_page.dart';
import 'package:new_api_chat/chat/chat_index_page.dart';
import 'package:new_api_chat/route/collapse_data_item.dart';

Future<void> main() async {
  // 使用 runZonedGuarded 包装整个应用
  runZonedGuarded<Future<void>>(
    () async {
      // 确保 Flutter 绑定初始化
      WidgetsFlutterBinding.ensureInitialized();

      // 设置 Flutter 框架异常处理器
      FlutterError.onError = (FlutterErrorDetails details) {
        print('Flutter框架异常：${details.exception}');
        print('堆栈跟踪：${details.stack}');
        _handleGlobalError(
          details.exception,
          details.stack ?? StackTrace.current,
        );
      };

      // 设置平台异常处理器（Flutter 3.3+）
      PlatformDispatcher.instance.onError = (error, stack) {
        print('平台异常：$error');
        print('堆栈跟踪：$stack');
        _handleGlobalError(error, stack);
        return true; // 表示异常已处理
      };

      // 初始化框架模块
      await FrameworkModuleManager.initialize(
        AppInitInfo(
          child: const MyApp(),
          appRouterConfig: AppRouterConfig(defaultRoutes: _buildRoute()),
        ),
      );
    },
    (Object error, StackTrace stack) {
      // 全局异步异常处理
      print('runZonedGuarded捕获异常：$error\n$stack');
      _handleGlobalError(error, stack);
    },
  );
}

List<CollapseDataItem> router_list = [
  CollapseDataItem(
    headerValue: 'go_route路由测试',
    items: [
      Item(title: '首页', page: '/', targetPage: ChatIndexPage()),
      Item(title: '聊天', page: '/chat_detail', targetPage: ChatDetailPage()),
    ],
  ),
];



List<RouteBase> _buildRoute() {
  var routeList =
      router_list.expand((e) {
        return e.items.map((e1) {
          return GoRoute(
            path: e1.page,
            name: e1.title,
            builder: (context, state) {
              return e1.targetPage;
            },
          );
        }).toList();
      }).toList();
  return routeList;
}

/// 处理全局错误
void _handleGlobalError(Object error, StackTrace stack) {
  // 实现全局错误处理逻辑
  // 1. 记录错误日志
  debugPrint('全局错误：$error');
  debugPrint('堆栈跟踪：$stack');

  // 2. 可以在这里添加错误报告逻辑
  // 例如发送到错误监控服务

  // 3. 显示用户友好的错误提示（需要确保应用已初始化）
  try {
    SmartDialog.show(
      builder:
          (_) => Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.red.shade100,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.shade300),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error, color: Colors.red, size: 32),
                const SizedBox(height: 8),
                const Text(
                  '应用发生错误',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(height: 8),
                const Text('请重启应用或联系技术支持'),
                const SizedBox(height: 8),
                Text(
                  error.toString(),
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
    );
  } catch (e) {
    // 如果 SmartDialog 不可用，使用系统级错误处理
    debugPrint('无法显示错误对话框：$e');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // TRY THIS: Try changing the color here to a specific color (to
        // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
        // change color while the other colors stay the same.
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          //
          // TRY THIS: Invoke "debug painting" (choose the "Toggle Debug Paint"
          // action in the IDE, or press "p" in the console), to see the
          // wireframe for each widget.
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text('You have pushed the button this many times:'),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.explore),
              label: const Text('功能测试导航'),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
