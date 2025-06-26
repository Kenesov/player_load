import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/user_model.dart';
import '../services/training_service.dart';
import '../services/auth_service.dart';

class CoachStatistics extends StatefulWidget {
  final User user;

  CoachStatistics({required this.user});

  @override
  _CoachStatisticsState createState() => _CoachStatisticsState();
}

class _CoachStatisticsState extends State<CoachStatistics> {
  List<Map<String, dynamic>> _teamReportData = [];
  String _selectedPeriod = 'week';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReport();
  }

  _loadReport() async {
    setState(() {
      _isLoading = true;
    });

    try {
      print('Loading team report for period: $_selectedPeriod');

      // Sana oralig'ini hisoblash
      DateTime now = DateTime.now();
      DateTime startDate;

      switch (_selectedPeriod) {
        case 'day':
          startDate = DateTime(now.year, now.month, now.day);
          break;
        case 'week':
          startDate = now.subtract(Duration(days: now.weekday - 1));
          break;
        case 'month':
          startDate = DateTime(now.year, now.month, 1);
          break;
        case 'year':
          startDate = DateTime(now.year, 1, 1);
          break;
        default:
          startDate = now.subtract(Duration(days: 7));
      }

      // Coach ning athletelarini olish
      final athletes = await AuthService().getAthletesByCoach(widget.user.username);
      print('Found ${athletes.length} athletes for coach');

      List<Map<String, dynamic>> teamData = [];

      for (var athlete in athletes) {
        try {
          // Har bir athlete uchun ma'lumot olish
          final trainingSessions = await TrainingService().getTrainingSessionsForAthlete(athlete.id);
          final rpeRecords = await TrainingService().getRPERecordsForAthlete(athlete.id);

          // Sana filtri qo'llash
          final filteredTrainingSessions = trainingSessions.where((session) {
            return session.date.isAfter(startDate.subtract(Duration(days: 1)));
          }).toList();

          final filteredRPERecords = rpeRecords.where((record) {
            if (record.trainingDate == null) return false;
            return record.trainingDate!.isAfter(startDate.subtract(Duration(days: 1)));
          }).toList();

          // Statistika hisoblash
          int trainingCount = filteredTrainingSessions.length;
          int totalTime = filteredTrainingSessions.fold(0, (sum, session) => sum + session.durationMinutes);

          double avgRPE = 0.0;
          if (filteredRPERecords.isNotEmpty) {
            int totalRPE = filteredRPERecords.fold(0, (sum, record) => sum + record.rpeValue);
            avgRPE = totalRPE / filteredRPERecords.length;
          }

          teamData.add({
            'id': athlete.id,
            'athlete_name': '${athlete.user.firstName} ${athlete.user.lastName}',
            'training_count': trainingCount,
            'total_training_time': totalTime,
            'avg_rpe': avgRPE,
            'rpe_records_count': filteredRPERecords.length,
          });

          print('Athlete ${athlete.id}: $trainingCount trainings, ${totalTime}min, RPE: ${avgRPE.toStringAsFixed(1)}');
        } catch (e) {
          print('Error loading data for athlete ${athlete.id}: $e');
        }
      }

      print('Generated team report data: $teamData');

      setState(() {
        _teamReportData = teamData;
        _isLoading = false;
      });
    } catch (e) {
      print('Load team report error: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Statistika yuklanmoqda...'),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Jamoa statistikasi',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      DropdownButton<String>(
                        value: _selectedPeriod,
                        items: [
                          DropdownMenuItem(value: 'day', child: Text('Kunlik')),
                          DropdownMenuItem(value: 'week', child: Text('Haftalik')),
                          DropdownMenuItem(value: 'month', child: Text('Oylik')),
                          DropdownMenuItem(value: 'year', child: Text('Yillik')),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedPeriod = value!;
                          });
                          _loadReport();
                        },
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  _buildOverallStats(),
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
                    'Sportchilar bo\'yicha mashg\'ulotlar',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 20),
                  Container(
                    height: 200,
                    child: _buildAthleteStatsChart(),
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
                    'O\'rtacha RPE dinamikasi',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 20),
                  Container(
                    height: 200,
                    child: _buildRPETrendChart(),
                  ),
                ],
              ),
            ),
          ),

        ],
      ),
    );
  }

  Widget _buildOverallStats() {
    int totalTrainings = 0;
    int totalTime = 0;
    int activeAthletes = _teamReportData.length;
    double totalRPE = 0;
    int rpeCount = 0;

    for (var athlete in _teamReportData) {
      totalTrainings += (athlete['training_count'] ?? 0) as int;
      totalTime += (athlete['total_training_time'] ?? 0) as int;

      final avgRPE = athlete['avg_rpe'];
      if (avgRPE != null && avgRPE > 0) {
        totalRPE += (avgRPE is int ? avgRPE.toDouble() : avgRPE);
        rpeCount++;
      }
    }

    double avgRPE = rpeCount > 0 ? totalRPE / rpeCount : 0;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Jami mashg\'ulotlar',
                totalTrainings.toString(),
                Icons.fitness_center,
                Colors.blue,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Faol sportchilar',
                activeAthletes.toString(),
                Icons.people,
                Colors.green,
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Jami vaqt',
                '${totalTime}d',
                Icons.access_time,
                Colors.orange,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'O\'rtacha RPE',
                avgRPE.toStringAsFixed(1),
                Icons.trending_up,
                Colors.red,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAthleteStatsChart() {
    if (_teamReportData.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bar_chart, size: 48, color: Colors.grey),
            SizedBox(height: 8),
            Text('Ma\'lumotlar yo\'q', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    List<BarChartGroupData> barGroups = [];
    for (int i = 0; i < _teamReportData.length; i++) {
      final athlete = _teamReportData[i];
      final trainingCount = (athlete['training_count'] ?? 0).toDouble();

      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: trainingCount,
              color: Colors.blue,
              width: 20,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        ),
      );
    }

    double maxY = _teamReportData.isNotEmpty
        ? _teamReportData.map((e) => (e['training_count'] ?? 0).toDouble()).reduce((a, b) => a > b ? a : b) + 2
        : 10;

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY,
        barGroups: barGroups,
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: TextStyle(fontSize: 12),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() < _teamReportData.length) {
                  return Text(
                    'ID${_teamReportData[value.toInt()]['id']}',
                    style: TextStyle(fontSize: 10),
                  );
                }
                return Text('');
              },
            ),
          ),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        gridData: FlGridData(show: true),
      ),
    );
  }

  Widget _buildRPETrendChart() {
    List<FlSpot> spots = [];

    for (int i = 0; i < _teamReportData.length; i++) {
      final athlete = _teamReportData[i];
      final avgRPE = athlete['avg_rpe'] ?? 0;
      if (avgRPE > 0) {
        spots.add(FlSpot(i.toDouble(), (avgRPE is int ? avgRPE.toDouble() : avgRPE)));
      }
    }

    if (spots.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.show_chart, size: 48, color: Colors.grey),
            SizedBox(height: 8),
            Text('RPE ma\'lumotlari yo\'q', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return LineChart(
      LineChartData(
        gridData: FlGridData(show: true),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: TextStyle(fontSize: 12),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                return Text(
                  (value.toInt() + 1).toString(),
                  style: TextStyle(fontSize: 12),
                );
              },
            ),
          ),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: true),
        minX: 0,
        maxX: (spots.length - 1).toDouble(),
        minY: 0,
        maxY: 10,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: Colors.blue,
            barWidth: 3,
            dotData: FlDotData(show: true),
          ),
        ],
      ),
    );
  }


}
