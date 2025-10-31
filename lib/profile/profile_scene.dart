import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:app_todo/models/user_model.dart';
import 'package:app_todo/profile/edit_profile_scene.dart';

class ProfileScene extends StatefulWidget {
  final User user;
  final bool isCurrentUser;

  const ProfileScene({
    super.key,
    required this.user,
    this.isCurrentUser = true,
  });

  @override
  _ProfileSceneState createState() => _ProfileSceneState();
}

class _ProfileSceneState extends State<ProfileScene> {
  late User _currentUser;
  final TextEditingController _friendIdController = TextEditingController();
  final List<String> _friendsList = []; // Список друзей (только ID)
  final List<String> _pendingRequests = []; // Входящие заявки
  final List<String> _outgoingRequests = []; // Исходящие заявки

  @override
  void initState() {
    super.initState();
    _currentUser = widget.user;
    // Инициализируем списки из данных пользователя
    _friendsList.addAll(_currentUser.friendsIds);
  }

  void _updateProfile(User updatedUser) {
    setState(() {
      _currentUser = updatedUser;
    });
  }

  void _navigateToEditProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditProfileScene(
          user: _currentUser,
          onProfileUpdated: _updateProfile,
        ),
      ),
    );
  }

  void _addFriend() {
    final friendId = _friendIdController.text.trim();
    if (friendId.isEmpty) return;

    // Проверяем, не добавлен ли уже этот друг
    if (!_friendsList.contains(friendId) && 
        !_outgoingRequests.contains(friendId) &&
        friendId != _currentUser.id) {
      
      setState(() {
        _outgoingRequests.add(friendId);
        _friendIdController.clear();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Заявка отправлена пользователю $friendId'),
          duration: Duration(seconds: 2),
        ),
      );
    } else if (friendId == _currentUser.id) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Нельзя добавить себя в друзья'),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.red,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Пользователь уже в списке друзей или заявок'),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  void _removeFriend(String friendId) {
    setState(() {
      _friendsList.remove(friendId);
      _pendingRequests.remove(friendId);
      _outgoingRequests.remove(friendId);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Пользователь удалён из списка'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _acceptFriendRequest(String friendId) {
    setState(() {
      _pendingRequests.remove(friendId);
      if (!_friendsList.contains(friendId)) {
        _friendsList.add(friendId);
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Заявка в друзья принята'),
        duration: Duration(seconds: 2),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _rejectFriendRequest(String friendId) {
    setState(() {
      _pendingRequests.remove(friendId);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Заявка в друзья отклонена'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _cancelOutgoingRequest(String friendId) {
    setState(() {
      _outgoingRequests.remove(friendId);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Заявка отменена'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showRemoveFriendDialog(String friendId, String friendName) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Удаление из друзей'),
          content:
              Text('Вы уверены, что хотите удалить "$friendName" из друзей?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Отмена'),
            ),
            TextButton(
              onPressed: () {
                _removeFriend(friendId);
                Navigator.pop(context);
              },
              child: Text('Удалить', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  void _showRejectRequestDialog(String friendId, String friendName) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Отклонение заявки'),
          content:
              Text('Вы уверены, что хотите отклонить заявку от "$friendName"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Отмена'),
            ),
            TextButton(
              onPressed: () {
                _rejectFriendRequest(friendId);
                Navigator.pop(context);
              },
              child: Text('Отклонить', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  void _showCancelRequestDialog(String friendId, String friendName) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Отмена заявки'),
          content:
              Text('Вы уверены, что хотите отменить заявку для "$friendName"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Отмена'),
            ),
            TextButton(
              onPressed: () {
                _cancelOutgoingRequest(friendId);
                Navigator.pop(context);
              },
              child: Text('Отменить', style: TextStyle(color: Colors.orange)),
            ),
          ],
        );
      },
    );
  }

  void _navigateToFriendProfile(String friendId) {
    // Создаем временного пользователя для просмотра профиля
    final friendUser = User(
      name: 'Друг $friendId',
      email: 'friend$friendId@example.com',
      id: friendId,
      friendsIds: [],
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfileScene(
          user: friendUser,
          isCurrentUser: false,
        ),
      ),
    );
  }

  void _goBack() {
    Navigator.pop(context);
  }

  void _copyIdToClipboard() {
    Clipboard.setData(ClipboardData(text: _currentUser.id));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('ID скопирован в буфер обмена'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  bool _isFriend(String friendId) {
    return _friendsList.contains(friendId);
  }

  bool _hasOutgoingRequest(String friendId) {
    return _outgoingRequests.contains(friendId);
  }

  bool _hasIncomingRequest(String friendId) {
    return _pendingRequests.contains(friendId);
  }

  // Метод для генерации имени друга на основе ID
  String _getFriendName(String friendId) {
    return 'Друг $friendId';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 254, 243, 243),
      appBar: !widget.isCurrentUser
          ? AppBar(
              leading: IconButton(
                icon: Icon(Icons.arrow_back, color: Colors.white),
                onPressed: _goBack,
              ),
              title: Text(
                'Профиль пользователя',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              centerTitle: true,
              backgroundColor: const Color.fromARGB(255, 10, 220, 181),
              elevation: 0,
              iconTheme: IconThemeData(color: Colors.white),
            )
          : null,
      body: SingleChildScrollView(
        child: Column(
          children: [
            if (widget.isCurrentUser) SizedBox(height: 20),
            // ID пользователя с возможностью копирования
            GestureDetector(
              onTap: _copyIdToClipboard,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.person_outline,
                        size: 16, color: Colors.grey[600]),
                    SizedBox(width: 4),
                    Text(
                      'ID: ${_currentUser.id}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(Icons.content_copy, size: 14, color: Colors.grey[500]),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),
            // Аватар и основная информация
            SizedBox(
              width: 100,
              height: 100,
              child: ClipOval(
                child: _currentUser.photoPath != null
                    ? Image.file(File(_currentUser.photoPath!))
                    : Image.asset('assets/images/test1.jpg'),
              ),
            ),
            SizedBox(height: 12),
            Text(
              _currentUser.name,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            // Кнопка редактирования/управления дружбой
            if (widget.isCurrentUser)
              Container(
                padding: EdgeInsets.all(16),
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _navigateToEditProfile,
                  style: ElevatedButton.styleFrom(
                    textStyle: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    backgroundColor: const Color.fromARGB(255, 23, 144, 126),
                    foregroundColor: Colors.white,
                    elevation: 10.0,
                    padding: EdgeInsets.all(20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text('Редактировать профиль'),
                ),
              )
            else
              Container(
                padding: EdgeInsets.all(16),
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (_isFriend(_currentUser.id)) {
                      _showRemoveFriendDialog(
                          _currentUser.id, _currentUser.name);
                    } else if (_hasOutgoingRequest(_currentUser.id)) {
                      _showCancelRequestDialog(
                          _currentUser.id, _currentUser.name);
                    } else if (_hasIncomingRequest(_currentUser.id)) {
                      // Показываем диалог для принятия/отклонения заявки
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: Text('Заявка в друзья'),
                            content: Text(
                                '${_currentUser.name} хочет добавить вас в друзья'),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  _showRejectRequestDialog(
                                      _currentUser.id, _currentUser.name);
                                },
                                child: Text('Отклонить',
                                    style: TextStyle(color: Colors.red)),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  _acceptFriendRequest(_currentUser.id);
                                },
                                child: Text('Принять',
                                    style: TextStyle(color: Colors.green)),
                              ),
                            ],
                          );
                        },
                      );
                    } else {
                      // Отправляем заявку в друзья
                      setState(() {
                        _outgoingRequests.add(_currentUser.id);
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Заявка отправлена'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    textStyle: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    backgroundColor: _isFriend(_currentUser.id)
                        ? Colors.red
                        : _hasOutgoingRequest(_currentUser.id)
                            ? Colors.orange
                            : _hasIncomingRequest(_currentUser.id)
                                ? Colors.blue
                                : const Color.fromARGB(255, 23, 144, 126),
                    foregroundColor: Colors.white,
                    elevation: 10.0,
                    padding: EdgeInsets.all(20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    _isFriend(_currentUser.id)
                        ? 'Удалить из друзей'
                        : _hasOutgoingRequest(_currentUser.id)
                            ? 'Отменить заявку'
                            : _hasIncomingRequest(_currentUser.id)
                                ? 'Ответить на заявку'
                                : 'Добавить в друзья',
                  ),
                ),
              ),
            // Контакты
            Container(
              margin: EdgeInsets.symmetric(horizontal: 16),
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        Icon(
                          Icons.email,
                          color: Colors.grey[500],
                        ),
                        SizedBox(width: 12),
                        _currentUser.hideEmail == true
                            ? Text(
                                'Email скрыт',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                  fontStyle: FontStyle.italic,
                                ),
                              )
                            : Text(
                                _currentUser.email,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Color.fromARGB(255, 16, 192, 169),
                                ),
                              ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),
            // Навыки
            Container(
              margin: EdgeInsets.symmetric(horizontal: 16),
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info,
                        color: Colors.grey[500],
                      ),
                      SizedBox(width: 12),
                      Text(
                        'Навыки',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _currentUser.skills
                        .map((skill) => Chip(
                              label: Text(skill),
                              backgroundColor:
                                  Color.fromARGB(255, 230, 245, 243),
                            ))
                        .toList(),
                  ),
                  if (_currentUser.skills.isEmpty)
                    Text(
                      'Навыки не добавлены',
                      style: TextStyle(
                          color: Colors.grey, fontStyle: FontStyle.italic),
                    ),
                ],
              ),
            ),
            SizedBox(height: 16),
            // О себе
            Container(
              margin: EdgeInsets.symmetric(horizontal: 16),
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.edit,
                        color: Colors.grey[500],
                      ),
                      SizedBox(width: 12),
                      Text(
                        'О себе',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 14),
                  Text(
                    _currentUser.about ?? 'Информация о себе не добавлена',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[700],
                    ),
                  )
                ],
              ),
            ),
            SizedBox(height: 16),
            // Друзья (только в своем профиле)
            if (widget.isCurrentUser)
              Container(
                margin: EdgeInsets.symmetric(horizontal: 16),
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.people,
                          color: Colors.grey[500],
                        ),
                        SizedBox(width: 12),
                        Text(
                          'Друзья',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 14),
                    // Поле для добавления друга
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _friendIdController,
                            decoration: InputDecoration(
                              hintText: 'Введите ID друга',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: Color.fromARGB(255, 23, 144, 126),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: IconButton(
                            onPressed: _addFriend,
                            icon: Icon(Icons.add, color: Colors.white),
                            tooltip: 'Добавить друга',
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    
                    // Входящие заявки
                    if (_pendingRequests.isNotEmpty)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Входящие заявки:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.orange[700],
                            ),
                          ),
                          SizedBox(height: 12),
                          ..._pendingRequests.map((friendId) => Card(
                                margin: EdgeInsets.only(bottom: 8),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor:
                                        Color.fromARGB(255, 255, 243, 224),
                                    child: Icon(Icons.person_add,
                                        color: Colors.orange),
                                  ),
                                  title: Text(
                                    _getFriendName(friendId),
                                    style: TextStyle(
                                        fontWeight: FontWeight.w500),
                                  ),
                                  subtitle: Text('ID: $friendId'),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: Icon(Icons.check,
                                            color: Colors.green),
                                        onPressed: () =>
                                            _acceptFriendRequest(friendId),
                                        tooltip: 'Принять заявку',
                                      ),
                                      IconButton(
                                        icon: Icon(Icons.close,
                                            color: Colors.red),
                                        onPressed: () =>
                                            _showRejectRequestDialog(
                                                friendId, _getFriendName(friendId)),
                                        tooltip: 'Отклонить заявку',
                                      ),
                                    ],
                                  ),
                                  onTap: () =>
                                      _navigateToFriendProfile(friendId),
                                  contentPadding:
                                      EdgeInsets.symmetric(horizontal: 16),
                                ),
                              )),
                          SizedBox(height: 16),
                        ],
                      ),
                    
                    // Исходящие заявки
                    if (_outgoingRequests.isNotEmpty)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Исходящие заявки:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.blue[700],
                            ),
                          ),
                          SizedBox(height: 12),
                          ..._outgoingRequests.map((friendId) => Card(
                                margin: EdgeInsets.only(bottom: 8),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor:
                                        Color.fromARGB(255, 224, 240, 255),
                                    child: Icon(Icons.person_outline,
                                        color: Colors.blue),
                                  ),
                                  title: Text(
                                    _getFriendName(friendId),
                                    style: TextStyle(
                                        fontWeight: FontWeight.w500),
                                  ),
                                  subtitle: Text('ID: $friendId'),
                                  trailing: IconButton(
                                    icon: Icon(Icons.cancel,
                                        color: Colors.orange),
                                    onPressed: () =>
                                        _showCancelRequestDialog(
                                            friendId, _getFriendName(friendId)),
                                    tooltip: 'Отменить заявку',
                                  ),
                                  onTap: () =>
                                      _navigateToFriendProfile(friendId),
                                  contentPadding:
                                      EdgeInsets.symmetric(horizontal: 16),
                                ),
                              )),
                          SizedBox(height: 16),
                        ],
                      ),
                    
                    // Список друзей
                    if (_friendsList.isNotEmpty)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Друзья:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.green[700],
                            ),
                          ),
                          SizedBox(height: 12),
                          ..._friendsList.map((friendId) => Card(
                                margin: EdgeInsets.only(bottom: 8),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor:
                                        Color.fromARGB(255, 230, 245, 243),
                                    child: Icon(Icons.person,
                                        color: Color.fromARGB(
                                            255, 16, 134, 134)),
                                  ),
                                  title: Text(
                                    _getFriendName(friendId),
                                    style: TextStyle(
                                        fontWeight: FontWeight.w500),
                                  ),
                                  subtitle: Text('ID: $friendId'),
                                  trailing: IconButton(
                                    icon: Icon(Icons.remove_circle,
                                        color: Colors.red),
                                    onPressed: () =>
                                        _showRemoveFriendDialog(
                                            friendId, _getFriendName(friendId)),
                                    tooltip: 'Удалить из друзей',
                                  ),
                                  onTap: () =>
                                      _navigateToFriendProfile(friendId),
                                  contentPadding:
                                      EdgeInsets.symmetric(horizontal: 16),
                                ),
                              )),
                        ],
                      )
                    else if (_pendingRequests.isEmpty && _outgoingRequests.isEmpty)
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Center(
                          child: Text(
                            'У вас пока нет друзей',
                            style: TextStyle(
                              color: Colors.grey,
                              fontStyle: FontStyle.italic,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}