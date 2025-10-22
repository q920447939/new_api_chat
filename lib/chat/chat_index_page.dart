import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:new_api_chat/entity/chat_info.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';

class ChatIndexPage extends StatefulWidget {
  const ChatIndexPage({super.key});

  @override
  State<ChatIndexPage> createState() => _ChatIndexPageState();
}

class _ChatIndexPageState extends State<ChatIndexPage> {
  Map<String, bool> select_status_map = {"1": true};

  List<ChatInfo> generatorChatInfoMockData() {
    return List.of([
      ChatInfo(id: 1, title: '豆包', desc: '你好，有什么可以帮你的吗？'),
      ChatInfo(id: 2, title: '找一首方大同的歌曲', desc: '推荐几首他比较好听的R&B'),
      ChatInfo(id: 3, title: '周末北京两日游攻略', desc: '想逛逛故宫和长城，求路线推荐'),
      ChatInfo(id: 4, title: '帮我写一首关于秋天的诗', desc: '要七言绝句，意境优美'),
      ChatInfo(id: 5, title: '什么是黑洞？', desc: '用通俗易懂的话解释一下'),
      ChatInfo(id: 6, title: '宫保鸡丁的做法', desc: '需要哪些材料，步骤是什么？'),
      ChatInfo(
        id: 7,
        title: 'Python代码报错，IndentationError',
        desc: '检查一下我的代码哪里缩进有问题',
      ),
      ChatInfo(id: 8, title: '推荐几本科幻小说', desc: '最近书荒了，最好是刘慈欣之外的'),
      ChatInfo(id: 9, title: '帮我想个社区咖啡馆的点子', desc: '希望能有特色，吸引年轻人'),
      ChatInfo(id: 10, title: '讲个笑话吧', desc: '来个冷笑话，让我清醒一下'),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey[100],
      child: Column(
        children: [
          _rightMultiAction(context),
          _buildTestEntry(context),
          _buildNewChat(),
        ],
      ),
    );
  }

  Widget _rightMultiAction(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 5),
      child: TDNavBar(
        height: 40,
        title: '对话',
        titleFontWeight: FontWeight.w600,
        screenAdaptation: false,
        useDefaultBack: false,
        backgroundColor: Colors.grey[100],
        rightBarItems: [
          TDNavBarItem(icon: TDIcons.search, iconSize: 24),
          TDNavBarItem(icon: TDIcons.ellipsis, iconSize: 24),
        ],
      ),
    );
  }

  _buildNewChat() {
    return SingleChildScrollView(
      child: Column(
        children: _buildNewChatItem(),
      ),
    );
  }

  Widget _buildTestEntry(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () => context.push('/chat_test'),
          icon: const Icon(Icons.play_circle_fill),
          label: const Text('聊天 API 模拟测试'),
        ),
      ),
    );
  }

  List<Widget> _buildNewChatItem() {
    final list = generatorChatInfoMockData();
    return list.map((e) => _buildCard(e)).toList();
  }



  Widget _buildCard(ChatInfo chatInfo) {
    return GestureDetector(
      onTap: () {
        context.push('/chat_detail');
      },
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 5, vertical: 2),
        padding: EdgeInsets.symmetric(vertical: 8),
        height: 70,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(10)),
          color: Colors.white,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [_buildSelect("1"), _buildImageAvatar(context,chatInfo)],
        ),
      ),
    );
  }

  Widget _buildSelect(String id) {
    bool isSelect = select_status_map[id]!;
    if (isSelect) {}
    return SizedBox(
      height: 50,
      width: 50,
      child: _horizontalRadios(context, id),
    );
  }

  Widget _buildImageAvatar(BuildContext context,ChatInfo chatInfo) {
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        children:  [
          TDAvatar(
            size: TDAvatarSize.medium,
            type: TDAvatarType.normal,
            defaultUrl: 'assets/img/td_avatar_1.png',
          ),
          Padding(
            padding: EdgeInsetsGeometry.only(left: 10),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TDText(
                  chatInfo.title,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                TDText(chatInfo.desc, style: TextStyle(fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _horizontalRadios(BuildContext context, String id) {
    return TDRadioGroup(
      selectId: 'index:1',
      direction: Axis.horizontal,
      directionalTdRadios: [
        TDRadio(
          id: id,
          title: '',
          radioStyle: TDRadioStyle.circle,
          showDivider: false,
        ),
      ],
    );
  }
}
