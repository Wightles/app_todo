import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app_todo/todo/widgets/note_editor.dart';

enum TodoFilter { all, active, completed, overdue }

class TodoScene extends StatefulWidget {
  const TodoScene({super.key});

  @override
  _TodoSceneState createState() => _TodoSceneState();
}

class _TodoSceneState extends State<TodoScene>
    with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> todos = [];
  List<Map<String, dynamic>> filteredTodos = [];
  TextEditingController searchController = TextEditingController();
  late SharedPreferences prefs;
  bool useImageBackground = false;
  Color selectedColor = Color.fromARGB(255, 128, 219, 219);
  String selectedImage = 'assets/images/test3.png';
  TodoFilter currentFilter = TodoFilter.all;

  // Анимации
  late AnimationController _animationController;
  late Animation<double> _paletteAnimation;
  bool _showPalette = false;

  // Оптимизированные списки
  final List<Map<String, dynamic>> _filterOptions = [
    {
      'value': TodoFilter.all,
      'icon': Icons.all_inclusive,
      'color': Colors.blue,
      'label': 'Все'
    },
    {
      'value': TodoFilter.active,
      'icon': Icons.radio_button_unchecked,
      'color': Colors.orange,
      'label': 'Активные'
    },
    {
      'value': TodoFilter.completed,
      'icon': Icons.check_circle,
      'color': Colors.green,
      'label': 'Выполненные'
    },
    {
      'value': TodoFilter.overdue,
      'icon': Icons.warning,
      'color': Colors.red,
      'label': 'Просроченные'
    },
  ];

  final List<Map<String, dynamic>> _paletteOptions = [
    {
      'type': 'color',
      'value': Color.fromARGB(255, 128, 219, 219),
      'name': 'Бирюзовый',
      'gradient': [Color(0xFF80DBDB), Color(0xFF4DCFCF)]
    },
    {
      'type': 'color',
      'value': Color.fromARGB(255, 255, 204, 153),
      'name': 'Персиковый',
      'gradient': [Color(0xFFFFCC99), Color(0xFFFFB366)]
    },
    {
      'type': 'color',
      'value': Color.fromARGB(255, 204, 255, 153),
      'name': 'Мятный',
      'gradient': [Color(0xFFCCFF99), Color(0xFFB3FF66)]
    },
    {
      'type': 'color',
      'value': Color.fromARGB(255, 255, 153, 204),
      'name': 'Розовый',
      'gradient': [Color(0xFFFF99CC), Color(0xFFFF66B3)]
    },
    {
      'type': 'color',
      'value': Color.fromARGB(255, 204, 153, 255),
      'name': 'Лавандовый',
      'gradient': [Color(0xFFCC99FF), Color(0xFFB366FF)]
    },
    {
      'type': 'color',
      'value': Color.fromARGB(255, 153, 204, 255),
      'name': 'Голубой',
      'gradient': [Color(0xFF99CCFF), Color(0xFF66B3FF)]
    },
    {
      'type': 'color',
      'value': Color.fromARGB(255, 255, 255, 153),
      'name': 'Лимонный',
      'gradient': [Color(0xFFFFFF99), Color(0xFFFFF066)]
    },
    {
      'type': 'image',
      'value': 'assets/images/test3.png',
      'name': 'Пингвины',
      'gradient': [Color(0xFF6A89CC), Color(0xFF4A69BB)]
    },
    {
      'type': 'image',
      'value': 'assets/images/test4.png',
      'name': 'Сердца',
      'gradient': [Color(0xFFFF6B6B), Color(0xFFFF4757)]
    },
    {
      'type': 'image',
      'value': 'assets/images/test5.png',
      'name': 'Лес',
      'gradient': [Color(0xFF1DD1A1), Color(0xFF10AC84)]
    },
  ];

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300),
    );

    _paletteAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    _initPrefs();
    searchController.addListener(filterTodos);
  }

  @override
  void dispose() {
    _animationController.dispose();
    searchController.removeListener(filterTodos);
    searchController.dispose();
    super.dispose();
  }

  Future<void> _initPrefs() async {
    prefs = await SharedPreferences.getInstance();
    _loadBackgroundPreference();
    _loadColorPreference();
    _loadImagePreference();
    _loadTodos();
  }

  void _loadBackgroundPreference() {
    setState(() {
      useImageBackground = prefs.getBool('use_image_background') ?? false;
    });
  }

  void _loadColorPreference() {
    int colorValue = prefs.getInt('selected_color') ?? 4284513243;
    setState(() {
      selectedColor = Color(colorValue);
    });
  }

  void _loadImagePreference() {
    String imagePath =
        prefs.getString('selected_image') ?? 'assets/images/test3.png';
    setState(() {
      selectedImage = imagePath;
    });
  }

  void _loadTodos() {
    setState(() {
      List<String>? savedTodos = prefs.getStringList('todos');
      if (savedTodos != null) {
        todos = savedTodos.map((json) {
          List<String> parts = json.split('|||');
          Map<String, dynamic> todo = {
            'title': parts[0],
            'content': parts.length > 1 ? parts[1] : '',
            'completed': parts.length > 3 ? parts[3] == 'true' : false,
          };
          if (parts.length > 2) {
            todo['dateTime'] = parts[2];
          } else {
            todo['dateTime'] = DateTime.now().toString();
          }
          if (parts.length > 4 && parts[4] != 'null') {
            todo['dueDate'] = parts[4];
          }
          return todo;
        }).toList();
      } else {
        todos = [];
      }
      _applyFilter();
    });
  }

  Future<void> _saveTodos() async {
    List<String> todosToSave = todos.map((todo) {
      return '${todo['title']}|||${todo['content']}|||${todo['dateTime']}|||${todo['completed']}|||${todo['dueDate'] ?? 'null'}';
    }).toList();
    await prefs.setStringList('todos', todosToSave);
    _checkForOverdue();
  }

  void _checkForOverdue() {
    final now = DateTime.now();
    int overdueCount = 0;

    for (var todo in todos) {
      if (todo['dueDate'] != null && !(todo['completed'] as bool)) {
        final dueDate = DateTime.parse(todo['dueDate'] as String);
        if (dueDate.isBefore(now)) {
          overdueCount++;
        }
      }
    }

    prefs.setInt('overdue_tasks', overdueCount);

    final dayOfWeek = now.weekday - 1;
    prefs.setInt('overdue_week_$dayOfWeek', overdueCount);
  }

  // Современное меню фильтров
  Widget _buildFilterChips() {
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        shrinkWrap: true,
        physics: BouncingScrollPhysics(),
        itemCount: _filterOptions.length,
        itemBuilder: (context, index) {
          final option = _filterOptions[index];
          final isSelected = currentFilter == option['value'];

          return Padding(
            padding: EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(
                option['label'],
                style: TextStyle(
                  color: isSelected ? Colors.white : option['color'],
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
              ),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  currentFilter = option['value'];
                  _applyFilter();
                });
              },
              backgroundColor: Colors.white.withOpacity(0.2),
              selectedColor: option['color'],
              side: BorderSide(
                color: isSelected ? option['color'] : Colors.white.withOpacity(0.3),
                width: 1.0,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              checkmarkColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 2),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          );
        },
      ),
    );
  }

  void _applyFilter() {
    final now = DateTime.now();

    setState(() {
      filteredTodos = todos.where((todo) {
        final isCompleted = todo['completed'] as bool;
        final dueDate = todo['dueDate'] != null
            ? DateTime.parse(todo['dueDate'] as String)
            : null;
        final isOverdue =
            dueDate != null && dueDate.isBefore(now) && !isCompleted;

        switch (currentFilter) {
          case TodoFilter.all:
            return true;
          case TodoFilter.active:
            return !isCompleted && !isOverdue;
          case TodoFilter.completed:
            return isCompleted;
          case TodoFilter.overdue:
            return isOverdue;
        }
      }).toList();
    });
  }

  void _togglePalette() {
    setState(() {
      _showPalette = !_showPalette;
      if (_showPalette) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  void _selectPaletteOption(int index) {
    final option = _paletteOptions[index];
    setState(() {
      if (option['type'] == 'color') {
        selectedColor = option['value'] as Color;
        useImageBackground = false;
        prefs.setInt('selected_color', selectedColor.value);
        prefs.setBool('use_image_background', false);
      } else {
        selectedImage = option['value'] as String;
        useImageBackground = true;
        prefs.setBool('use_image_background', true);
        prefs.setString('selected_image', selectedImage);
      }
      _showPalette = false;
      _animationController.reverse();
    });
  }

  void filterTodos() {
    setState(() {
      String searchText = searchController.text.toLowerCase();
      final now = DateTime.now();

      filteredTodos = todos.where((todo) {
        bool matchesSearch = searchText.isEmpty ||
            (todo['title'] as String).toLowerCase().contains(searchText) ||
            (todo['content'] as String).toLowerCase().contains(searchText);

        final isCompleted = todo['completed'] as bool;
        final dueDate = todo['dueDate'] != null
            ? DateTime.parse(todo['dueDate'] as String)
            : null;
        final isOverdue =
            dueDate != null && dueDate.isBefore(now) && !isCompleted;

        bool matchesFilter;
        switch (currentFilter) {
          case TodoFilter.all:
            matchesFilter = true;
            break;
          case TodoFilter.active:
            matchesFilter = !isCompleted && !isOverdue;
            break;
          case TodoFilter.completed:
            matchesFilter = isCompleted;
            break;
          case TodoFilter.overdue:
            matchesFilter = isOverdue;
            break;
        }

        return matchesSearch && matchesFilter;
      }).toList();
    });
  }

  void addTodo() {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => NoteEditor(
          onSave: (title, content, dueDate) {
            setState(() {
              todos.add({
                'title': title,
                'content': content,
                'dateTime': DateTime.now().toString(),
                'dueDate': dueDate?.toString(),
                'completed': false,
              });
              _saveTodos();
              filterTodos();
              _updateStatistics('created');
            });
          },
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: Offset(0.0, 1.0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOut,
            )),
            child: child,
          );
        },
        transitionDuration: Duration(milliseconds: 300),
      ),
    );
  }

  void editTodo(int index) {
    Map<String, dynamic> todoToEdit = filteredTodos[index];
    String originalTitle = todoToEdit['title'] as String;
    String originalContent = todoToEdit['content'] as String;
    String originalDateTime = todoToEdit['dateTime'] as String;
    bool originalCompleted = todoToEdit['completed'] as bool;
    DateTime? originalDueDate = todoToEdit['dueDate'] != null
        ? DateTime.parse(todoToEdit['dueDate'] as String)
        : null;

    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => NoteEditor(
          initialTitle: originalTitle,
          initialContent: originalContent,
          initialDueDate: originalDueDate,
          onSave: (newTitle, newContent, newDueDate) {
            setState(() {
              int originalIndex = todos.indexWhere((todo) =>
                  todo['title'] == originalTitle &&
                  todo['content'] == originalContent &&
                  todo['dateTime'] == originalDateTime);

              if (originalIndex != -1) {
                todos[originalIndex] = {
                  'title': newTitle,
                  'content': newContent,
                  'dateTime': DateTime.now().toString(),
                  'dueDate': newDueDate?.toString(),
                  'completed': originalCompleted,
                };
                _saveTodos();
                filterTodos();
              }
            });
          },
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.9, end: 1.0).animate(
                CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeInOut,
                ),
              ),
              child: child,
            ),
          );
        },
        transitionDuration: Duration(milliseconds: 250),
      ),
    );
  }

  void toggleTodoCompletion(int index) {
    setState(() {
      Map<String, dynamic> todoToToggle = filteredTodos[index];
      int originalIndex = todos.indexWhere((todo) =>
          todo['title'] == todoToToggle['title'] &&
          todo['content'] == todoToToggle['content'] &&
          todo['dateTime'] == todoToToggle['dateTime']);

      if (originalIndex != -1) {
        bool wasCompleted = todos[originalIndex]['completed'] as bool;
        bool newCompletedState = !wasCompleted;
        todos[originalIndex]['completed'] = newCompletedState;

        _saveTodos();
        filterTodos();

        if (newCompletedState) {
          _updateStatistics('completed');
        } else {
          _decrementStatistics('completed');
        }
      }
    });
  }

  void _decrementStatistics(String type) async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final dayOfWeek = now.weekday - 1;

    switch (type) {
      case 'completed':
        int completed = prefs.getInt('completed_tasks') ?? 0;
        if (completed > 0) {
          await prefs.setInt('completed_tasks', completed - 1);
        }

        int weekCount = prefs.getInt('completed_week_$dayOfWeek') ?? 0;
        if (weekCount > 0) {
          await prefs.setInt('completed_week_$dayOfWeek', weekCount - 1);
        }
        break;
    }
  }

  void removeTodo(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Удалить задачу?'),
        content: Text('Вы уверены, что хотите удалить эту задачу?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                Map<String, dynamic> todoToRemove = filteredTodos[index];
                todos.removeWhere((todo) =>
                    todo['title'] == todoToRemove['title'] &&
                    todo['content'] == todoToRemove['content'] &&
                    todo['dateTime'] == todoToRemove['dateTime']);
                _saveTodos();
                filterTodos();
                _updateStatistics('deleted');
              });
              Navigator.pop(context);
            },
            child: Text('Удалить', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _updateStatistics(String type) async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final dayOfWeek = now.weekday - 1;

    switch (type) {
      case 'created':
        int total = prefs.getInt('total_tasks') ?? 0;
        await prefs.setInt('total_tasks', total + 1);

        int weekCount = prefs.getInt('created_week_$dayOfWeek') ?? 0;
        await prefs.setInt('created_week_$dayOfWeek', weekCount + 1);
        break;

      case 'completed':
        int completed = prefs.getInt('completed_tasks') ?? 0;
        await prefs.setInt('completed_tasks', completed + 1);

        int weekCount = prefs.getInt('completed_week_$dayOfWeek') ?? 0;
        await prefs.setInt('completed_week_$dayOfWeek', weekCount + 1);
        break;

      case 'deleted':
        int deleted = prefs.getInt('deleted_tasks') ?? 0;
        await prefs.setInt('deleted_tasks', deleted + 1);

        int weekCount = prefs.getInt('deleted_week_$dayOfWeek') ?? 0;
        await prefs.setInt('deleted_week_$dayOfWeek', weekCount + 1);
        break;
    }

    _checkForOverdue();
  }

  String _formatDateTime(String dateTimeString) {
    try {
      DateTime dateTime = DateTime.parse(dateTimeString);
      return '${_twoDigits(dateTime.day)}.${_twoDigits(dateTime.month)}.${dateTime.year} ${_twoDigits(dateTime.hour)}:${_twoDigits(dateTime.minute)}';
    } catch (e) {
      return 'Дата не определена';
    }
  }

  String _twoDigits(int n) {
    if (n >= 10) return '$n';
    return '0$n';
  }

  Widget _buildTodoCard(Map<String, dynamic> todo, int index) {
    final isCompleted = todo['completed'] as bool;
    final dueDate = todo['dueDate'] != null
        ? DateTime.parse(todo['dueDate'] as String)
        : null;
    final isOverdue =
        dueDate != null && dueDate.isBefore(DateTime.now()) && !isCompleted;

    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      margin: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isCompleted
            ? Color.fromARGB(255, 200, 230, 200)
            : (isOverdue
                ? Color.fromARGB(255, 255, 230, 230)
                : Colors.white),
        borderRadius: BorderRadius.circular(16),
        border: isCompleted
            ? Border.all(color: Colors.green, width: 2)
            : isOverdue
                ? Border.all(color: Colors.red, width: 2)
                : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => editTodo(index),
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            todo['title'] as String,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              decoration: isCompleted
                                  ? TextDecoration.lineThrough
                                  : TextDecoration.none,
                              color: Colors.black,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Expanded(
                      child: Text(
                        todo['content'] as String,
                        style: TextStyle(
                          decoration: isCompleted
                              ? TextDecoration.lineThrough
                              : TextDecoration.none,
                          color: Colors.black,
                        ),
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SizedBox(height: 12),
                    if (dueDate != null)
                      Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isOverdue
                              ? Colors.red.withOpacity(0.9)
                              : Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 14,
                              color: isOverdue ? Colors.white : Colors.grey[700],
                            ),
                            SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                _formatDateTime(dueDate.toString()),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isOverdue ? Colors.white : Colors.grey[700],
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (isOverdue)
                              Padding(
                                padding: EdgeInsets.only(left: 4),
                                child: Icon(Icons.warning,
                                    size: 14, color: Colors.white),
                              ),
                          ],
                        ),
                      ),
                    SizedBox(height: 8),
                    Text(
                      _formatDateTime(todo['dateTime'] as String),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  onPressed: () => removeTodo(index),
                  icon: Icon(Icons.delete_outline, size: 20),
                  color: Colors.red[400],
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints(),
                ),
              ),
              Positioned(
                bottom: 8,
                right: 8,
                child: IconButton(
                  onPressed: () => toggleTodoCompletion(index),
                  icon: Icon(
                    isCompleted
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    size: 20,
                    color: isCompleted
                        ? Colors.green
                        : (isOverdue ? Colors.red[400] : Colors.grey[600]),
                  ),
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: useImageBackground
          ? null
          : selectedColor,
      body: Stack(
        children: [
          if (useImageBackground)
            Positioned.fill(
              child: Image.asset(
                selectedImage,
                fit: BoxFit.cover,
              ),
            ),
          
          Column(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.85),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 15,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 4,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: TextField(
                              controller: searchController,
                              decoration: InputDecoration(
                                hintText: 'Поиск заметок...',
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 10,
                                ),
                                prefixIcon: Icon(Icons.search, 
                                    size: 20, 
                                    color: Colors.grey[600]),
                                hintStyle: TextStyle(fontSize: 14),
                              ),
                              style: TextStyle(fontSize: 14),
                            ),
                          ),
                        ),
                        SizedBox(width: 10),
                        // Кнопка палитры
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: _showPalette
                                ? Theme.of(context).primaryColor
                                : Colors.white.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: IconButton(
                            onPressed: _togglePalette,
                            icon: Icon(
                              Icons.palette,
                              size: 20,
                              color: _showPalette
                                  ? Colors.white
                                  : Colors.grey[700],
                            ),
                            padding: EdgeInsets.zero,
                            tooltip: 'Выбрать оформление',
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    // Фильтры
                    _buildFilterChips(),
                  ],
                ),
              ),

              SizeTransition(
                sizeFactor: _paletteAnimation,
                axisAlignment: -1.0,
                child: Container(
                  height: 90,
                  padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    physics: BouncingScrollPhysics(),
                    itemCount: _paletteOptions.length,
                    itemBuilder: (context, index) {
                      final option = _paletteOptions[index];
                      return GestureDetector(
                        onTap: () => _selectPaletteOption(index),
                        child: Container(
                          width: 60,
                          margin: EdgeInsets.symmetric(horizontal: 4),
                          child: Column(
                            children: [
                              Container(
                                width: 45,
                                height: 45,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    colors: option['gradient'],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  image: option['type'] == 'image'
                                      ? DecorationImage(
                                          image: AssetImage(
                                              option['value'] as String),
                                          fit: BoxFit.cover,
                                        )
                                      : null,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      blurRadius: 4,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.8),
                                    width: 2,
                                  ),
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                option['name'] as String,
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black87,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

              Expanded(
                child: AnimatedSwitcher(
                  duration: Duration(milliseconds: 300),
                  child: filteredTodos.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.task_alt,
                                size: 64,
                                color: Colors.white.withOpacity(0.7),
                              ),
                              SizedBox(height: 16),
                              Text(
                                currentFilter == TodoFilter.completed
                                    ? 'Нет выполненных задач'
                                    : currentFilter == TodoFilter.overdue
                                        ? 'Нет просроченных задач'
                                        : 'Задачи не найдены',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 16,
                                  shadows: [
                                    Shadow(
                                      offset: Offset(1, 1),
                                      blurRadius: 3,
                                      color: Colors.black.withOpacity(0.5),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        )
                      : GridView.builder(
                          key: ValueKey(currentFilter),
                          padding: EdgeInsets.all(8),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                            childAspectRatio: 1.0,
                          ),
                          itemCount: filteredTodos.length,
                          itemBuilder: (context, index) {
                            return _buildTodoCard(filteredTodos[index], index);
                          },
                        ),
                ),
              ),
            ],
          ),

          Positioned(
            bottom: 20,
            right: 20,
            child: FloatingActionButton(
              backgroundColor: const Color.fromARGB(255, 10, 220, 181),
              onPressed: addTodo,
              elevation: 6,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(Icons.add, color: Colors.white, size: 28),
            ),
          ),
        ],
      ),
    );
  }
}