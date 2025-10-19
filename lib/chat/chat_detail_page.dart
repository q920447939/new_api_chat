import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_base/ui/components/gap/gap_width.dart';
import 'package:flutter_application_base/ui/components/smart_dialog/smart_dialog_helper.dart';
import 'package:gpt_markdown/gpt_markdown.dart';
import 'package:new_api_chat/entity/chat_obj.dart'; //聊天消息实体类
import 'package:tdesign_flutter/tdesign_flutter.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
class ChatDetailPage extends StatefulWidget {
  const ChatDetailPage({super.key});

  @override
  State<ChatDetailPage> createState() => _ChatDetailPageState();
}

class _ChatDetailPageState extends State<ChatDetailPage> {

  //模拟一些聊天对象
  List<ChatMessage> chatMessageList = [];
  List<ChatMessage> generatorChatMessageMockData() {
    return List.of([
      ChatMessage(id: 1, messageId: '1', messageTime: DateTime.now(), chatType: ChatType.system, messageType: MessageType.markdown, content: '你好，有什么可以帮你的吗？'),
      ChatMessage(id: 2, messageId: '2', messageTime: DateTime.now(), chatType: ChatType.user, messageType: MessageType.markdown, content: '推荐几首他比较好听的R&B'),
      ChatMessage(id: 3, messageId: '3', messageTime: DateTime.now(), chatType: ChatType.system, messageType: MessageType.markdown, content: '想逛逛故宫和长城，求路线推荐'),
      ChatMessage(id: 4, messageId: '4', messageTime: DateTime.now(), chatType: ChatType.user, messageType: MessageType.markdown, content: '要七言绝句，意境优美'),
      ChatMessage(id: 5, messageId: '5', messageTime: DateTime.now(), chatType: ChatType.system, messageType: MessageType.markdown, content: '用通俗易懂的话解释一下'),
    ]);
  }

  TextEditingController controller = TextEditingController(); 

  @override
  void initState() {
    super.initState();
    chatMessageList = generatorChatMessageMockData();
  }

  @override
  void dispose() {
    super.dispose();
    chatMessageList.clear();
    controller.dispose(); 
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey[100],
      child: Column(
        children: [
          _rightMultiAction(context),
          TDDivider(),
          _loadHistoryChat(chatMessageList),
          Spacer(),

          Container(
            padding: EdgeInsetsGeometry.symmetric(vertical: 10),
            margin: EdgeInsets.symmetric(vertical: 10,),
            child: _loadChatOperator(),
          )
        ],
      ),
    );
  }

  Widget _rightMultiAction(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 5),
      child: TDNavBar(
        height: 40,
        title: '找一首方大同的歌曲',
        titleFontWeight: FontWeight.w600,
        screenAdaptation: false,
        useDefaultBack: false,
        backgroundColor: Colors.grey[100],
        rightBarItems: [TDNavBarItem(icon: TDIcons.ellipsis, iconSize: 24)],
      ),
    );
  }

  _loadHistoryChat(List<ChatMessage>  chatMessageList) {
    return Container(
      height: 745.h,
      padding: EdgeInsets.all(5.r),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(10.r),),
        color: Colors.white,
      ),
      child: chatMessageList.isEmpty ? showNoMessage() : _buildChatList(chatMessageList),
    );
  }

  Widget showNoMessage(){
    return Container();
  }

  _loadChatOperator() {
    //在聊天框右上角增加一个按钮，点击后清空聊天框
    return Row(
      children: [
        Container(
          width: 380.w,
          child: TDInput(
          controller: controller,
          backgroundColor: Colors.white,
          hintText: '你想问什么？',
          onChanged: (text) {
            setState(() {});
          },
          onClearTap: () {
            controller.clear();
            setState(() {});
          },
        ),
        ),
        gapWidthNormal(),
        Icon(TDIcons.send, color: Colors.blue, size: 24.r,)
      ],
    );
  }
  
  _buildChatList(List<ChatMessage> chatMessageList) {
    return ListView.builder(
      itemBuilder: (context, index) {
        //如果是系统消息，那么背景颜色为灰色，如果是用户消息，那么背景颜色为蓝色
        ChatMessage chatMessage = chatMessageList[index];
        Color backgroundColor = chatMessage.chatType == ChatType.system ? Colors.grey[100]! : Colors.blue[100]!;
        return Container(
          padding: EdgeInsets.all(10.r),
          margin: EdgeInsets.symmetric(vertical: 5.r), 
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.all(Radius.circular(10.r),),
          ),
          child: Column(
            children: [
              //系统消息文字靠左，用户消息文字靠右
              chatMessage.chatType == ChatType.system ?
              Align(
                alignment: Alignment.centerLeft,
                child: GptMarkdown(
                  chatMessage.content,
                ),
              ) :
              Align(
                alignment: Alignment.centerRight,
                child: GptMarkdown(
                  chatMessage.content,
                ),
              ),
              TDDivider(),
              Row(
                mainAxisAlignment: chatMessage.chatType == ChatType.system ? MainAxisAlignment.start : MainAxisAlignment.end,
                children: [
                  IconButton(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: chatMessage.content));
                      dialogSuccess('复制成功');
                    },
                    icon: Icon(TDIcons.copy, color: Colors.blue,size: 18.r,),
                  ),
                  IconButton(
                    onPressed: () {
                      chatMessageList.removeAt(index);
                    },
                    icon: Icon(TDIcons.delete, color: Colors.red,size: 18.r,), 
                  ),
                ],
              )
            ],
          ),
        );
      },
    );
  }
}
