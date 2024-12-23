import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'receipt.dart';

class ChatRoomListPage extends StatefulWidget {
  @override
  _ChatRoomListPageState createState() => _ChatRoomListPageState();
}

class _ChatRoomListPageState extends State<ChatRoomListPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 채팅방 생성 함수
  Future<void> createNewChatRoom(String roomName) async {
    try {
      final newRoom = {
        'name': roomName, // 채팅방 이름
        'createdAt': FieldValue.serverTimestamp(), // 생성 시간
      };
      final newRoomRef = await _firestore.collection('chatRooms').add(newRoom);

      // 생성된 채팅방으로 이동
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatRoomPage(roomId: newRoomRef.id),
        ),
      );
    } catch (e) {
      print('채팅방 생성 오류: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('채팅방 목록')),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('chatRooms')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }

                final chatRooms = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: chatRooms.length,
                  itemBuilder: (context, index) {
                    final room = chatRooms[index].data() as Map<String, dynamic>;
                    final roomId = chatRooms[index].id;
                    final roomName = room['name'] ?? '이름 없음';

                    return ListTile(
                      title: Text(roomName),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChatRoomPage(roomId: roomId),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: TextEditingController(),
                    decoration: InputDecoration(
                      hintText: '새 채팅방 이름 입력',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (value) {
                      if (value.trim().isNotEmpty) {
                        createNewChatRoom(value.trim());
                      }
                    },
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.add),
                  onPressed: () {
                    final roomNameController = TextEditingController();
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: Text('채팅방 생성'),
                          content: TextField(
                            controller: roomNameController,
                            decoration: InputDecoration(hintText: '채팅방 이름 입력'),
                          ),
                          actions: [
                            TextButton(
                              child: Text('취소'),
                              onPressed: () => Navigator.pop(context),
                            ),
                            TextButton(
                              child: Text('확인'),
                              onPressed: () {
                                final roomName = roomNameController.text.trim();
                                if (roomName.isNotEmpty) {
                                  createNewChatRoom(roomName);
                                  Navigator.pop(context);
                                }
                              },
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ChatRoomPage extends StatefulWidget {
  final String roomId; // 채팅방 ID

  ChatRoomPage({required this.roomId});

  @override
  _ChatRoomPageState createState() => _ChatRoomPageState();
}

class _ChatRoomPageState extends State<ChatRoomPage> {
  final TextEditingController _messageController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ScrollController _scrollController = ScrollController(); // 화면 맨 아래로 내려줌


  String? nickname;

  String appBarTitle = ''; // AppBar 제목 초기화
  String? lastSender;


  @override
  void initState() {
    super.initState();
    initializeChatRoom(); // 초기화 함수 호출
  }

  // 초기화 함수
  Future<void> initializeChatRoom() async {
    await fetchUserNickname();
    await fetchChatRoomDetails();
    setState(() {}); // 초기화 후 상태 업데이트
  }

  // 닉네임 가져오기
  Future<void> fetchUserNickname() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final userDoc = await _firestore.collection('user').doc(uid).get();
    nickname = userDoc.data()?['name'] ?? '익명';
  }

  // 채팅방 세부 정보 가져오기
  Future<void> fetchChatRoomDetails() async {
    final roomDoc = await _firestore.collection('bread').doc(widget.roomId).get();
    if (roomDoc.exists) {
      final data = roomDoc.data();
      final category = data?['category'];
      final roomData = data?['data'];

      switch (category) {
        case "택시팟빵":
          appBarTitle = roomData?['목적지'] ?? "알 수 없는 목적지";
          break;
        case "배달팟빵":
          appBarTitle = roomData?['음식 이름'] ?? "알 수 없는 음식 이름";
          break;
        case "공구팟빵":
          appBarTitle = roomData?['제품명'] ?? "알 수 없는 제품명";
          break;
        case "기타팟빵":
          appBarTitle = roomData?['이름'] ?? "알 수 없는 이름";
          break;
        default:
          appBarTitle = "알 수 없는 채팅방";
      }
    } else {
      appBarTitle = "채팅방 정보 없음";
    }
  }

  // 메시지 전송 함수
  Future<void> sendMessage() async {
    if (_messageController.text.trim().isEmpty || nickname == null) return;

    final message = {
      'nickname': nickname,
      'message': _messageController.text.trim(),
      'timestamp': FieldValue.serverTimestamp(),
    };

    await _firestore
        .collection('chatRooms')
        .doc(widget.roomId)
        .collection('messages')
        .add(message);

    _messageController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(appBarTitle), // 즉시 표시되는 제목
      ),
      body: Column(
        children: [
          // 실시간 메시지 스트림
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('chatRooms')
                  .doc(widget.roomId)
                  .collection('messages')
                  .orderBy('timestamp', descending: false)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }

                final messages = snapshot.data!.docs;

                // 메세지 새로 로드될 때마다 화면을 아래로 내려줘요
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _scrollController.animateTo(
                    _scrollController.position.maxScrollExtent,
                    duration: Duration(milliseconds: 300),
                    curve: Curves.easeOut,
                  );
                });

                return ListView.builder(
                  controller: _scrollController,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message =
                        messages[index].data() as Map<String, dynamic>;
                    final uid = message['uid'];
                    final imageUrl = message['imageUrl'];
                    final sender = message['nickname'] ?? '익명';
                    final text = message['message'] ?? '';
                    final timestamp = message['timestamp'] != null
                        ? (message['timestamp'] as Timestamp).toDate()
                        : DateTime.now();

                    // 내가 보낸 메세지인지 확인하기
                    // final isMe = uid == _auth.currentUser?.uid;
                    final bool isMe = sender == nickname;

                    // 같은 사람이 연속으로 보내는지 확인
                    final bool showSenderName = sender != lastSender;

                    // 마지막으로 보낸 사람 저장
                    lastSender = sender;

                    // return ListTile(
                    //   title: Text(sender, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),),
                    //   subtitle: Text(text),
                    //   trailing: Text(
                    //     '${timestamp.hour}:${timestamp.minute}',
                    //     style: TextStyle(fontSize: 12, color: Colors.grey),
                    //   ),
                    // );
                    return Column(
                      crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                      children: [
                        if (showSenderName)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(15, 23, 0, 10),
                            // padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 10.0),
                            child: Text(
                              isMe ? "" : sender,
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        Row(
                          mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                          children: [
                            if (isMe) // 내 메세지 - 메세지 전송 시간을 오른쪽에
                              Padding(
                                padding: const EdgeInsets.fromLTRB(0, 30, 0, 0),
                                // padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                child: Text(
                                  '${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}',
                                  style: TextStyle(fontSize: 12, color: Colors.black),
                                ),
                              ),
                            Container(
                              padding: const EdgeInsets.fromLTRB(18, 10, 18, 10),
                              margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                              // padding: EdgeInsets.all(12),
                              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
                              decoration: BoxDecoration(
                                color: isMe ? Color(0xFF574142) : Colors.grey[300],
                                borderRadius: BorderRadius.circular(300),
                              ),
                              child: Text(
                                text,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: isMe ? Colors.white : Color(0xFF574142),
                                ),
                              ),
                            ),
                            if (!isMe) // 다른 사람 메세지 - 시간을 왼쪽에
                              Padding(
                                padding: const EdgeInsets.fromLTRB(0, 30, 0, 0),
                                // padding: const EdgeInsets.symmetric(horizontal: 5.0),
                                child: Text(
                                  '${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}',
                                  style: TextStyle(fontSize: 12, color: Color(0xFF574142)),
                                ),
                              ),
                          ],
                        ),
                        if (imageUrl != null)
                          Image.network(
                            imageUrl,
                            width: 300,
                            fit: BoxFit.cover, // 또는 BoxFit.contain
                          ),
                      ],
                    );

                  },
                );
              },
            ),
          ),
          // 메시지 입력창
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.money),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => Receipt(roomId: widget.roomId),
                      ),
                    );
                  },
                  // => Navigator.of(context).pushNamed('/receipt'),
                      // .pushReplacementNamed('/receipt'),
                ),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: '메시지를 입력하세요',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
