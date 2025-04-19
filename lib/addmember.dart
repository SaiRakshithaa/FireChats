import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddMembersScreen extends StatefulWidget {
  final String groupId;
  final String groupName;
  final List<String> currentMembers;

  const AddMembersScreen({
    super.key,
    required this.groupId,
    required this.groupName,
    required this.currentMembers,
  });

  @override
  State<AddMembersScreen> createState() => _AddMembersScreenState();
}

class _AddMembersScreenState extends State<AddMembersScreen> {
  Map<String, String> allUsers = {}; // userId: username
  Set<String> selectedUserIds = {};

  @override
  void initState() {
    super.initState();
    selectedUserIds = widget.currentMembers.toSet(); // pre-select existing members
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

  void updateGroupMembers() async {
    await FirebaseFirestore.instance
        .collection('groups')
        .doc(widget.groupId)
        .update({"members": selectedUserIds.toList()});

    Navigator.pop(context, selectedUserIds.toList()); // return to previous screen
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add Members", style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF075E54),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextFormField(
              initialValue: widget.groupName,
              readOnly: true,
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
                bool isAlreadyMember = widget.currentMembers.contains(userId);

                return CheckboxListTile(
                  title: Text(username),
                  value: selectedUserIds.contains(userId),
                  onChanged: isAlreadyMember
                      ? null // Disable unselecting for current members
                      : (isSelected) {
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
              onPressed: updateGroupMembers,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF075E54),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text("Confirm", style: TextStyle(fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }
}
