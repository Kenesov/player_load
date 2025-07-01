import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/athlete_model.dart';
import '../models/rpe_record_model.dart';
import '../services/training_service.dart';
import '../widgets/profile_avatar.dart';
import 'athlete_statistics.dart';

class AthleteDetailScreen extends StatefulWidget {
  final Athlete athlete;

  AthleteDetailScreen({Key? key, required this.athlete}) : super(key: key);

  @override
  _AthleteDetailScreenState createState() => _AthleteDetailScreenState();
}

class _AthleteDetailScreenState extends State<AthleteDetailScreen> {
  List<RPERecord> _rpeRecords = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRPERecords();
  }

  _loadRPERecords() async {
    setState(() {
      _isLoading = true;
    });

    try {
      List<RPERecord> records = await TrainingService().getRPERecordsForAthlete(widget.athlete.id);
      setState(() {
        _rpeRecords = records;
        _isLoading = false;
      });
    } catch (e) {
      print('Load RPE records error: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.athlete.user.firstName} ${widget.athlete.user.lastName}'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  children: [
                    ProfileAvatar(
                      profilePicture: widget.athlete.user.profilePicture,
                      firstName: widget.athlete.user.firstName,
                      lastName: widget.athlete.user.lastName,
                      username: widget.athlete.user.username,
                      radius: 50,
                    ),
                    SizedBox(height: 16),
                    Text(
                      '${widget.athlete.user.firstName} ${widget.athlete.user.lastName}',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'SPORTCHI',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                  ],
                ),
              ),
            ),
            SizedBox(height: 16),
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Shaxsiy ma\'lumotlar',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 16),
                    _buildInfoRow(Icons.person, 'Username', widget.athlete.user.username),
                    _buildInfoRow(Icons.email, 'Email', widget.athlete.user.email.isNotEmpty ? widget.athlete.user.email : 'Kiritilmagan'),
                    if (widget.athlete.user.phoneNumber != null && widget.athlete.user.phoneNumber!.isNotEmpty)
                      _buildInfoRow(Icons.phone, 'Telefon', widget.athlete.user.phoneNumber!),
                    if (widget.athlete.user.dateOfBirth != null)
                      _buildInfoRow(
                        Icons.cake,
                        'Tug\'ilgan sana',
                        DateFormat('dd/MM/yyyy').format(widget.athlete.user.dateOfBirth!),
                      ),
                    if (widget.athlete.sport != null && widget.athlete.sport!.isNotEmpty)
                      _buildInfoRow(Icons.sports, 'Sport turi', widget.athlete.sport!),
                    if (widget.athlete.team != null && widget.athlete.team!.isNotEmpty)
                      _buildInfoRow(Icons.group, 'Jamoa', widget.athlete.team!),
                    if (widget.athlete.weight != null)
                      _buildInfoRow(Icons.monitor_weight, 'Vazn', '${widget.athlete.weight} kg'),
                    if (widget.athlete.height != null)
                      _buildInfoRow(Icons.height, 'Bo\'y', '${widget.athlete.height} cm'),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'RPE Yozuvlari',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 16),
                    if (_rpeRecords.isEmpty)
                      Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons.fitness_center,
                              size: 64,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Hozircha RPE yozuvlari yo\'q',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      ..._rpeRecords.take(5).map((record) => _buildRPERecordCard(record)).toList(),
                    if (_rpeRecords.length > 5)
                      TextButton(
                        onPressed: () {
                          // Barcha RPE yozuvlarini ko'rsatish
                        },
                        child: Text('Barchasini ko\'rish'),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey[600]),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRPERecordCard(RPERecord record) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    record.trainingTitle ?? 'Mashg\'ulot',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getRPEColor(record.rpeValue),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'RPE: ${record.rpeValue}',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            if (record.notes != null && record.notes!.isNotEmpty)
              Text(
                record.notes!,
                style: TextStyle(color: Colors.grey[600]),
              ),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                SizedBox(width: 4),
                Text(record.trainingDate != null
                    ? DateFormat('dd/MM/yyyy').format(record.trainingDate!)
                    : 'Noma\'lum sana'),
                if (record.recordedAt != null) ...[
                  SizedBox(width: 16),
                  Icon(Icons.access_time, size: 16, color: Colors.grey),
                  SizedBox(width: 4),
                  Text(DateFormat('HH:mm').format(record.recordedAt!)),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getRPEColor(int rpe) {
    if (rpe <= 3) return Colors.green;
    if (rpe <= 6) return Colors.orange;
    return Colors.red;
  }
}
