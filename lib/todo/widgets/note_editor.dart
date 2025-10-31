import 'package:flutter/material.dart';
import 'due_date_picker.dart';

class NoteEditor extends StatefulWidget {
  final String? initialTitle;
  final String? initialContent;
  final DateTime? initialDueDate;
  final Function(String, String, DateTime?) onSave;

  const NoteEditor({
    super.key, 
    this.initialTitle, 
    this.initialContent,
    this.initialDueDate,
    required this.onSave
  });

  @override
  _NoteEditorState createState() => _NoteEditorState();
}

class _NoteEditorState extends State<NoteEditor> {
  late TextEditingController titleController;
  late TextEditingController contentController;
  DateTime? dueDate;

  @override
  void initState() {
    super.initState();
    titleController = TextEditingController(text: widget.initialTitle ?? '');
    contentController = TextEditingController(text: widget.initialContent ?? '');
    dueDate = widget.initialDueDate;
  }

  void _saveNote() {
    if (titleController.text.isNotEmpty) {
      widget.onSave(titleController.text, contentController.text, dueDate);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(Icons.arrow_back),
        ),
        title: Text(
          widget.initialTitle == null ? 'Новая заметка' : 'Редактирование',
        ),
        actions: [
          IconButton(
            onPressed: _saveNote,
            icon: Icon(Icons.save),
          ),
        ],
        backgroundColor: const Color.fromARGB(255, 10, 220, 181),
      ),
      backgroundColor: const Color.fromARGB(255, 254, 243, 243),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: titleController,
              decoration: InputDecoration(labelText: 'Заголовок'),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              maxLines: null,
            ),
            SizedBox(height: 16),
            DueDatePicker(
              initialDate: dueDate,
              onDateSelected: (date) {
                setState(() {
                  dueDate = date;
                });
              },
            ),
            Expanded(
              child: Container(
                alignment: Alignment.topLeft,
                child: TextField(
                  controller: contentController,
                  decoration: InputDecoration(
                    labelText: 'Текст заметки',
                    border: InputBorder.none,
                    hintText: 'Введите текст заметки...',
                    alignLabelWithHint: true,
                  ),
                  maxLines: null,
                  expands: true,
                  keyboardType: TextInputType.multiline,
                  textAlignVertical: TextAlignVertical.top,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    titleController.dispose();
    contentController.dispose();
    super.dispose();
  }
}