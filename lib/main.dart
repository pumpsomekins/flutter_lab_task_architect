import 'package:flutter/material.dart';
import 'dart:async';

// =========================================================================
// 1. DATA MODELS
// =========================================================================

// Model for an individual task item
class Task {
  final String title;
  bool isDone;
  final int listId; // Links the task to its parent list

  Task({required this.title, this.isDone = false, required this.listId});
}

// Model for the list group (The 'name' property is now mutable for editing)
class TaskList {
  final int id;
  String name; // CHANGED to non-final to allow editing

  TaskList({required this.id, required this.name});
}

// =========================================================================
// 2. MAIN APPLICATION WIDGET
// =========================================================================

void main() {
  runApp(const TodoApp());
}

class TodoApp extends StatelessWidget {
  const TodoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Grouped To-Do List',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const TodoListScreen(),
    );
  }
}

// =========================================================================
// 3. TODO LIST SCREEN (STATEFUL)
// =========================================================================

class TodoListScreen extends StatefulWidget {
  const TodoListScreen({super.key});

  @override
  State<TodoListScreen> createState() => _TodoListScreenState();
}

class _TodoListScreenState extends State<TodoListScreen> {
  // --- STATE AND DATA ---
  
  // Hardcoded initial data for lists (now with mutable names)
  final List<TaskList> _taskLists = [
    TaskList(id: 1, name: 'Work'),
    TaskList(id: 2, name: 'Personal'),
    TaskList(id: 3, name: 'Shopping'),
  ];
  
  // Hardcoded initial data for all tasks
  final List<Task> _allTasks = [
    Task(title: 'Review Flutter PR', listId: 1),
    Task(title: 'Water the plants', listId: 2),
    Task(title: 'Buy milk', listId: 3, isDone: true),
    Task(title: 'Draft presentation slides', listId: 1),
    Task(title: 'Call the landlord', listId: 2),
    Task(title: 'Pay electric bill', listId: 2),
  ];
  
  // State to track which list is currently selected
  int _currentListId = 1; 
  
  // Controller for the text input field in the dialogs
  final TextEditingController _textFieldController = TextEditingController();

  // --- GETTERS for currently displayed data ---

  // Filters _allTasks based on the currently selected list ID
  List<Task> get _currentTasks {
    return _allTasks.where((task) => task.listId == _currentListId).toList();
  }

  // Gets the name of the currently selected list for the AppBar
  String get _currentListName {
    // Return a default name if no lists exist (ID 0 used as fallback)
    if (_currentListId == 0) return 'No List Selected';
    return _taskLists.firstWhere((list) => list.id == _currentListId).name;
  }

  // --- TASK CRUD FUNCTIONS ---

  void _addTodoItem(String title) {
    if (title.isNotEmpty) {
      setState(() {
        _allTasks.add(Task(title: title, listId: _currentListId));
      });
      _textFieldController.clear();
    }
  }

  void _removeTodoItem(Task taskToRemove) {
    setState(() {
      _allTasks.removeWhere((task) => task == taskToRemove);
    });
  }

  void _toggleTaskStatus(Task task) {
    setState(() {
      task.isDone = !task.isDone;
    });
  }

  // --- LIST MANAGEMENT FUNCTIONS ---

  void _addTaskList(String name) {
    if (name.isNotEmpty) {
      setState(() {
        // Simple logic for unique ID
        final int newId = _taskLists.isEmpty ? 1 : _taskLists.last.id + 1;
        final newList = TaskList(id: newId, name: name);
        _taskLists.add(newList);
        _currentListId = newId; // Automatically select the new list
      });
      _textFieldController.clear();
    }
  }

  void _editTaskListName(TaskList list, String newName) {
    if (newName.isNotEmpty) {
      setState(() {
        // Since 'name' is mutable, we can assign the new value
        list.name = newName; 
      });
      _textFieldController.clear();
    }
  }

  void _deleteTaskList(TaskList list) {
    setState(() {
      // 1. Remove all tasks associated with this list ID
      _allTasks.removeWhere((task) => task.listId == list.id);
      
      // 2. Remove the list itself
      _taskLists.removeWhere((l) => l.id == list.id);

      // 3. Switch to a valid list if the deleted one was the current one
      if (_currentListId == list.id) {
        _currentListId = _taskLists.isNotEmpty ? _taskLists.first.id : 0; // Fall back to the first or 0 (none)
      }
    });
  }

  // --- UI DIALOGS ---

