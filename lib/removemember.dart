import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RemoveMembersScreen extends StatefulWidget {
  final String groupId;
  final String groupName;
  final List<String> currentMembers;

  const RemoveMembersScreen({
    super.key,
    required this.groupId,
    required this.groupName,
    required this.currentMembers,
  });

  @override
  State<RemoveMembersScreen> createState() => _RemoveMembersScreenState();
}

class _RemoveMembersScreenState extends State<RemoveMembersScreen> {
  List<String> selectedMembers = [];

  @override
  void initState() {
    super.initState();
    selectedMembers = List<String>.from(widget.currentMembers); // preselect all members
  }

  void _toggleMember(String userId) {
    setState(() {
      if (selectedMembers.contains(userId)) {
        selectedMembers.remove(userId);
      } else {
        selectedMembers.add(userId);
      }
    });
  }

  void _updateGroupMembers() async {
    await FirebaseFirestore.instance.collection('groups').doc(widget.groupId).update({
      'members': selectedMembers,
    });

    Navigator.pop(context, selectedMembers); // Return updated list to parent screen
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Remove Members from ${widget.groupName}",style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF075E54),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _updateGroupMembers,
          )
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final users = snapshot.data!.docs;

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              var user = users[index];
              String userId = user.id;
              String username = user['username'];

              bool isChecked = selectedMembers.contains(userId);
              bool isInGroup = widget.currentMembers.contains(userId);

              // Only show users who are in the current group
              if (!isInGroup) return const SizedBox.shrink();

              return CheckboxListTile(
                value: isChecked,
                onChanged: (bool? checked) {
                  _toggleMember(userId);
                },
                title: Text(username),
              );
            },
          );
        },
      ),
    );
  }
}
