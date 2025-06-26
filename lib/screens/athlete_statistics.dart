import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/user_model.dart';
import '../services/training_service.dart';
import '../services/athlete_service.dart';

class AthleteStatistics extends StatefulWidget {
  final User user;

  AthleteStatistics({required this.user});

  @override
  _AthleteStatisticsState createState() => _AthleteStatisticsState();
}

class _AthleteStatisticsState extends State<AthleteStatistics> {
  Map<String, dynamic>? _reportData;
  String _selectedPeriod = 'week';
  bool _isLoading = true;
  int? _athleteProfileId;

  @override
  void initState() {
    super.initState();
    _loadAthleteProfile();
  }

  _loadAthleteProfile() async {
    try {
      // Athlete profile ID ni topish
      final athlete = await AthleteService().getAthleteByUserId(widget.user.id);
      if (athlete != null) {
        _athleteProfileId = athlete.id;
        print('Found athlete profile ID: $_athleteProfileId');
        _loadReport();
      } else {
        print('Athlete profile not found, using user ID as fallback');
        _athleteProfileId = widget.user.id;
        _loadReport();
      }
    } catch (e) {
      print('Load athlete profile error: $e');
      _athleteProfileId = widget.user.id;
      _loadReport();
    }
  }

  _loadReport() async {
    if (_athleteProfileId == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      print('Loading athlete report for athlete ID: $_athleteProfileId, period: $_selectedPeriod');

      // TrainingService dan to'g'ridan-to'g'ri ma'lumot olish
      final trainingSessions = await TrainingService().getTrainingSessionsForAthlete(_athleteProfileId!);
      final rpeRecords = await TrainingService().getRPERecordsForAthlete(_athleteProfileId!);

      print('Loaded ${trainingSessions.length} training sessions');
      print('Loaded ${rpeRecords.length} RPE records');

      // Sana filtri qo'llash
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

      // Filtrlangan ma'lumotlar
      final filteredRPERecords = rpeRecords.where((record) {
        if (record.trainingDate == null) return false;
        return record.trainingDate!.isAfter(startDate.subtract(Duration(days: 1)));
      }).toList();

      final filteredTrainingSessions = trainingSessions.where((session) {
        return session.date.isAfter(startDate.subtract(Duration(days: 1)));
      }).toList();

      // Statistika hisoblash
      int trainingCount = filteredTrainingSessions.length;
      int totalTime = filteredTrainingSessions.fold(0, (sum, session) => sum + session.durationMinutes);

      double avgRPE = 0.0;
      if (filteredRPERecords.isNotEmpty) {
        int totalRPE = filteredRPERecords.fold(0, (sum, record) => sum + record.rpeValue);
        avgRPE = totalRPE / filteredRPERecords.length;
      }

      // Report data yaratish
      Map<String, dynamic> reportData = {
        'training_count': trainingCount,
        'total_training_time': totalTime,
        'avg_rpe': avgRPE,
        'rpe_records': filteredRPERecords.map((record) => {
          'rpe_value': record.rpeValue,
          'training_title': record.trainingTitle ?? 'Mashg\'ulot',
          'training_date': record.trainingDate?.toIso8601String().split('T')[0],
          'notes': record.notes,
        }).toList(),
      };

      print('Generated report data: $reportData');

      setState(() {
        _reportData = reportData;
        _isLoading = false;
      });
    } catch (e) {
      print('Load report error: $e');
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

    if (_reportData == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Ma\'lumotlar yuklanmadi',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadReport,
              child: Text('Qayta urinish'),
            ),
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
                        'Statistika',
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
                  _buildStatCards(),
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
                    'RPE Ma\'lumotlari',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 20),
                  Container(
                    height: 200,
                    child: _buildRPEChart(),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 16),
          _buildDetailedStats(),
        ],
      ),
    );
  }

  Widget _buildStatCards() {
    final trainingCount = _reportData!['training_count'] ?? 0;
    final totalTime = _reportData!['total_training_time'] ?? 0;
    final avgRPE = _reportData!['avg_rpe'] ?? 0.0;
    final rpeRecords = _reportData!['rpe_records'] as List<dynamic>? ?? [];

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Mashg\'ulotlar',
                trainingCount.toString(),
                Icons.fitness_center,
                Colors.blue,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Jami vaqt',
                '${totalTime}d',
                Icons.access_time,
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
                'O\'rtacha RPE',
                avgRPE.toStringAsFixed(1),
                Icons.trending_up,
                Colors.orange,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'RPE yozuvlari',
                rpeRecords.length.toString(),
                Icons.assignment,
                Colors.purple,
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

  Widget _buildRPEChart() {
    final rpeRecords = _reportData!['rpe_records'] as List<dynamic>? ?? [];

    if (rpeRecords.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.show_chart, size: 48, color: Colors.grey),
            SizedBox(height: 8),
            Text(
              'RPE ma\'lumotlari yo\'q',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    List<FlSpot> spots = [];
    for (int i = 0; i < rpeRecords.length; i++) {
      final record = rpeRecords[i];
      final rpeValue = record['rpe_value'] ?? 0;
      spots.add(FlSpot(i.toDouble(), rpeValue.toDouble()));
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
        maxX: (rpeRecords.length - 1).toDouble(),
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

  Widget _buildDetailedStats() {
    final rpeRecords = _reportData!['rpe_records'] as List<dynamic>? ?? [];

    if (rpeRecords.isEmpty) {
      return Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(
            child: Column(
              children: [
                Icon(Icons.info_outline, size: 48, color: Colors.grey),
                SizedBox(height: 8),
                Text(
                  'Hozircha ma\'lumotlar yo\'q',
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),
                SizedBox(height: 8),
                Text(
                  'Mashg\'ulotlarni tugallab, RPE baholash qiling',
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'So\'nggi RPE yozuvlari',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            ...rpeRecords.take(5).map((record) => _buildRPERecordItem(record)).toList(),
            if (rpeRecords.length > 5)
              TextButton(
                onPressed: () {
                  // Show all records
                },
                child: Text('Barchasini ko\'rish'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRPERecordItem(Map<String, dynamic> record) {
    final rpeValue = record['rpe_value'] ?? 0;
    final trainingTitle = record['training_title'] ?? 'Mashg\'ulot';
    final trainingDate = record['training_date'];

    return Container(
      margin: EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _getRPEColor(rpeValue),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              rpeValue.toString(),
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  trainingTitle,
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                if (trainingDate != null)
                  Text(
                    trainingDate,
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getRPEColor(int rpe) {
    if (rpe <= 3) return Colors.green;
    if (rpe <= 6) return Colors.orange;
    return Colors.red;
  }
}
