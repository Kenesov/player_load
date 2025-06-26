import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/training_session_model.dart';
import '../models/rpe_record_model.dart';
import '../models/athlete_model.dart';
import '../models/rpe_scale_model.dart';
import '../services/training_service.dart';
import '../services/auth_service.dart';
import 'athlete_statistics.dart';
import 'athlete_profile.dart';
import '../services/athlete_service.dart';
import '../widgets/rpe_rating_dialog.dart';

class AthleteDashboard extends StatefulWidget {
  final User user;

  AthleteDashboard({required this.user});

  @override
  _AthleteDashboardState createState() => _AthleteDashboardState();
}

class _AthleteDashboardState extends State<AthleteDashboard> with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  List<TrainingSession> _upcomingTrainings = [];
  List<RPERecord> _completedTrainings = [];
  bool _isLoading = true;
  late TabController _tabController;
  int? _athleteProfileId;
  List<RPEScale> _rpeScales = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadAthleteProfileAndData();
  }

  // Default RPE scales yaratish - faqat 1-10
  List<RPEScale> _createDefaultRPEScales() {
    return [
      RPEScale(id: 1, value: 1, level: 'Juda oson', description: 'Deyarli hech qanday kuch sarflamaysiz'),
      RPEScale(id: 2, value: 2, level: 'Oson', description: 'Juda kam kuch sarflaysiz'),
      RPEScale(id: 3, value: 3, level: 'Me\'yoriy', description: 'Kam kuch sarflaysiz'),
      RPEScale(id: 4, value: 4, level: 'Biroz qiyin', description: 'O\'rtacha kuch sarflaysiz'),
      RPEScale(id: 5, value: 5, level: 'Qiyin', description: 'Sezilarli kuch sarflaysiz'),
      RPEScale(id: 6, value: 6, level: 'Ancha qiyin', description: 'Ko\'p kuch sarflaysiz'),
      RPEScale(id: 7, value: 7, level: 'Juda qiyin', description: 'Juda ko\'p kuch sarflaysiz'),
      RPEScale(id: 8, value: 8, level: 'Charchatuvchi', description: 'Maksimal kuchingizga yaqin'),
      RPEScale(id: 9, value: 9, level: 'Juda charchatuvchi', description: 'Deyarli maksimal kuch'),
      RPEScale(id: 10, value: 10, level: 'Maksimal', description: 'Maksimal kuch sarflaysiz'),
    ];
  }

  _loadAthleteProfileAndData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      print('Loading athlete profile for user ID: ${widget.user.id}');

      Athlete? currentAthlete = await AthleteService().getMyProfile();

      if (currentAthlete == null) {
        print('My profile not found, trying with user ID...');
        currentAthlete = await AthleteService().getAthleteByUserId(widget.user.id);
      }

      if (currentAthlete == null) {
        print('Athlete not found via AthleteService, trying TrainingService...');
        _athleteProfileId = await TrainingService().getAthleteProfileIdByUserId(widget.user.id);
      } else {
        _athleteProfileId = currentAthlete.id;
      }

      if (_athleteProfileId != null) {
        print('Found athlete profile ID: $_athleteProfileId for user ID: ${widget.user.id}');
      } else {
        print('Athlete profile not found, using user ID as fallback');
        _athleteProfileId = widget.user.id;
      }

      await _loadData();
    } catch (e) {
      print('Load athlete profile error: $e');
      _athleteProfileId = widget.user.id;
      await _loadData();
    }
  }

  _loadData() async {
    if (_athleteProfileId == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      print('Loading data for athlete profile ID: $_athleteProfileId');

      final trainingSessions = await TrainingService().getTrainingSessionsForAthlete(_athleteProfileId!);
      final rpeRecords = await TrainingService().getRPERecordsForAthlete(_athleteProfileId!);
      final rpeScales = await TrainingService().getRPEScales();

      print('Loaded ${trainingSessions.length} training sessions');
      print('Loaded ${rpeRecords.length} RPE records');
      print('Loaded ${rpeScales.length} RPE scales');

      List<RPEScale> finalRPEScales = rpeScales.isEmpty ? _createDefaultRPEScales() : rpeScales;
      print('Using ${finalRPEScales.length} RPE scales (${rpeScales.isEmpty ? 'default' : 'from API'})');

      final upcomingTrainings = trainingSessions.where((session) {
        return !rpeRecords.any((record) => record.trainingSessionId == session.id);
      }).toList();

      setState(() {
        _upcomingTrainings = upcomingTrainings;
        _completedTrainings = rpeRecords;
        _rpeScales = finalRPEScales;
        _isLoading = false;
      });

      print('Found ${_upcomingTrainings.length} upcoming trainings');
      print('Found ${_completedTrainings.length} completed trainings');
    } catch (e) {
      print('Load data error: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Sportshi ${widget.user.firstName.isNotEmpty ? widget.user.firstName : widget.user.username}'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: _getBody(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Statistika',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }

  Widget _getBody() {
    switch (_selectedIndex) {
      case 0:
        return _buildDashboard();
      case 1:
        return AthleteStatistics(user: widget.user);
      case 2:
        return AthleteProfile(user: widget.user);
      default:
        return _buildDashboard();
    }
  }

  Widget _buildDashboard() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Ma\'lumotlar yuklanmoqda...'),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await _loadData();
      },
      child: Column(
        children: [
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: Colors.blue,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Colors.blue,
              tabs: [
                Tab(text: 'Endi bajaradigan (${_upcomingTrainings.length})'),
                Tab(text: 'Bajarib bo\'lingan (${_completedTrainings.length})'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildUpcomingTrainings(),
                _buildCompletedTrainings(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingTrainings() {
    return ListView(
      padding: EdgeInsets.all(16),
      children: [
        Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mashg\'ulotlar ro\'yxati',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 16),
                if (_upcomingTrainings.isEmpty)
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
                          'Hozircha yangi mashg\'ulotlar yo\'q',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Murabbiy sizga mashg\'ulot tayinlaganida bu yerda ko\'rinadi',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                else
                  ..._upcomingTrainings.map((training) => _buildUpcomingTrainingCard(training)).toList(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCompletedTrainings() {
    return ListView(
      padding: EdgeInsets.all(16),
      children: [
        Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bajarib bo\'lingan mashg\'ulotlar',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 16),
                if (_completedTrainings.isEmpty)
                  Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          size: 64,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Hozircha tugallangan mashg\'ulotlar yo\'q',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  ..._completedTrainings.map((record) => _buildCompletedTrainingCard(record)).toList(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUpcomingTrainingCard(TrainingSession training) {
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
                    training.title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'MASHG\'ULOT',
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
            if (training.description != null)
              Text(
                training.description!,
                style: TextStyle(color: Colors.grey[600]),
              ),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.access_time, size: 16, color: Colors.grey),
                SizedBox(width: 4),
                Text('${training.durationMinutes} daqiqa'),
                SizedBox(width: 16),
                Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                SizedBox(width: 4),
                Text('${training.date.day}/${training.date.month}/${training.date.year}'),
              ],
            ),
            SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _showCompleteTrainingDialog(training),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                child: Text('Mashg\'ulotni tugallash'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompletedTrainingCard(RPERecord record) {
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
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'TUGALLANGAN',
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
                    ? '${record.trainingDate!.day}/${record.trainingDate!.month}/${record.trainingDate!.year}'
                    : 'Noma\'lum sana'),
              ],
            ),
            SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'RPE baholash:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getRPEColor(record.rpeValue),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${record.rpeValue}/10',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
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

  _showCompleteTrainingDialog(TrainingSession training) {
    showDialog(
      context: context,
      builder: (context) {
        return RPERatingDialog(
          rpeScales: _rpeScales,
          onRatingSubmitted: (rpeValue, notes) async {
            await _completeTraining(training, rpeValue, notes);
          },
        );
      },
    );
  }

  _completeTraining(TrainingSession training, int rpeValue, String? notes) async {
    if (_athleteProfileId == null) return;

    try {
      print('Creating RPE record with value: $rpeValue');

      RPERecord record = RPERecord(
        athleteId: _athleteProfileId!,
        trainingSessionId: training.id,
        rpeValue: rpeValue, // Faqat 1-10 oralig'idagi qiymat
        notes: notes,
      );

      bool success = await TrainingService().createRPERecord(record);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Mashg\'ulot muvaffaqiyatli tugallandi!'),
            backgroundColor: Colors.green,
          ),
        );
        _loadData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Xatolik yuz berdi. Iltimos qaytadan urinib ko\'ring.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('Complete training error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Xatolik: Internetga ulanishni tekshiring'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
