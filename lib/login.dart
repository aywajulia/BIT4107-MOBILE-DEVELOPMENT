import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'student_model.dart';
import 'details.dart';

// SCREEN 1: LOGIN SCREEN
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  void _login() {
    String name = _nameController.text.trim();
    String password = _passwordController.text.trim();

    if (name.isNotEmpty && password.isNotEmpty) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => HomeScreen(studentName: name),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter both Name and Password'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Login'),
        backgroundColor: Colors.blue,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.school, size: 80, color: Colors.blue),
            const SizedBox(height: 30),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Student Name',
                hintText: 'Enter your full name',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Password',
                hintText: 'Enter password',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock),
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _login,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                backgroundColor: Colors.blue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('Login', style: TextStyle(fontSize: 18)),
            ),
          ],
        ),
      ),
    );
  }
}

// SCREEN 2: HOME SCREEN (ADD & DELETE STUDENTS)
class HomeScreen extends StatefulWidget {
  final String studentName;

  const HomeScreen({super.key, required this.studentName});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _courseController = TextEditingController();

  List<Student> _students = [];

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  // Load data from phone storage
  Future<void> _loadStudents() async {
    final prefs = await SharedPreferences.getInstance();
    List<String>? savedStudents = prefs.getStringList('students_list');

    if (savedStudents != null) {
      setState(() {
        _students = savedStudents
            .map((studentStr) => Student.fromStorageString(studentStr))
            .toList();
      });
    }
  }

  // Save data to phone storage
  Future<void> _saveStudents() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> studentsToSave = _students
        .map((student) => student.toStorageString())
        .toList();
    await prefs.setStringList('students_list', studentsToSave);
  }

  void _addStudent() async {
    String id = _idController.text.trim();
    String name = _nameController.text.trim();
    String course = _courseController.text.trim();

    if (id.isEmpty || name.isEmpty || course.isEmpty) {
      _showMessage('Please fill all fields (ID, Name, Course)', Colors.red);
      return;
    }

    bool idExists = _students.any((student) => student.id == id);
    if (idExists) {
      _showMessage('Student ID already exists! Use a unique ID', Colors.orange);
      return;
    }

    setState(() {
      _students.add(Student(id: id, name: name, course: course));
      _idController.clear();
      _nameController.clear();
      _courseController.clear();
    });

    await _saveStudents();
    _showMessage('Student added successfully!', Colors.green);
  }

  void _deleteStudent(int index) async {
    setState(() {
      _students.removeAt(index);
    });

    await _saveStudents();
    _showMessage('Student deleted successfully', Colors.orange);
  }

  void _showMessage(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Welcome, ${widget.studentName}!'),
        backgroundColor: Colors.blue,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.list),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DetailsScreen(students: _students),
                ),
              );
            },
            tooltip: 'View All Student Records',
          ),
        ],
      ),

      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Text(
                      'Add New Student',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _idController,
                      decoration: const InputDecoration(
                        labelText: 'Student ID',
                        hintText: 'e.g., STU001',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.numbers),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Full Name',
                        hintText: 'e.g., John Doe',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _courseController,
                      decoration: const InputDecoration(
                        labelText: 'Course',
                        hintText: 'e.g., Computer Science',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.book),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: _addStudent,
                      icon: const Icon(Icons.add),
                      label: const Text('Add Student'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 45),
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Student list - shows only when students exist
            Expanded(
              child: _students.isEmpty
                  ? Container()
                  : ListView.builder(
                itemCount: _students.length,
                itemBuilder: (context, index) {
                  final student = _students[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    elevation: 2,
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.blue[100],
                        child: Text(
                          student.id[0].toUpperCase(),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      title: Text(
                        student.name,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      subtitle: Text('ID: ${student.id} | Course: ${student.course}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteStudent(index),
                        tooltip: 'Delete Student',
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}