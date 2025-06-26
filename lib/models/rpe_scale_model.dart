class RPEScale {
  final int id;
  final int value;
  final String level;
  final String description;

  RPEScale({
    required this.id,
    required this.value,
    required this.level,
    required this.description,
  });

  factory RPEScale.fromJson(Map<String, dynamic> json) {
    return RPEScale(
      id: json['id'],
      value: json['value'],
      level: json['level'],
      description: json['description'],
    );
  }
}
