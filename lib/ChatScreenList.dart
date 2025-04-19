import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'ChatScreen.dart';
import 'group_chat_screen.dart';
import 'CreateGroupScreen.dart';

class SearchUsersScreen extends StatefulWidget {
  const SearchUsersScreen({super.key});

  @override
  State<SearchUsersScreen> createState() => _SearchUsersScreenState();
}

class _SearchUsersScreenState extends State<SearchUsersScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  List<Map<String, dynamic>> _searchResults = [];
  List<Map<String, dynamic>> _chatUsers = [];
  List<Map<String, dynamic>> _groupChats = [];

  String? currentUserId;

  @override
  void initState() {
    super.initState();
    getCurrentUser();
  }

  void getCurrentUser() {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      currentUserId = user.uid;
      fetchChatUsers();
      fetchGroupChats();
    }
  }

  Future<void> fetchChatUsers() async {
    if (currentUserId == null) return;

    FirebaseFirestore firestore = FirebaseFirestore.instance;
    QuerySnapshot chatSnapshot = await firestore
        .collection('chats')
        .where('participants', arrayContains: currentUserId)
        .get();

    Set<String> userIds = {};
    for (var doc in chatSnapshot.docs) {
      List<dynamic> participants = doc['participants'];
      for (var id in participants) {
        if (id != currentUserId) {
          userIds.add(id);
        }
      }
    }

    List<Map<String, dynamic>> chatUsers = [];
    for (String userId in userIds) {
      DocumentSnapshot userDoc =
          await firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        var data = userDoc.data() as Map<String, dynamic>;
        chatUsers.add({
          "username": data["username"] ?? "Unknown",
          "email": data["email"] ?? "No email",
          "uid": data["uid"] ?? "",
          "profilePic": data["profilePic"] ?? "",
        });
      }
    }

    setState(() {
      _chatUsers = chatUsers;
    });
  }

  Future<void> fetchGroupChats() async {
    if (currentUserId == null) return;

    FirebaseFirestore firestore = FirebaseFirestore.instance;
    QuerySnapshot groupSnapshot = await firestore
        .collection('groups')
        .where('members', arrayContains: currentUserId)
        .get();

    List<Map<String, dynamic>> groups = groupSnapshot.docs.map((doc) {
      var data = doc.data() as Map<String, dynamic>;
      return {
        "groupId": doc.id,
        "name": data["name"] ?? "Unnamed Group",
        "members": List<String>.from(data["members"] ?? []),
      };
    }).toList();

    setState(() {
      _groupChats = groups;
    });
  }

  void searchUsers(String query) async {
    query = query.trim().toLowerCase();
    if (query.isEmpty) {
      setState(() => _searchResults.clear());
      return;
    }

    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('users')
        .where("username", isGreaterThanOrEqualTo: query)
        .where("username", isLessThanOrEqualTo: query + '\uf8ff')
        .get();

    List<Map<String, dynamic>> results =
        querySnapshot.docs.where((doc) => doc.id != currentUserId).map((doc) {
      var data = doc.data() as Map<String, dynamic>;
      return {
        "username": data["username"] ?? "Unknown",
        "email": data["email"] ?? "No email",
        "uid": data["uid"] ?? "",
        "profilePic": data["profilePic"] ?? "",
      };
    }).toList();

    setState(() {
      _searchResults = results;
    });
  }

  String getChatId(String uid1, String uid2) {
    return uid1.hashCode <= uid2.hashCode ? '$uid1\$uid2' : '$uid2\$uid1';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF075E54),
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: "Search users...",
                  hintStyle: TextStyle(color: Colors.white70),
                  border: InputBorder.none,
                ),
                onChanged: searchUsers,
              )
            : const Text('Fire Chat', style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search,
                color: Colors.white),
            onPressed: () {
              setState(() {
                if (_isSearching) {
                  _searchController.clear();
                  _searchResults.clear();
                }
                _isSearching = !_isSearching;
              });
            },
          ),
          IconButton(
            icon: const Text(
              '+',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28, // You can adjust the size as needed
                fontWeight: FontWeight.bold,
              ),
            ),
            tooltip: "Create Group",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CreateGroupScreen()),
              );
            },
          ),
        ],
      ),
      body: _isSearching ? _buildUserList(_searchResults) : _buildChatList(),
    );
  }

  Widget _buildChatList() {
    return ListView(
      children: [
        if (_groupChats.isNotEmpty)
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text("Groups",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
        ..._groupChats.map((group) => ListTile(
              leading: const CircleAvatar(
                child: Icon(Icons.group),
              ),
              title: Text(group["name"]),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => GroupChatScreen(
                      groupId: group["groupId"],
                      groupName: group["name"],
                      memberIds: group["members"],
                    ),
                  ),
                );
              },
            )),
        const Divider(),
        if (_chatUsers.isNotEmpty)
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text("Chats",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
        ..._chatUsers.map((user) => ListTile(
              leading: CircleAvatar(
                backgroundImage: user["profilePic"].isNotEmpty
                    ? NetworkImage(user["profilePic"])
                    : const AssetImage("assets/default_profile.png")
                        as ImageProvider,
              ),
              title: Text(user["username"]),
              subtitle: Text(user["email"]),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChatScreen(
                      userName: user["username"],
                      userId: user["uid"],
                      profilePic: user["profilePic"],
                    ),
                  ),
                );
              },
            )),
      ],
    );
  }

  Widget _buildUserList(List<Map<String, dynamic>> users) {
    return users.isEmpty
        ? const Center(child: Text("No users found"))
        : ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              var user = users[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: user["profilePic"].isNotEmpty
                      ? NetworkImage(user["profilePic"])
                      : const AssetImage("assets/default_profile.png")
                          as ImageProvider,
                ),
                title: Text(user["username"]),
                subtitle: Text(user["email"]),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatScreen(
                        userName: user["username"],
                        userId: user["uid"],
                        profilePic: user["profilePic"],
                      ),
                    ),
                  );
                },
              );
            },
          );
  }
}
