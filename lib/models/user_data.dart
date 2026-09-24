class UserData {
  final String name;
  final double weight;
  final double height;
  final int reminderMinutes;

  UserData({
    this.name = '',
    required this.weight,
    required this.height,
    required this.reminderMinutes,
  });

  String get initials {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return 'U';
    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length == 1) {
      return parts[0].substring(0, 1).toUpperCase();
    }
    return (parts[0].substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
  }
}
