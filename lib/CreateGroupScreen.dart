import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'group_chat_screen.dart';

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final TextEditingController _groupNameController = TextEditingController();
  Map<String, String> allUsers = {}; // userId: username
  Set<String> selectedUserIds = {};

  @override
  void initState() {
    super.initState();
    fetchUsers();
  }

  Future<void> fetchUsers() async {
    final snapshot = await FirebaseFirestore.instance.collection('users').get();
    final Map<String, String> users = {};
    for (var doc in snapshot.docs) {
      users[doc.id] = doc['username'];
    }
    setState(() => allUsers = users);
  }

  void createGroup() async {
    final groupName = _groupNameController.text.trim();
    if (groupName.isEmpty || selectedUserIds.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter a name and select at least 2 users")),
      );
      return;
    }

    final groupDoc = await FirebaseFirestore.instance.collection("groups").add({
      "name": groupName,
      "members": selectedUserIds.toList(),
      "createdAt": FieldValue.serverTimestamp(),
    });

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => GroupChatScreen(
          groupId: groupDoc.id,
          groupName: groupName,
          memberIds: selectedUserIds.toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Create Group",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF075E54),
        iconTheme: const IconThemeData(color: Colors.white), // back arrow color
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _groupNameController,
              decoration: const InputDecoration(
                labelText: "Group Name",
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              children: allUsers.entries.map((entry) {
                final userId = entry.key;
                final username = entry.value;
                return CheckboxListTile(
                  title: Text(username),
                  value: selectedUserIds.contains(userId),
                  onChanged: (isSelected) {
                    setState(() {
                      isSelected!
                          ? selectedUserIds.add(userId)
                          : selectedUserIds.remove(userId);
                    });
                  },
                );
              }).toList(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: ElevatedButton(
              onPressed: createGroup,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF075E54), // green
                foregroundColor: Colors.white, // text color
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text(
                "Create Group",
                style: TextStyle(fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
