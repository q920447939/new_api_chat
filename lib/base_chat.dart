import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_chat_core/flutter_chat_core.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:gpt_markdown/gpt_markdown.dart';

class Basic extends StatefulWidget {
  const Basic({super.key});

  @override
  BasicState createState() => BasicState();
}

class BasicState extends State<Basic> {
  final _chatController = InMemoryChatController();

  var message = '''
    ## ChatGPT Response
```html
<html>
<head>
    <meta charset="UTF-8">
    <title>手机卡数据统计报告</title>
    <style>
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            line-height: 1.6;
            color: #333;
            max-width: 600px;
            margin: 0 auto;
            padding: 20px;
        }
        .container {
            background-color: #ffffff;
            border-radius: 8px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
            padding: 25px;
        }
        .header {
            text-align: center;
            margin-bottom: 25px;
        }
        .header h1 {
            color: #007BFF;
            margin: 0;
            font-size: 24px;
        }
        .status {
            background-color: #E8F5E9;
            color: #2E7D32;
            padding: 12px;
            border-radius: 4px;
            margin-bottom: 25px;
            text-align: center;
            font-weight: 600;
        }
        .data-section {
            margin-bottom: 20px;
        }
        .data-section h2 {
            color: #333;
            font-size: 18px;
            margin-top: 0;
            margin-bottom: 15px;
            border-bottom: 1px solid #eee;
            padding-bottom: 8px;
        }
        .data-table {
            width: 100%;
            border-collapse: collapse;
        }
        .data-table th, .data-table td {
            padding: 10px 15px;
            text-align: left;
            border-bottom: 1px solid #eee;
        }
        .data-table th {
            background-color: #f8f9fa;
            color: #555;
            font-weight: 600;
        }
        .footer {
            margin-top: 25px;
            text-align: center;
            color: #777;
            font-size: 14px;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>手机卡数据统计报告</h1>
        </div>
        
        <div class="status">
            最终存储的结果：成功保存 {{ 1 }} 条手机卡数据
        </div>
        
        <div class="data-section">
            <h2>各平台数据统计</h2>
            <table class="data-table">
                <tr>
                    <th>平台名称</th>
                    <th>数据条数</th>
                </tr>
                <tr>
                    <td>卡多多平台</td>
                    <td>{{ 1.all().length }}</td>
                </tr>
                <tr>
                    <td>172平台</td>
                    <td>{{ 1.all().length }}</td>
                </tr>
                <tr>
                    <td>阿喵平台</td>
                    <td>{{ 1.all().length }}</td>
                </tr>
                <tr>
                    <td>浩卡平台</td>
                    <td>{{ 1.all().length }}</td>
                </tr>
            </table>
        </div>
        
        <div class="footer">
            <p>此报告由系统自动生成</p>
        </div>
    </div>
</body>
</html>
```
    ''';

  int idx = 0;
  var response = "";

  Timer? _timer;
  int _counter = 0;

  @override
  void initState() {
    super.initState();
    // 创建每秒执行一次的定时器
    _timer = Timer.periodic(Duration(milliseconds: 100), (timer) {
      if (idx >= message.length) {
        _timer!.cancel();
        return;
      }
      setState(() {
        int sepautre = idx + 100 > message.length ? message.length - idx : 100;
        response += message.substring(idx, idx + sepautre).toString();
        idx += sepautre;
      });
    });
  }

  @override
  void dispose() {
    _chatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SizedBox(
          height: 600,
          child: SingleChildScrollView(
            child: GptMarkdown(
              response,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ),
      ),
    );
  }
}
