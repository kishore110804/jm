// Displays and manages user's friends and social connections
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FriendsManager extends StatefulWidget {
  @override
  _FriendsManagerState createState() => _FriendsManagerState();
}

class _FriendsManagerState extends State<FriendsManager> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  late User? _currentUser;
  late Stream<QuerySnapshot> _friendsStream;

  @override
  void initState() {
    super.initState();
    _currentUser = _auth.currentUser;
    if (_currentUser != null) {
      _friendsStream = _firestore
          .collection('users')
          .doc(_currentUser!.uid)
          .collection('friends')
          .snapshots();
    }
  }

  Future<void> addFriend(String friendEmail) async {
    try {
      final friendQuery = await _firestore
          .collection('users')
          .where('email', isEqualTo: friendEmail)
          .get();

      if (friendQuery.docs.isNotEmpty) {
        final friendDoc = friendQuery.docs.first;
        await _firestore
            .collection('users')
            .doc(_currentUser!.uid)
            .collection('friends')
            .doc(friendDoc.id)
            .set({'email': friendEmail});
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Friend added successfully')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No user found with this email')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add friend: $e')),
      );
    }
  }

  Future<void> removeFriend(String friendId) async {
    try {
      await _firestore
          .collection('users')
          .doc(_currentUser!.uid)
          .collection('friends')
          .doc(friendId)
          .delete();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Friend removed successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to remove friend: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null) {
      return Center(child: Text('Please sign in to manage friends'));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Friends Manager'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _friendsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No friends found'));
          }

          final friends = snapshot.data!.docs;

          return ListView.builder(
            itemCount: friends.length,
            itemBuilder: (context, index) {
              final friend = friends[index];
              return ListTile(
                title: Text(friend['email']),
                trailing: IconButton(
                  icon: Icon(Icons.delete),
                  onPressed: () => removeFriend(friend.id),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final friendEmail = await showDialog<String>(
            context: context,
            builder: (context) {
              String email = '';
              return AlertDialog(
                title: Text('Add Friend'),
                content: TextField(
                  onChanged: (value) => email = value,
                  decoration: InputDecoration(hintText: 'Enter email'),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(email),
                    child: Text('Add'),
                  ),
                ],
              );
            },
          );

          if (friendEmail != null && friendEmail.isNotEmpty) {
            addFriend(friendEmail);
          }
        },
        child: Icon(Icons.add),
      ),
    );
  }
}