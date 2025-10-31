import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:app_todo/models/user_model.dart';

class EditProfileScene extends StatefulWidget {
  final User user;
  final Function(User) onProfileUpdated;

  const EditProfileScene({
    super.key,
    required this.user,
    required this.onProfileUpdated,
  });

  @override
  _EditProfileSceneState createState() => _EditProfileSceneState();
}

class _EditProfileSceneState extends State<EditProfileScene> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _aboutController;
  late TextEditingController _skillController;
  late List<String> _skills;
  String? _photoPath;
  bool _hideEmail = false;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.name);
    _emailController = TextEditingController(text: widget.user.email);
    _aboutController = TextEditingController(text: widget.user.about ?? '');
    _skillController = TextEditingController();
    _skills = List.from(widget.user.skills);
    _photoPath = widget.user.photoPath;
    _hideEmail = widget.user.hideEmail ?? false;
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _photoPath = image.path;
      });
    }
  }

  void _addSkill() {
    final skill = _skillController.text.trim();
    if (skill.isNotEmpty && !_skills.contains(skill)) {
      setState(() {
        _skills.add(skill);
        _skillController.clear();
      });
    }
  }

  void _removeSkill(String skill) {
    setState(() {
      _skills.remove(skill);
    });
  }

  void _saveProfile() {
    final updatedUser = widget.user.copyWith(
      name: _nameController.text,
      email: _emailController.text,
      about: _aboutController.text.isNotEmpty ? _aboutController.text : null,
      skills: _skills,
      photoPath: _photoPath,
      hideEmail: _hideEmail,
    );

    widget.onProfileUpdated(updatedUser);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Редактировать профиль'),
        backgroundColor: const Color.fromARGB(255, 10, 220, 181),
        actions: [
          IconButton(
            icon: Icon(Icons.save),
            onPressed: _saveProfile,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: CircleAvatar(
                radius: 50,
                backgroundImage: _photoPath != null
                    ? FileImage(File(_photoPath!)) as ImageProvider
                    : AssetImage('assets/images/test1.jpg'),
                child: Stack(
                  children: [
                    if (_photoPath == null)
                      Container(
                        color: Colors.black54,
                        child: Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),

            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Имя',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
            ),
            SizedBox(height: 16),

            TextFormField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            SizedBox(height: 16),

            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.visibility, color: Colors.grey[600]),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Скрыть email в профиле',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Switch(
                    value: _hideEmail,
                    onChanged: (value) {
                      setState(() {
                        _hideEmail = value;
                      });
                    },
                    activeColor: const Color.fromARGB(255, 10, 220, 181),
                    activeTrackColor: const Color.fromARGB(255, 10, 220, 181).withOpacity(0.5),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),

            // Поле "О себе"
            TextFormField(
              controller: _aboutController,
              decoration: InputDecoration(
                labelText: 'О себе',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 3,
            ),
            SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _skillController,
                    decoration: InputDecoration(
                      labelText: 'Добавить навык',
                      border: OutlineInputBorder(),
                    ),
                    onFieldSubmitted: (_) => _addSkill(),
                  ),
                ),
                SizedBox(width: 8),
                IconButton(
                  icon: Icon(Icons.add),
                  onPressed: _addSkill,
                ),
              ],
            ),
            SizedBox(height: 8),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _skills.map((skill) => Chip(
                label: Text(skill),
                deleteIcon: Icon(Icons.close, size: 16),
                onDeleted: () => _removeSkill(skill),
              )).toList(),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _aboutController.dispose();
    _skillController.dispose();
    super.dispose();
  }
}