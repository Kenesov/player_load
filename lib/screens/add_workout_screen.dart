import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/user_model.dart';
import '../models/workout_model.dart';
import '../services/workout_service.dart';

class AddWorkoutScreen extends StatefulWidget {
  final String coachUsername;
  final List<User> athletes;

  AddWorkoutScreen({required this.coachUsername, required this.athletes});

  @override
  _AddWorkoutScreenState createState() => _AddWorkoutScreenState();
}

class _AddWorkoutScreenState extends State<AddWorkoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _durationController = TextEditingController();

  List<User> _selectedAthletes = [];
  String _selectedType = 'strength';
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _startTime = TimeOfDay.now();
  TimeOfDay _endTime = TimeOfDay.now().replacing(hour: TimeOfDay.now().hour + 1);
  bool _isLoading = false;

  final List<String> _workoutTypes = [
    'strength',
    'cardio',
    'flexibility',
    'endurance',
    'recovery',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Mashg\'ulot qo\'shish'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    labelText: 'Mashg\'ulot nomi',
                    prefixIcon: Icon(Icons.fitness_center),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Mashg\'ulot nomini kiriting';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Tavsif',
                    prefixIcon: Icon(Icons.description),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Tavsifni kiriting';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),
                InkWell(
                  onTap: _selectDate,
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Sana',
                      prefixIcon: Icon(Icons.calendar_today),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      DateFormat('dd/MM/yyyy').format(_selectedDate),
                    ),
                  ),
                ),
                SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => _selectTime(true),
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'Boshlanish vaqti',
                            prefixIcon: Icon(Icons.access_time),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(_startTime.format(context)),
                        ),
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: InkWell(
                        onTap: () => _selectTime(false),
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'Tugash vaqti',
                            prefixIcon: Icon(Icons.access_time_filled),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(_endTime.format(context)),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: _durationController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Davomiyligi (daqiqa)',
                    prefixIcon: Icon(Icons.timer),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Davomiyligini kiriting';
                    }
                    if (int.tryParse(value) == null) {
                      return 'Raqam kiriting';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedType,
                  decoration: InputDecoration(
                    labelText: 'Mashg\'ulot turi',
                    prefixIcon: Icon(Icons.category),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: _workoutTypes.map((type) {
                    return DropdownMenuItem<String>(
                      value: type,
                      child: Text(_getWorkoutTypeName(type)),
                    );
                  }).toList(),
                  onChanged: (String? value) {
                    setState(() {
                      _selectedType = value!;
                    });
                  },
                ),
                SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: EdgeInsets.all(12),
                        child: Text(
                          'Sportchilarni tanlang',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      ...widget.athletes.map((athlete) {
                        return CheckboxListTile(
                          title: Text('${athlete.firstName} ${athlete.lastName}'),
                          subtitle: Text(athlete.username),
                          value: _selectedAthletes.contains(athlete),
                          onChanged: (bool? value) {
                            setState(() {
                              if (value == true) {
                                _selectedAthletes.add(athlete);
                              } else {
                                _selectedAthletes.remove(athlete);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ],
                  ),
                ),
                SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _addWorkout,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? CircularProgressIndicator(color: Colors.white)
                        : Text(
                      'Mashg\'ulot qo\'shish',
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getWorkoutTypeName(String type) {
    switch (type) {
      case 'strength':
        return 'Kuch';
      case 'cardio':
        return 'Kardio';
      case 'flexibility':
        return 'Egiluvchanlik';
      case 'endurance':
        return 'Chidamlilik';
      case 'recovery':
        return 'Tiklanish';
      default:
        return type;
    }
  }

  _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 365)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  _selectTime(bool isStartTime) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isStartTime ? _startTime : _endTime,
    );
    if (picked != null) {
      setState(() {
        if (isStartTime) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  _addWorkout() async {
    if (_formKey.currentState!.validate() && _selectedAthletes.isNotEmpty) {
      setState(() {
        _isLoading = true;
      });

      DateTime startDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _startTime.hour,
        _startTime.minute,
      );

      DateTime endDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _endTime.hour,
        _endTime.minute,
      );

      // Har bir tanlangan sportchi uchun alohida mashg'ulot yaratish
      for (User athlete in _selectedAthletes) {
        Workout newWorkout = Workout(
          id: '${DateTime.now().millisecondsSinceEpoch}_${athlete.username}',
          athleteUsername: athlete.username,
          title: _titleController.text,
          description: _descriptionController.text,
          date: _selectedDate,
          startTime: startDateTime,
          endTime: endDateTime,
          durationMinutes: int.parse(_durationController.text),
          type: _selectedType,
          athletes: _selectedAthletes.map((a) => widget.athletes.indexOf(a)).toList(),
        );

        await WorkoutService().addWorkout(newWorkout);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Mashg\'ulot(lar) muvaffaqiyatli qo\'shildi!'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);

      setState(() {
        _isLoading = false;
      });
    } else if (_selectedAthletes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Kamida bitta sportchini tanlang'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _durationController.dispose();
    super.dispose();
  }
}
