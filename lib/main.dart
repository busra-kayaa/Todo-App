
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Todo App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        primarySwatch: Colors.lightGreen,
        scaffoldBackgroundColor: Colors.grey[100],
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.lightGreenAccent,
          foregroundColor: Colors.black,
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: Colors.lightGreenAccent,
        ),
      ),
      home: TodoListScreen(),
    );
  }
}

class TodoListScreen extends StatefulWidget {
  @override
  _TodoListScreenState createState() => _TodoListScreenState();
}

class _TodoListScreenState extends State<TodoListScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _subtitleController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  DateTime? _selectedDate;
  String? _selectedIconName;
  String _filterStatus = 'all';
  String _searchText = '';

  final List<Map<String, dynamic>> icons = [
    {'name': 'work', 'icon': Icons.work},
    {'name': 'school', 'icon': Icons.school},
    {'name': 'shopping', 'icon': Icons.shopping_bag},
    {'name': 'exercise', 'icon': Icons.fitness_center},
    {'name': 'meeting', 'icon': Icons.meeting_room},
    {'name': 'book', 'icon': Icons.menu_book},
    {'name': 'cleaning', 'icon': Icons.cleaning_services},
    {'name': 'payment', 'icon': Icons.payments},
    {'name': 'event', 'icon': Icons.event},
    {'name': 'notes', 'icon': Icons.notes},
  ];
  void _showAddTodoModal({Todo? existingTodo}) {
    if (existingTodo != null) {
      _titleController.text = existingTodo.title;
      _subtitleController.text = existingTodo.subtitle;
      _selectedDate = existingTodo.date != null ? DateTime.parse(existingTodo.date!) : null;
      _selectedIconName =
          icons.firstWhere((icon) => icon['icon'] == existingTodo.icon)['name'];
    }

    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      backgroundColor: Colors.white,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 20,
                right: 20,
                top: 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 40,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey[400],
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      existingTodo == null ? 'Yeni Görev Ekle' : 'Görevi Güncelle',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 20),
                    TextField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        labelText: 'Başlık',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 15),
                    TextField(
                      controller: _subtitleController,
                      decoration: InputDecoration(
                        labelText: 'Alt Başlık',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 15),
                    DropdownButtonFormField<Map<String, dynamic>>(
                      value: _selectedIconName != null
                          ? icons.firstWhere((e) => e['name'] == _selectedIconName)
                          : null,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                      hint: Text('İkon Seçin'),
                      onChanged: (value) {
                        setModalState(() {
                          _selectedIconName = value?['name'];
                        });
                      },
                      items: icons.map((icon) {
                        return DropdownMenuItem<Map<String, dynamic>>(
                          value: icon,
                          child: Row(
                            children: [
                              Icon(icon['icon']),
                              SizedBox(width: 10),
                              Text(icon['name']),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                    SizedBox(height: 15),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        minimumSize: Size(double.infinity, 50),
                      ),
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2101),
                        );
                        if (picked != null) {
                          setModalState(() {
                            _selectedDate = picked;
                          });
                        }
                      },
                      child: Text(
                        _selectedDate == null
                            ? 'Tarih Seçin'
                            : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                      ),
                    ),
                    SizedBox(height: 15),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.lightGreenAccent,
                        minimumSize: Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                      ),
                      onPressed: () async {
                        if (_titleController.text.isEmpty || _subtitleController.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Başlık ve Alt Başlık boş olamaz!')),
                          );
                          return;
                        }

                        final data = {
                          'title': _titleController.text,
                          'subtitle': _subtitleController.text,
                          'icon': _selectedIconName ?? 'notes',
                          'date': _selectedDate?.toIso8601String(),
                          'timestamp': FieldValue.serverTimestamp(),
                        };

                        if (existingTodo == null) {
                          data['isDone'] = false;
                          await _firestore.collection('todos').add(data);
                        } else {
                          await _firestore.collection('todos').doc(existingTodo.id).update(data);
                        }

                        _titleController.clear();
                        _subtitleController.clear();
                        setModalState(() {
                          _selectedIconName = null;
                          _selectedDate = null;
                        });

                        Navigator.pop(context);
                      },
                      icon: Icon(
                        existingTodo == null ? Icons.add_task : Icons.update,
                        size: 26,
                      ),
                      label: Text(
                        existingTodo == null ? 'Görev Ekle' : 'Güncelle',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    SizedBox(height: 20),
                  ],
                ),
              ),
            );
          },
        );
      },
    ).whenComplete(() {
      _titleController.clear();
      _subtitleController.clear();
      setState(() {
        _selectedIconName = null;
        _selectedDate = null;
      });
    });
  }
  Stream<List<Todo>> _getTodos() {
    return _firestore
        .collection('todos')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      List<Todo> todos = snapshot.docs.map((doc) => Todo.fromFirestore(doc)).toList();

      if (_filterStatus == 'done') {
        todos = todos.where((todo) => todo.isDone).toList();
      } else if (_filterStatus == 'todo') {
        todos = todos.where((todo) => !todo.isDone).toList();
      }

      if (_searchText.isNotEmpty) {
        todos = todos
            .where((todo) =>
                todo.title.toLowerCase().contains(_searchText.toLowerCase()) ||
                todo.subtitle.toLowerCase().contains(_searchText.toLowerCase()))
            .toList();
      }

      return todos;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Görev Listesi'),
        actions: [
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () {
              showSearchDialog(context);
            },
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() {
                _filterStatus = value;
              });
            },
            itemBuilder: (context) => [
              PopupMenuItem(value: 'all', child: Text('Hepsi')),
              PopupMenuItem(value: 'done', child: Text('Tamamlananlar')),
              PopupMenuItem(value: 'todo', child: Text('Yapılacaklar')),
            ],
          ),
        ],
      ),
      body: StreamBuilder<List<Todo>>(
        stream: _getTodos(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Bir hata oluştu'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('Görev bulunamadı.'));
          }

          final todos = snapshot.data!;

          return ListView.builder(
            itemCount: todos.length,
            itemBuilder: (context, index) {
              final todo = todos[index];
              return ListTile(
                leading: Icon(todo.icon, color: todo.isDone ? Colors.green : Colors.grey),
                title: Text(
                  todo.title,
                  style: TextStyle(
                    decoration: todo.isDone ? TextDecoration.lineThrough : null,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(todo.subtitle),
                    if (todo.date != null)
                      Text(
                        'Tarih: ${DateTime.parse(todo.date!).day}/${DateTime.parse(todo.date!).month}/${DateTime.parse(todo.date!).year}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Checkbox(
                      value: todo.isDone,
                      onChanged: (bool? value) async {
                        await _firestore.collection('todos').doc(todo.id).update({
                          'isDone': value,
                        });
                      },
                    ),
                    IconButton(
                      icon: Icon(Icons.edit, color: Colors.orange),
                      onPressed: () {
                        _showAddTodoModal(existingTodo: todo);
                      },
                    ),
                    IconButton(
                      icon: Icon(Icons.delete, color: Colors.red),
                      onPressed: () async {
                        bool? confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text("Silmek istiyor musun?"),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: Text("İptal"),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: Text("Sil", style: TextStyle(color: Colors.red)),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          await _firestore.collection('todos').doc(todo.id).delete();
                        }
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTodoModal(),
        child: Icon(Icons.add),
      ),
    );
  }

  void showSearchDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Ara'),
          content: TextField(
            controller: _searchController,
            autofocus: true,
            decoration: InputDecoration(hintText: 'Başlık veya alt başlık...'),
            onChanged: (value) {
              setState(() {
                _searchText = value;
              });
            },
          ),
          actions: [
            TextButton(
              child: Text('Temizle'),
              onPressed: () {
                _searchController.clear();
                setState(() {
                  _searchText = '';
                });
                Navigator.pop(context);
              },
            ),
            TextButton(
              child: Text('Kapat'),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }
}

class Todo {
  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isDone;
  final String? date;

  Todo({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isDone,
    this.date,
  });

  factory Todo.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Todo(
      id: doc.id,
      title: data['title'],
      subtitle: data['subtitle'],
      icon: _getIconFromName(data['icon']),
      isDone: data['isDone'] ?? false,
      date: data['date'],
    );
  }

  static IconData _getIconFromName(String iconName) {
    switch (iconName) {
      case 'work':
        return Icons.work;
      case 'school':
        return Icons.school;
      case 'shopping':
        return Icons.shopping_bag;
      case 'exercise':
        return Icons.fitness_center;
      case 'meeting':
        return Icons.meeting_room;
      case 'book':
        return Icons.menu_book;
      case 'cleaning':
        return Icons.cleaning_services;
      case 'payment':
        return Icons.payments;
      case 'event':
        return Icons.event;
      case 'notes':
        return Icons.notes;
      default:
        return Icons.notes;
    }
  }
}