  // Dialog for adding or editing a single task (for the currently selected list)
  Future<void> _displayTaskDialog() async {
    _textFieldController.clear(); // Clear for new task input

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Add a new item to: $_currentListName'),
          content: TextField(
            controller: _textFieldController,
            decoration: const InputDecoration(hintText: 'Enter your task'),
            autofocus: true,
            onSubmitted: (value) {
              _addTodoItem(value);
              Navigator.of(context).pop();
            },
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('CANCEL'),
              onPressed: () {
                _textFieldController.clear();
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('ADD'),
              onPressed: () {
                _addTodoItem(_textFieldController.text);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  // Dialog for adding or editing a TaskList (the group itself)
  Future<void> _displayListDialog({TaskList? listToEdit}) async {
    // Pre-fill the text field if editing
    _textFieldController.text = listToEdit?.name ?? '';
    
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(listToEdit == null ? 'Add New List' : 'Edit List Name'),
          content: TextField(
            controller: _textFieldController,
            decoration: const InputDecoration(hintText: 'Enter list name'),
            autofocus: true,
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('CANCEL'),
              onPressed: () {
                _textFieldController.clear();
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text(listToEdit == null ? 'ADD' : 'SAVE'),
              onPressed: () {
                if (listToEdit == null) {
                  _addTaskList(_textFieldController.text);
                } else {
                  _editTaskListName(listToEdit, _textFieldController.text);
                }
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  // Confirmation dialog before deleting a list
  Future<void> _displayDeleteConfirmation(TaskList list) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Deletion'),
          content: Text('Are you sure you want to delete the list "${list.name}" and all associated tasks?'),
          actions: <Widget>[
            TextButton(
              child: const Text('CANCEL'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('DELETE', style: TextStyle(color: Colors.red)),
              onPressed: () {
                _deleteTaskList(list);
                Navigator.of(context).pop(); // Close the confirmation dialog
                Navigator.of(context).pop(); // Close the drawer
              },
            ),
          ],
        );
      },
    );
  }

  // --- BUILD METHOD ---
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // The AppBar shows the name of the currently selected list
      appBar: AppBar(
        title: Text('${_currentListName} Tasks'), 
      ),
      
      // The Drawer allows the user to switch between and manage lists
      drawer: Drawer(
        child: Column(
          children: [
            // Drawer Header (Styling)
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.blue),
              child: SizedBox(
                width: double.infinity,
                child: Text(
                  'Task Lists',
                  style: TextStyle(color: Colors.white, fontSize: 24),
                ),
              ),
            ),
            
            // List Tiles for each TaskList with Edit/Delete options
            Expanded( 
              child: ListView(
                children: _taskLists.map((list) {
                  return ListTile(
                    title: Text(list.name),
                    selected: list.id == _currentListId, // Highlight selected list
                    onTap: () {
                      setState(() {
                        _currentListId = list.id; // Switch the active list
                      });
                      Navigator.pop(context); // Close the drawer
                    },
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Edit Button
                        IconButton(
                          icon: const Icon(Icons.edit, size: 20),
                          onPressed: () => _displayListDialog(listToEdit: list),
                          tooltip: 'Edit List Name',
                        ),
                        // Delete Button (only visible if there's more than one list)
                        if (_taskLists.length > 1)
                          IconButton(
                            icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                            onPressed: () => _displayDeleteConfirmation(list),
                            tooltip: 'Delete List',
                          ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
            
            const Divider(),
            
            // Button to Add a New List
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ListTile(
                leading: const Icon(Icons.add_box),
                title: const Text('Add New List', style: TextStyle(fontWeight: FontWeight.bold)),
                onTap: () {
                  _displayListDialog();
                  // Drawer stays open briefly to show the new list being added
                },
              ),
            ),
          ],
        ),
      ),
      
      // The body displays only the tasks for the selected list
      body: _currentListId == 0
          ? const Center(child: Text('Please create a task list to begin.'))
          : ListView.builder(
              itemCount: _currentTasks.length, 
              itemBuilder: (context, index) {
                final task = _currentTasks[index];
                return ListTile(
                  title: Text(
                    task.title,
                    style: TextStyle(
                      decoration: task.isDone ? TextDecoration.lineThrough : null,
                      color: task.isDone ? Colors.grey : null,
                    ),
                  ),
                  // Checkbox to mark task as complete
                  leading: Checkbox(
                    value: task.isDone,
                    onChanged: (bool? newValue) {
                      _toggleTaskStatus(task);
                    },
                  ),
                  // Delete button
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _removeTodoItem(task),
                  ),
                );
              },
            ),
      
      // Floating action button to add a task (only enabled if a list is selected)
      floatingActionButton: _currentListId != 0
          ? FloatingActionButton(
              onPressed: _displayTaskDialog,
              tooltip: 'Add Item to ${_currentListName}',
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}