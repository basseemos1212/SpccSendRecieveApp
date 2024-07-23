import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart' as intl;
import 'package:path/path.dart' as p;
import 'package:secret_contact/presentation/blocs/file_upload_bloc/file_upload_bloc.dart';
import 'package:secret_contact/presentation/blocs/file_upload_bloc/file_upload_event.dart';

class FileUploadScreen extends StatefulWidget {
  @override
  _FileUploadScreenState createState() => _FileUploadScreenState();
}

class _FileUploadScreenState extends State<FileUploadScreen> {
  final TextEditingController _fileNameController = TextEditingController();
  final TextEditingController _transactionNumberController =
      TextEditingController();
  final TextEditingController _incomingNumberController =
      TextEditingController();
  final TextEditingController _transactionDateController =
      TextEditingController();
  final TextEditingController _outgoingNumberController =
      TextEditingController();
  final TextEditingController _organizationNameController =
      TextEditingController();

  File? _selectedFile;
  List<Map<String, String>> uploadedFiles = [];
  List<String> suggestedNames = [];
  DateTime selectedDate = DateTime.now();
  bool showTransactionFields = true;
  bool showIncomingNumberField = true;
  bool showOutgoingNumberField = true;
  bool showOrganizationNameField = true;

  void _pickFile() async {
    final result = await FilePicker.platform.pickFiles();
    if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedFile = File(result.files.single.path!);
      });
      await _generateSuggestedNames();
    }
  }

  Future<void> _generateSuggestedNames() async {
    final fileCount = await _getFileCount();
    final currentMonth = DateTime.now().month;
    final currentYear = DateTime.now().year;
    final baseNumber = 4000 + fileCount;

    setState(() {
      suggestedNames = [
        '$baseNumber-$currentYear-$currentMonth-S',
        '$baseNumber-$currentYear-$currentMonth-R',
      ];
    });
  }

  Future<int> _getFileCount() async {
    final querySnapshot =
        await FirebaseFirestore.instance.collection('file_links').get();
    return querySnapshot.docs.length;
  }

  void _uploadFile() {
    if (_selectedFile != null && _fileNameController.text.isNotEmpty) {
      String extension = p.extension(_selectedFile!.path);
      String fullName = _fileNameController.text
              .trim()
              .replaceAll(RegExp(r'[^a-zA-Z0-9]'), '-') +
          extension;
      String formattedDate = intl.DateFormat('yyyy-MM-dd').format(selectedDate);
      BlocProvider.of<FileUploadBloc>(context).add(
        FileSelected(
          _selectedFile!,
          fullName,
          _transactionNumberController.text.trim(),
          _incomingNumberController.text.trim(),
          _transactionDateController.text.trim(),
          _outgoingNumberController.text.trim(),
          _organizationNameController.text.trim(),
          formattedDate,
        ),
      );

      setState(() {
        uploadedFiles.add({'name': fullName, 'path': _selectedFile!.path});
        _selectedFile = null;
        _fileNameController.clear();
        _transactionNumberController.clear();
        _incomingNumberController.clear();
        _transactionDateController.clear();
        _outgoingNumberController.clear();
        _organizationNameController.clear();
        suggestedNames.clear();
        showTransactionFields = true;
        showIncomingNumberField = true;
        showOutgoingNumberField = true;
        showOrganizationNameField = true;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء اختيار ملف وإدخال اسم الملف.')),
      );
    }
  }

  void _removeFile(int index) {
    setState(() {
      uploadedFiles.removeAt(index);
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2030),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
        _transactionDateController.text =
            intl.DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  void _handleSuggestedNameSelection(String name) {
    setState(() {
      _fileNameController.text = name;
      if (name.contains('-S')) {
        showTransactionFields = false;
        showIncomingNumberField = false;
        showOutgoingNumberField = true;
        showOrganizationNameField = false;
      } else if (name.contains('-R')) {
        showTransactionFields = true;
        showIncomingNumberField = true;
        showOutgoingNumberField = false;
        showOrganizationNameField = true;
      } else {
        showTransactionFields = true;
        showIncomingNumberField = true;
        showOutgoingNumberField = true;
        showOrganizationNameField = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('رفع ملف', style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.grey[900], // Dark mode app bar
        ),
        backgroundColor: Colors.black, // Dark mode background
        body: Padding(
          padding: const EdgeInsets.all(20.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  height: 200,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue),
                    color: Colors.grey[800],
                  ),
                  child: InkWell(
                    onTap: _pickFile,
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.cloud_upload, color: Colors.blue, size: 50),
                        SizedBox(height: 10),
                        Text(
                          'اختر ملف أو اسحبه هنا',
                          style: TextStyle(color: Colors.blue, fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                if (suggestedNames.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'الاقتراحات:',
                        style: TextStyle(color: Colors.white70),
                      ),
                      for (var name in suggestedNames)
                        ListTile(
                          title: Text(
                            name,
                            style: TextStyle(color: Colors.white),
                          ),
                          onTap: () {
                            _handleSuggestedNameSelection(name);
                          },
                        ),
                    ],
                  ),
                const SizedBox(height: 20),
                TextField(
                  controller: _fileNameController,
                  decoration: InputDecoration(
                    labelText: 'اسم الملف',
                    labelStyle: const TextStyle(color: Colors.white70),
                    enabledBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Colors.white24),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Colors.white70),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                  style: const TextStyle(color: Colors.white),
                  cursorColor: Colors.white70,
                ),
                const SizedBox(height: 20),
                if (showTransactionFields)
                  Column(
                    children: [
                      TextField(
                        controller: _transactionNumberController,
                        decoration: InputDecoration(
                          labelText: 'رقم المعاملة',
                          labelStyle: const TextStyle(color: Colors.white70),
                          enabledBorder: OutlineInputBorder(
                            borderSide: const BorderSide(color: Colors.white24),
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: const BorderSide(color: Colors.white70),
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                        ),
                        style: const TextStyle(color: Colors.white),
                        cursorColor: Colors.white70,
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: _transactionDateController,
                        readOnly: true,
                        decoration: InputDecoration(
                          labelText: 'تاريخ المعاملة',
                          labelStyle: const TextStyle(color: Colors.white70),
                          enabledBorder: OutlineInputBorder(
                            borderSide: const BorderSide(color: Colors.white24),
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: const BorderSide(color: Colors.white70),
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                        ),
                        style: const TextStyle(color: Colors.white),
                        cursorColor: Colors.white70,
                        onTap: () => _selectDate(context),
                      ),
                    ],
                  ),
                const SizedBox(height: 20),
                if (showIncomingNumberField)
                  TextField(
                    controller: _incomingNumberController,
                    decoration: InputDecoration(
                      labelText: 'رقم الوارد',
                      labelStyle: const TextStyle(color: Colors.white70),
                      enabledBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.white24),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.white70),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                    style: const TextStyle(color: Colors.white),
                    cursorColor: Colors.white70,
                  ),
                const SizedBox(height: 20),
                if (showOutgoingNumberField)
                  TextField(
                    controller: _outgoingNumberController,
                    decoration: InputDecoration(
                      labelText: 'رقم الصادر',
                      labelStyle: const TextStyle(color: Colors.white70),
                      enabledBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.white24),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.white70),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                    style: const TextStyle(color: Colors.white),
                    cursorColor: Colors.white70,
                  ),
                const SizedBox(height: 20),
                if (showOrganizationNameField)
                  TextField(
                    controller: _organizationNameController,
                    decoration: InputDecoration(
                      labelText: 'اسم الجهة',
                      labelStyle: const TextStyle(color: Colors.white70),
                      enabledBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.white24),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.white70),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                    style: const TextStyle(color: Colors.white),
                    cursorColor: Colors.white70,
                  ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  icon: const Icon(Icons.cloud_upload),
                  label: const Text('رفع الملف'),
                  onPressed: _uploadFile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green, // Button color
                    foregroundColor: Colors.white, // Text color
                  ),
                ),
                const SizedBox(height: 20),
                ListView.builder(
                  shrinkWrap: true,
                  itemCount: uploadedFiles.length,
                  itemBuilder: (context, index) {
                    var file = uploadedFiles[index];
                    return ListTile(
                      leading: const Icon(Icons.insert_drive_file,
                          color: Colors.blue),
                      title: Text(
                        file['name']!,
                        style: const TextStyle(color: Colors.white),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _removeFile(index),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
