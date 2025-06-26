import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/athlete_model.dart';
import '../services/auth_service.dart';
import '../widgets/profile_avatar.dart';
import 'add_athlete_screen.dart';
import 'athlete_detail_screen.dart';

class CoachAthletes extends StatefulWidget {
  final User user;

  CoachAthletes({required this.user});

  @override
  _CoachAthletesState createState() => _CoachAthletesState();
}

class _CoachAthletesState extends State<CoachAthletes> {
  List<Athlete> _athletes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAthletes();
  }

  _loadAthletes() async {
    setState(() {
      _isLoading = true;
    });

    try {
      List<Athlete> athletes = await AuthService().getAthletesByCoach(widget.user.username);
      setState(() {
        _athletes = athletes;
        _isLoading = false;
      });
    } catch (e) {
      print('Load athletes error: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: () async {
          await _loadAthletes();
        },
        child: ListView(
          padding: EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sportchilar ro\'yxati',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Jami: ${_athletes.length} ta sportchi',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AddAthleteScreen(
                              coachId: widget.user.id,
                            ),
                          ),
                        ).then((_) {
                          // Athlete qo'shgandan keyin ro'yxatni yangilash
                          print('Returning from add athlete screen, refreshing list...');
                          _loadAthletes();
                        });
                      },
                      icon: Icon(Icons.add),
                      label: Text('Qo\'shish'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),
            if (_athletes.isEmpty)
              Card(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 64,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Hozircha sportchilar yo\'q',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Yangi sportchi qo\'shish uchun yuqoridagi tugmani bosing',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              ..._athletes.map((athlete) => _buildAthleteCard(athlete)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildAthleteCard(Athlete athlete) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: ProfileAvatar(
          profilePicture: athlete.user.profilePicture,
          firstName: athlete.user.firstName,
          lastName: athlete.user.lastName,
          username: athlete.user.username,
          radius: 25,
        ),
        title: Text(
          '${athlete.user.firstName} ${athlete.user.lastName}',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(athlete.user.email.isNotEmpty ? athlete.user.email : athlete.user.username),
            if (athlete.user.phoneNumber != null && athlete.user.phoneNumber!.isNotEmpty)
              Text(athlete.user.phoneNumber!),
            if (athlete.sport != null && athlete.sport!.isNotEmpty)
              Container(
                margin: EdgeInsets.only(top: 4),
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  athlete.sport!,
                  style: TextStyle(
                    color: Colors.green,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        trailing: Icon(Icons.arrow_forward_ios),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AthleteDetailScreen(athlete: athlete),
            ),
          );
        },
      ),
    );
  }
}
