import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/html.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:convert';

class ChatScreen extends StatefulWidget {
  final String userName;
  final String userId;
  final String profilePic;

  const ChatScreen({
    super.key,
    required this.userName,
    required this.userId,
    required this.profilePic,
  });

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late WebSocketChannel _channel;
  String? currentUserId;

  @override
  void initState() {
    super.initState();
    currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId != null) {
      _connectWebSocket();
    }
  }

  void _connectWebSocket() {
    String url = "ws://192.168.75.1:12345/ws/$currentUserId";

    _channel = kIsWeb
        ? HtmlWebSocketChannel.connect(url)
        : IOWebSocketChannel.connect(url);

    _channel.stream.listen(
      (message) {
        print("📥 Received message: $message");
        _handleIncomingMessage(message);
      },
      onError: (error) {
        print("❌ WebSocket error: $error");
      },
      onDone: () {
        print("⚠ WebSocket closed. Reconnecting...");
        _connectWebSocket();
      },
    );
  }

  String getChatId() {
    List<String> ids = [currentUserId!, widget.userId];
    ids.sort();
    return ids.join("_");
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;

    String messageText = _messageController.text.trim();
    String chatId = getChatId();
    Timestamp timestamp = Timestamp.now(); // ✅ Firestore Timestamp

    Map<String, dynamic> messageData = {
      "chatId": chatId,
      "senderId": currentUserId,
      "receiverId": widget.userId,
      "message": messageText,
      "timestamp": timestamp, // ✅ Firestore Timestamp
      "seen": false
    };

    FirebaseFirestore.instance
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .add(messageData)
        .then((_) {
      _messageController.clear();
      _scrollToBottom();
    });

    // ✅ Send timestamp as milliseconds for WebSocket
    _channel.sink.add(jsonEncode({
      "chatId": chatId,
      "senderId": currentUserId,
      "receiverId": widget.userId,
      "message": messageText,
      "timestamp": timestamp.millisecondsSinceEpoch, // ✅ WebSocket timestamp
      "seen": false
    }));
  }

  void _handleIncomingMessage(String message) {
    var decodedMessage = jsonDecode(message);

    // ✅ Convert WebSocket timestamp back to Firestore Timestamp
    if (decodedMessage["timestamp"] is int) {
      decodedMessage["timestamp"] =
          Timestamp.fromMillisecondsSinceEpoch(decodedMessage["timestamp"]);
    }

    // ✅ Store received message in Firestore if it doesn't exist
    String chatId = getChatId();
    FirebaseFirestore.instance
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .where("timestamp", isEqualTo: decodedMessage["timestamp"])
        .get()
        .then((snapshot) {
      if (snapshot.docs.isEmpty) {
        FirebaseFirestore.instance
            .collection('chats')
            .doc(chatId)
            .collection('messages')
            .add(decodedMessage);
      }
    });

    setState(() {}); // ✅ Refresh UI
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    String chatId = getChatId();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF075E54),
        title: Row(
          children: [
            CircleAvatar(
              backgroundImage: widget.profilePic.isNotEmpty
                  ? NetworkImage(widget.profilePic)
                  : const AssetImage("assets/background.png")
                      as ImageProvider, // ✅ Default image fallback
            ),
            const SizedBox(width: 10),
            Text(widget.userName),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .doc(chatId)
                  .collection('messages')
                  .orderBy('timestamp', descending: false) // ✅ Correct order
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("No messages yet."));
                }

                var messages = snapshot.data!.docs;

                return ListView.builder(
                  controller: _scrollController,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    var messageData = messages[index].data() as Map<String, dynamic>;

                    // ✅ Convert timestamp properly
                    var timestampData = messageData['timestamp'];
                    DateTime timestamp;
                    if (timestampData is Timestamp) {
                      timestamp = timestampData.toDate();
                    } else if (timestampData is int) {
                      timestamp = DateTime.fromMillisecondsSinceEpoch(timestampData);
                    } else {
                      timestamp = DateTime.now();
                    }

                    bool isMe = messageData['senderId'] == currentUserId;

                    return _buildMessageBubble(
                      messageData['message'],
                      isMe,
                      messageData['seen'],
                      timestamp,
                    );
                  },
                );
              },
            ),
          ),
          _buildMessageComposer(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(
      String message, bool isMe, bool seen, DateTime timestamp) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isMe ? const Color(0xFFDCF8C6) : Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  Text(message, style: const TextStyle(fontSize: 16)),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}",
                        style:
                            const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      if (isMe) const SizedBox(width: 5),
                      if (isMe)
                        Icon(Icons.done_all,
                            size: 18, color: seen ? Colors.blue : Colors.grey),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageComposer() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: const InputDecoration(
                  hintText: "Type a message", border: InputBorder.none),
            ),
          ),
          IconButton(
              icon: const Icon(Icons.send, color: Color(0xFF075E54)),
              onPressed: _sendMessage),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _channel.sink.close();
    super.dispose();
  }
}
