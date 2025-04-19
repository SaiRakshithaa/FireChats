import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/html.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:convert';

import 'addmember.dart'; // Ensure this screen exists
import 'removemember.dart'; // Ensure this screen exists
import 'ChatScreenList.dart'; // Import SearchUsersScreen

class GroupChatScreen extends StatefulWidget {
  final String groupId;
  final String groupName;
  final List<String> memberIds;

  const GroupChatScreen({
    super.key,
    required this.groupId,
    required this.groupName,
    required this.memberIds,
  });

  @override
  State<GroupChatScreen> createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends State<GroupChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late WebSocketChannel _channel;
  String? currentUserId;
  Map<String, String> memberNames = {}; // userId: username

  @override
  void initState() {
    super.initState();
    currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId != null) {
      _connectWebSocket();
    }
    fetchMemberNames();
  }

  Future<void> fetchMemberNames() async {
    Map<String, String> names = {};
    for (String userId in widget.memberIds) {
      var doc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
      if (doc.exists) {
        names[userId] = doc['username'];
      }
    }
    setState(() {
      memberNames = names;
    });
  }

  void _connectWebSocket() {
    String url = "ws://192.168.75.1:12345/ws/$currentUserId";
    _channel = kIsWeb
        ? HtmlWebSocketChannel.connect(url)
        : IOWebSocketChannel.connect(url);

    _channel.stream.listen(
      (message) {
        _handleIncomingMessage(message);
      },
      onError: (error) {
        print("WebSocket error: $error");
      },
      onDone: () {
        _connectWebSocket();
      },
    );
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;

    String messageText = _messageController.text.trim();
    Timestamp timestamp = Timestamp.now();

    Map<String, dynamic> messageData = {
      "groupId": widget.groupId,
      "senderId": currentUserId,
      "receiverIds": widget.memberIds,
      "message": messageText,
      "timestamp": timestamp,
      "seen": false,
    };

    FirebaseFirestore.instance
        .collection('groups')
        .doc(widget.groupId)
        .collection('messages')
        .add(messageData);

    _channel.sink.add(jsonEncode({
      "groupId": widget.groupId,
      "senderId": currentUserId,
      "receiverIds": widget.memberIds,
      "message": messageText,
      "timestamp": timestamp.millisecondsSinceEpoch,
    }));

    _messageController.clear();
    _scrollToBottom();
  }

  void _handleIncomingMessage(String message) {
    var decodedMessage = jsonDecode(message);

    if (decodedMessage["groupId"] != widget.groupId) return;

    if (decodedMessage["timestamp"] is int) {
      decodedMessage["timestamp"] =
          Timestamp.fromMillisecondsSinceEpoch(decodedMessage["timestamp"]);
    }

    FirebaseFirestore.instance
        .collection('groups')
        .doc(widget.groupId)
        .collection('messages')
        .where("timestamp", isEqualTo: decodedMessage["timestamp"])
        .get()
        .then((snapshot) {
      if (snapshot.docs.isEmpty) {
        FirebaseFirestore.instance
            .collection('groups')
            .doc(widget.groupId)
            .collection('messages')
            .add(decodedMessage);
      }
    });

    setState(() {});
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

  void _showGroupInfoBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Wrap(
              children: [
                Center(
                  child: Container(
                    height: 5,
                    width: 50,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const Text("Participants", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                ...memberNames.entries.map((entry) => ListTile(
                      leading: const Icon(Icons.person),
                      title: Text(entry.value),
                    )),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.person_add),
                  title: const Text("Add Member"),
                  onTap: () async {
                    Navigator.pop(context);
                    final updatedMembers = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AddMembersScreen(
                          groupId: widget.groupId,
                          groupName: widget.groupName,
                          currentMembers: widget.memberIds,
                        ),
                      ),
                    );

                    if (updatedMembers != null) {
                      setState(() {
                        widget.memberIds.clear();
                        widget.memberIds.addAll(List<String>.from(updatedMembers));
                      });
                      await fetchMemberNames();
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.person_remove),
                  title: const Text("Remove Member"),
                  onTap: () async {
                    Navigator.pop(context);
                    final updatedMembers = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => RemoveMembersScreen(
                          groupId: widget.groupId,
                          groupName: widget.groupName,
                          currentMembers: widget.memberIds,
                        ),
                      ),
                    );

                    if (updatedMembers != null) {
                      setState(() {
                        widget.memberIds.clear();
                        widget.memberIds.addAll(List<String>.from(updatedMembers));
                      });
                      await fetchMemberNames();
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.exit_to_app),
                  title: const Text("Exit Group"),
                  onTap: () {
                    Navigator.pop(context);
                    _exitGroup();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _exitGroup() async {
    await FirebaseFirestore.instance.collection('groups').doc(widget.groupId).update({
      'members': FieldValue.arrayRemove([currentUserId])
    });

    if (!mounted) return;
    Navigator.pop(context); // Pop the group chat screen

    // Navigate to SearchUsersScreen after exiting the group
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const SearchUsersScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF075E54),
        title: GestureDetector(
          onTap: _showGroupInfoBottomSheet,
          child: Text(widget.groupName, style: const TextStyle(color: Colors.white)),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('groups')
                  .doc(widget.groupId)
                  .collection('messages')
                  .orderBy('timestamp', descending: false)
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

  Widget _buildMessageBubble(String message, bool isMe, DateTime timestamp) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              backgroundColor: Colors.blue,
              child: Text(
                memberNames[currentUserId]?[0].toUpperCase() ?? "",
                style: const TextStyle(color: Colors.white),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isMe ? Colors.green : Colors.grey[300],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment:
                  isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Text(
                  message,
                  style: TextStyle(color: isMe ? Colors.white : Colors.black),
                ),
                const SizedBox(height: 4),
                Text(
                  "${timestamp.hour}:${timestamp.minute}",
                  style: TextStyle(
                    color: isMe ? Colors.white : Colors.black.withOpacity(0.6),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageComposer() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: const InputDecoration(
                hintText: 'Type a message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(20)),
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: _sendMessage,
          ),
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


