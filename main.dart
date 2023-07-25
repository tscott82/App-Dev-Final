import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'login.dart';
import 'register.dart';
import 'profile.dart';

class MainPage extends StatefulWidget {
  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  final TextEditingController _postController = TextEditingController();
  final TextEditingController _replyController = TextEditingController();

  int _currentIndex = 0;

  Stream<QuerySnapshot> _getRepliesForPost(String postId) {
    return FirebaseFirestore.instance
        .collection('replies')
        .where('postId', isEqualTo: postId)
        .snapshots();
  }

  Future<void> _createPost() async {
    String content = _postController.text.trim();
    String? userId = FirebaseAuth.instance.currentUser?.uid;
    String username = FirebaseAuth.instance.currentUser?.displayName ?? "Unknown User";

    if (content.isNotEmpty && userId != null) {
      await FirebaseFirestore.instance.collection('posts').add({
        'userId': userId,
        'username': username,
        'content': content,
        'timestamp': FieldValue.serverTimestamp(),
      });
      _postController.clear();
    }
  }

  Future<void> _createReply(String postId) async {
    String content = _replyController.text.trim();
    String? userId = FirebaseAuth.instance.currentUser?.uid;
    String username =
        FirebaseAuth.instance.currentUser?.displayName ?? "Unknown User";

    if (content.isNotEmpty && userId != null) {
      await FirebaseFirestore.instance.collection('replies').add({
        'postId': postId,
        'userId': userId,
        'username': username,
        'content': content,
        'timestamp': FieldValue.serverTimestamp(),
      });
      _replyController.clear();
      Navigator.pop(context); // Close the reply dialog
    }
  }

  bool _canEdit(String ownerId) {
    String? currentUserId = FirebaseAuth.instance.currentUser?.uid;
    return currentUserId == ownerId;
  }

  Future<void> _editPost(String postId, String editedContent) async {
    await FirebaseFirestore.instance.collection('posts').doc(postId).update({
      'content': editedContent,
    });
  }

  Future<void> _deletePost(String postId) async {
    await FirebaseFirestore.instance.collection('posts').doc(postId).delete();
  }

  Future<void> _showEditDialog(String postId, String currentContent) async {
    String editedContent = currentContent;

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Edit Post"),
          content: TextField(
            controller: TextEditingController(text: currentContent),
            onChanged: (value) {
              editedContent = value;
            },
            decoration: InputDecoration(hintText: "Edit your post"),
          ),
          actions: [
            TextButton(
              onPressed: () {
                if (editedContent.isNotEmpty) {
                  _editPost(postId, editedContent);
                  Navigator.pop(context);
                }
              },
              child: Text("Save"),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text("Cancel"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteReply(String postId, String replyId) async {
    await FirebaseFirestore.instance
        .collection('replies')
        .doc(replyId)
        .delete();
  }

  Widget _buildRepliesList(String postId) {
    return StreamBuilder<QuerySnapshot>(
      stream: _getRepliesForPost(postId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (!snapshot.hasData) {
          return SizedBox.shrink(); // No replies yet
        } else {
          final replies = snapshot.data!.docs;
          return ListView.builder(
            shrinkWrap: true,
            itemCount: replies.length,
            itemBuilder: (context, index) {
              final reply = replies[index];
              final replyId = reply.id;
              final replyUsername = reply['username'];
              final replyContent = reply['content'];
              return ListTile(
                title: Text(replyUsername),
                subtitle: Text(replyContent),
                trailing: _canEdit(reply['userId'])
                    ? IconButton(
                  onPressed: () => _deleteReply(postId, replyId),
                  icon: Icon(Icons.delete),
                )
                    : null,
              );
            },
          );
        }
      },
    );
  }

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blueAccent,
        title: Text("School Help App"),
        actions: [
          IconButton(
            onPressed: () {
              // Log out the user
              FirebaseAuth.instance.signOut();
              Navigator.pushReplacementNamed(context, '/login');
            },
            icon: Icon(Icons.logout),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('posts')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else if (!snapshot.hasData) {
                  return Center(child: Text("No posts available"));
                } else {
                  final posts = snapshot.data!.docs;
                  return ListView.builder(
                    itemCount: posts.length,
                    itemBuilder: (context, index) {
                      final post = posts[index];
                      final postId = post.id;
                      final username = post['username'];
                      final content = post['content'];
                      final ownerId = post['userId'];

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ListTile(
                            title: Text(username),
                            subtitle: Text(content),
                            trailing: _canEdit(ownerId)
                                ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  onPressed: () =>
                                      _showEditDialog(postId, content),
                                  icon: Icon(Icons.edit),
                                ),
                                IconButton(
                                  onPressed: () => _deletePost(postId),
                                  icon: Icon(Icons.delete),
                                ),
                              ],
                            )
                                : IconButton(
                              onPressed: () => _showReplyDialog(postId),
                              icon: Icon(Icons.reply,
                                color: Colors.lightBlueAccent,
                              ),
                            ),
                          ),
                          // Display replies for this post as an ExpansionTile
                          Container(
                            color: Colors.lightBlueAccent,
                            child: ExpansionTile(
                              title: DefaultTextStyle(
                                style: TextStyle(color: Colors.white), // Set the text color of the title
                                child: Text('Replies'),
                              ),
                              children: [
                                _buildRepliesList(postId),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  );
                }
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.all(10.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _postController,
                    decoration: InputDecoration(
                      hintText: "What do you need help with?",
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _createPost,
                  icon: Icon(Icons.send),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
              context, MaterialPageRoute(builder: (context) => ProfilePage()));
        },
        child: Icon(Icons.person),
      ),
    );
  }

  Future<void> _showReplyDialog(String postId) async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Reply to Post"),
          content: TextField(
            controller: _replyController,
            decoration: InputDecoration(hintText: "Enter your reply"),
          ),
          actions: [
            TextButton(
              onPressed: () {
                _createReply(postId);
              },
              child: Text("Reply"),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text("Cancel"),
            ),
          ],
        );
      },
    );
  }
}