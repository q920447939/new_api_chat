import 'package:flutter/material.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';

class ChatIndexPage extends StatefulWidget {
  const ChatIndexPage({super.key});

  @override
  State<ChatIndexPage> createState() => _ChatIndexPageState();
}

class _ChatIndexPageState extends State<ChatIndexPage> {
  Map<String, bool> select_status_map = {"1": true};

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey[100],
      child: Column(
        children: [
          _rightMultiAction(context),
          _buildNewChat(),
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
          TDNavBarItem(icon: TDIcons.home, iconSize: 24),
          TDNavBarItem(icon: TDIcons.ellipsis, iconSize: 24),
        ],
      ),
    );
  }

  _buildNewChat() {
    return _buildCard();
  }

  _buildCard() {
    return GestureDetector(
      onLongPress: () {},
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 5, vertical: 2),
        height: 50,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(10)),
          color: Colors.white,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [_buildSelect("1"), _buildImageAvatar(context)],
        ),
      ),
    );
  }

  Widget _buildSelect(String id) {
    bool isSelect = select_status_map[id]!;
    if (isSelect) {}
    return SizedBox(
      height: 40,
      width: 60,
      child: _horizontalRadios(context, id),
    );
  }

  Widget _buildImageAvatar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        children: const [
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
                  '111',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                TDText('豆包', style: TextStyle(fontSize: 14)),
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
