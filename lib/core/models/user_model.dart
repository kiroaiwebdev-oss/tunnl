class UserModel {
  final int    id;
  final String name;
  final String phone;
  final bool   isPremium;
  final String premiumExpiry;
  final int    totalXp;
  final int    currentStreak;
  final int    rankPosition;

  UserModel({
    required this.id, required this.name, required this.phone,
    required this.isPremium, required this.premiumExpiry,
    required this.totalXp, required this.currentStreak,
    required this.rankPosition,
  });

  factory UserModel.fromJson(Map<String, dynamic> j) => UserModel(
    id:             j['id']              ?? 0,
    name:           j['name']            ?? '',
    phone:          j['phone']           ?? '',
    isPremium:      j['is_premium']      == true,
    premiumExpiry:  j['premium_expiry']  ?? '',
    totalXp:        j['total_xp']        ?? 0,
    currentStreak:  j['current_streak']  ?? 0,
    rankPosition:   j['rank_position']   ?? 0,
  );
}
