// No imports needed for this class

class Activity {
  final String label;
  final String icon;
  final String category;

  const Activity({
    required this.label,
    required this.icon,
    required this.category,
  });
}

class UniversityActivities {
  static const List<Activity> sports = [
    Activity(label: 'Cricket', icon: '🏏', category: 'Sports'),
    Activity(label: 'Football', icon: '⚽', category: 'Sports'),
    Activity(label: 'Badminton', icon: '🏸', category: 'Sports'),
    Activity(label: 'Basketball', icon: '🏀', category: 'Sports'),
    Activity(label: 'Table Tennis', icon: '🏓', category: 'Sports'),
    Activity(label: 'Swimming', icon: '🏊', category: 'Sports'),
    Activity(label: 'Squash', icon: '🎾', category: 'Sports'),
    Activity(label: 'E-Sports', icon: '🎮', category: 'Sports'),
  ];

  static const List<Activity> societies = [
    Activity(label: 'SOCA Media', icon: '🎥', category: 'Societies'),
    Activity(label: 'IEEE Tech', icon: '🤖', category: 'Societies'),
    Activity(label: 'Debating', icon: '🗣️', category: 'Societies'),
    Activity(label: 'Dramatic Club', icon: '🎭', category: 'Societies'),
    Activity(label: 'Music Society', icon: '🎸', category: 'Societies'),
    Activity(label: 'Literary Society', icon: '📚', category: 'Societies'),
    Activity(label: 'V-Gems Events', icon: '💎', category: 'Societies'),
    Activity(label: 'Blood Donors', icon: '🩸', category: 'Societies'),
  ];

  static const List<Activity> interests = [
    Activity(label: 'Photography', icon: '📸', category: 'Interests'),
    Activity(label: 'Art & Design', icon: '🎨', category: 'Interests'),
    Activity(label: 'Coding', icon: '💻', category: 'Interests'),
    Activity(label: 'Traveling', icon: '✈️', category: 'Interests'),
    Activity(label: 'Reading', icon: '📖', category: 'Interests'),
    Activity(label: 'Fitness', icon: '🏋️‍♂️', category: 'Interests'),
  ];

  static List<Activity> get all => [...sports, ...societies, ...interests];

  static Activity? fromLabel(String label) {
    try {
      return all.firstWhere((a) => a.label == label);
    } catch (_) {
      return null;
    }
  }
}
