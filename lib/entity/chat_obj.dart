//
// 
/**
 * 聊天对象
 * 包含属性
 *    ID
 *    messageId
 *    消息时间
 *    聊天对象类型：分为系统对象和用户对象
 *    消息类型:markdown
 *    
 */


class ChatMessage {
  final int id;
  final String messageId;
  final DateTime messageTime;
  final ChatType chatType; 
  final MessageType messageType; 
  final String content;
  ChatMessage({required this.id, required this.messageId, required this.messageTime, required this.chatType, required this.messageType, required this.content});

}

enum ChatType {
  system,
  user,
}

enum MessageType {
  markdown,
  text,
}