import 'package:flutter/material.dart';
import '../models/rpe_scale_model.dart';

class RPERatingDialog extends StatefulWidget {
  final List<RPEScale> rpeScales;
  final Function(int rpeValue, String? notes) onRatingSubmitted;

  const RPERatingDialog({
    Key? key,
    required this.rpeScales,
    required this.onRatingSubmitted,
  }) : super(key: key);

  @override
  _RPERatingDialogState createState() => _RPERatingDialogState();
}

class _RPERatingDialogState extends State<RPERatingDialog> with TickerProviderStateMixin {
  int? selectedRPEValue;
  TextEditingController notesController = TextEditingController();
  late AnimationController _animationController;
  late AnimationController _pulseController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: Duration(milliseconds: 1500),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _animationController.forward();
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pulseController.dispose();
    notesController.dispose();
    super.dispose();
  }

  Color _getRPEColor(int value) {
    if (value <= 2) return Color(0xFF10B981); // Green
    if (value <= 4) return Color(0xFF84CC16); // Light Green
    if (value <= 6) return Color(0xFFF59E0B); // Yellow/Orange
    if (value <= 8) return Color(0xFFEF4444); // Red
    return Color(0xFF991B1B); // Dark Red
  }

  String _getRPEEmoji(int value) {
    switch (value) {
      case 1: return '😌';
      case 2: return '🙂';
      case 3: return '😊';
      case 4: return '😐';
      case 5: return '😅';
      case 6: return '😰';
      case 7: return '😵';
      case 8: return '🥵';
      case 9: return '😤';
      case 10: return '💀';
      default: return '🤔';
    }
  }

  String _getRPEDescription(int value) {
    switch (value) {
      case 1: return 'Juda oson';
      case 2: return 'Oson';
      case 3: return 'Me\'yoriy';
      case 4: return 'Biroz qiyin';
      case 5: return 'Qiyin';
      case 6: return 'Ancha qiyin';
      case 7: return 'Juda qiyin';
      case 8: return 'Charchatuvchi';
      case 9: return 'Maksimalga yaqin';
      case 10: return 'Maksimal';
      default: return 'Noma\'lum';
    }
  }

  String _getRPEDetailedDescription(int value) {
    switch (value) {
      case 1: return 'Deyarli hech qanday kuch sarflamaysiz';
      case 2: return 'Juda kam kuch sarflaysiz';
      case 3: return 'Kam kuch sarflaysiz';
      case 4: return 'O\'rtacha kuch sarflaysiz';
      case 5: return 'Sezilarli kuch sarflaysiz';
      case 6: return 'Ko\'p kuch sarflaysiz';
      case 7: return 'Juda ko\'p kuch sarflaysiz';
      case 8: return 'Maksimal kuchingizga yaqin';
      case 9: return 'Deyarli maksimal kuch';
      case 10: return 'Maksimal kuch sarflaysiz';
      default: return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Dialog(
              backgroundColor: Colors.transparent,
              elevation: 0,
              child: Container(
                constraints: BoxConstraints(maxWidth: 420, maxHeight: 650),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white,
                      Color(0xFFF8FAFC),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 30,
                      offset: Offset(0, 15),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    Container(
                      padding: EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFF667eea),
                            Color(0xFF764ba2),
                          ],
                        ),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(28),
                          topRight: Radius.circular(28),
                        ),
                      ),
                      child: Column(
                        children: [
                          AnimatedBuilder(
                            animation: _pulseAnimation,
                            builder: (context, child) {
                              return Transform.scale(
                                scale: _pulseAnimation.value,
                                child: Container(
                                  padding: EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.25),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.white.withOpacity(0.3),
                                        blurRadius: 20,
                                        spreadRadius: 5,
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    Icons.fitness_center,
                                    size: 48,
                                    color: Colors.white,
                                  ),
                                ),
                              );
                            },
                          ),
                          SizedBox(height: 20),
                          Text(
                            'Mashg\'ulotni baholang',
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Mashg\'ulot qanchalik qiyin bo\'ldi?',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white.withOpacity(0.9),
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Content
                    Flexible(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.all(28),
                        child: Column(
                          children: [
                            // RPE Scale Selection - faqat 1-10
                            Container(
                              padding: EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Color(0xFFE2E8F0),
                                  width: 1,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    'RPE Shkalasi (1-10)',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF475569),
                                    ),
                                  ),
                                  SizedBox(height: 20),

                                  // RPE Numbers Grid - faqat 1-10
                                  Wrap(
                                    spacing: 12,
                                    runSpacing: 12,
                                    children: List.generate(10, (index) {
                                      final rpeValue = index + 1; // 1 dan 10 gacha
                                      final isSelected = selectedRPEValue == rpeValue;

                                      return GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            selectedRPEValue = rpeValue;
                                          });
                                        },
                                        child: AnimatedContainer(
                                          duration: Duration(milliseconds: 300),
                                          curve: Curves.easeInOut,
                                          width: isSelected ? 60 : 50,
                                          height: isSelected ? 60 : 50,
                                          decoration: BoxDecoration(
                                            color: isSelected
                                                ? _getRPEColor(rpeValue)
                                                : _getRPEColor(rpeValue).withOpacity(0.2),
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: _getRPEColor(rpeValue),
                                              width: isSelected ? 3 : 2,
                                            ),
                                            boxShadow: isSelected ? [
                                              BoxShadow(
                                                color: _getRPEColor(rpeValue).withOpacity(0.4),
                                                blurRadius: 15,
                                                offset: Offset(0, 8),
                                              ),
                                            ] : [],
                                          ),
                                          child: Center(
                                            child: Text(
                                              '$rpeValue',
                                              style: TextStyle(
                                                fontSize: isSelected ? 20 : 16,
                                                fontWeight: FontWeight.bold,
                                                color: isSelected
                                                    ? Colors.white
                                                    : _getRPEColor(rpeValue),
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    }),
                                  ),

                                  SizedBox(height: 20),

                                  // Color Bar
                                  Container(
                                    height: 10,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(5),
                                      gradient: LinearGradient(
                                        colors: [
                                          Color(0xFF10B981), // 1-2
                                          Color(0xFF84CC16), // 3-4
                                          Color(0xFFF59E0B), // 5-6
                                          Color(0xFFEF4444), // 7-8
                                          Color(0xFF991B1B), // 9-10
                                        ],
                                      ),
                                    ),
                                  ),

                                  SizedBox(height: 12),

                                  // Labels
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Oson',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Color(0xFF64748B),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        'Qiyin',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Color(0xFF64748B),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            // Selected RPE Description
                            if (selectedRPEValue != null) ...[
                              SizedBox(height: 24),
                              AnimatedContainer(
                                duration: Duration(milliseconds: 400),
                                padding: EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      _getRPEColor(selectedRPEValue!).withOpacity(0.1),
                                      _getRPEColor(selectedRPEValue!).withOpacity(0.05),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: _getRPEColor(selectedRPEValue!).withOpacity(0.3),
                                    width: 2,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Container(
                                          padding: EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: _getRPEColor(selectedRPEValue!).withOpacity(0.2),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Text(
                                            _getRPEEmoji(selectedRPEValue!),
                                            style: TextStyle(fontSize: 36),
                                          ),
                                        ),
                                        SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'RPE ${selectedRPEValue!}',
                                                style: TextStyle(
                                                  fontSize: 24,
                                                  fontWeight: FontWeight.bold,
                                                  color: _getRPEColor(selectedRPEValue!),
                                                ),
                                              ),
                                              Text(
                                                _getRPEDescription(selectedRPEValue!),
                                                style: TextStyle(
                                                  fontSize: 18,
                                                  color: Color(0xFF64748B),
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 16),
                                    Container(
                                      padding: EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.7),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        _getRPEDetailedDescription(selectedRPEValue!),
                                        style: TextStyle(
                                          fontSize: 15,
                                          color: Color(0xFF374151),
                                          height: 1.5,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],

                            SizedBox(height: 24),

                            // Notes Input
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Color(0xFFE2E8F0),
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 10,
                                    offset: Offset(0, 4),
                                  ),
                                ],
                              ),
                            ),

                            SizedBox(height: 32),

                            // Action Buttons
                            Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    height: 56,
                                    child: TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      style: TextButton.styleFrom(
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(16),
                                          side: BorderSide(
                                            color: Color(0xFFE2E8F0),
                                            width: 2,
                                          ),
                                        ),
                                        backgroundColor: Colors.white,
                                      ),
                                      child: Text(
                                        'Bekor qilish',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Color(0xFF64748B),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(width: 16),
                                Expanded(
                                  flex: 2,
                                  child: Container(
                                    height: 56,
                                    decoration: BoxDecoration(
                                      gradient: selectedRPEValue != null
                                          ? LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          _getRPEColor(selectedRPEValue!),
                                          _getRPEColor(selectedRPEValue!).withOpacity(0.8),
                                        ],
                                      )
                                          : LinearGradient(
                                        colors: [Color(0xFFE2E8F0), Color(0xFFE2E8F0)],
                                      ),
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: selectedRPEValue != null ? [
                                        BoxShadow(
                                          color: _getRPEColor(selectedRPEValue!).withOpacity(0.4),
                                          blurRadius: 12,
                                          offset: Offset(0, 6),
                                        ),
                                      ] : [],
                                    ),
                                    child: ElevatedButton(
                                      onPressed: selectedRPEValue != null
                                          ? () {
                                        widget.onRatingSubmitted(
                                          selectedRPEValue!,
                                          notesController.text.isEmpty
                                              ? null
                                              : notesController.text,
                                        );
                                        Navigator.pop(context);
                                      }
                                          : null,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.transparent,
                                        shadowColor: Colors.transparent,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                      ),
                                      child: Center(
                                        child: Text(
                                          'Baholashni saqlash',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: selectedRPEValue != null
                                                ? Colors.white
                                                : Color(0xFF9CA3AF),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
