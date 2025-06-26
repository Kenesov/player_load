import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/training_session_model.dart';
import '../models/athlete_model.dart';
import '../services/training_service.dart';
import '../services/auth_service.dart';
import 'coach_statistics.dart';
import 'coach_profile.dart';
import 'coach_athletes.dart';
import 'add_training_session_screen.dart';

class CoachDashboard extends StatefulWidget {
  final User user;

  CoachDashboard({required this.user});

  @override
  _CoachDashboardState createState() => _CoachDashboardState();
}

class _CoachDashboardState extends State<CoachDashboard> {
  int _selectedIndex = 0;
  List<TrainingSession> _trainingSessions = [];
  List<Athlete> _athletes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final trainingSessions = await TrainingService().getTrainingSessions();
      final athletes = await AuthService().getAthletesByCoach(widget.user.username);

      // Faqat shu coach ga tegishli sessionlarni filter qilish
      final coachSessions = trainingSessions.where((session) =>
      session.coachId == widget.user.id
      ).toList();

      setState(() {
        _trainingSessions = coachSessions;
        _athletes = athletes;
        _isLoading = false;
      });
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
        title: Text('Murabbiy Dashboard'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: _getBody(),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
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
            icon: Icon(Icons.people),
            label: 'Sportchilar',
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
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddTrainingSessionScreen(
                coachId: widget.user.id,
                athletes: _athletes,
              ),
            ),
          ).then((_) => _loadData());
        },
        child: Icon(Icons.add),
        backgroundColor: Colors.blue,
      )
          : null,
    );
  }

  Widget _getBody() {
    switch (_selectedIndex) {
      case 0:
        return _buildDashboard();
      case 1:
        return CoachAthletes(user: widget.user);
      case 2:
        return CoachStatistics(user: widget.user);
      case 3:
        return CoachProfile(user: widget.user);
      default:
        return _buildDashboard();
    }
  }

  Widget _buildDashboard() {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: () async {
        await _loadData();
      },
      child: ListView(
        padding: EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Expanded(
                child: Card(
                  color: Colors.blue.shade50,
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Icon(Icons.people, size: 32, color: Colors.blue),
                        SizedBox(height: 8),
                        Text(
                          '${_athletes.length}',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                        Text('Sportchilar'),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Card(
                  color: Colors.green.shade50,
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Icon(Icons.fitness_center, size: 32, color: Colors.green),
                        SizedBox(height: 8),
                        Text(
                          '${_trainingSessions.length}',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        Text('Mashg\'ulotlar'),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
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
                    'So\'nggi mashg\'ulotlar',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 16),
                  if (_trainingSessions.isEmpty)
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
                            'Hozircha mashg\'ulotlar yo\'q',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    ..._trainingSessions.take(5).map((session) => _buildTrainingSessionCard(session)).toList(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrainingSessionCard(TrainingSession session) {
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
                    session.title,
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
            Text(
              'Sportchilar: ${session.athleteIds.length} ta',
              style: TextStyle(
                color: Colors.blue,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 4),
            if (session.description != null)
              Text(
                session.description!,
                style: TextStyle(color: Colors.grey[600]),
              ),
            SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.access_time, size: 16, color: Colors.grey),
                    SizedBox(width: 4),
                    Text('${session.durationMinutes} daqiqa'),
                    SizedBox(width: 16),
                    Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                    SizedBox(width: 4),
                    Text('${session.date.day}/${session.date.month}/${session.date.year}'),
                  ],
                ),
          ],
        ),
      ),
    );
  }
}
