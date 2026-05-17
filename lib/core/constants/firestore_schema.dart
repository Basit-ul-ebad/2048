/// Firestore collection and field names — single source of truth for the app schema.
class FirestoreSchema {
  FirestoreSchema._();

  static const users = 'users';
  static const nicknameIndex = 'nickname_index';
  static const friendRequests = 'friend_requests';
  static const partyRooms = 'party_rooms';
  static const notifications = 'notifications';
  static const leaderboardGlobal = 'leaderboard';
  static const leaderboardDoc = 'global';
  static const topPlayers = 'topPlayers';

  static const subRuns = 'runs';
  static const subFriends = 'friends';
  static const subUserSkins = 'user_skins';
  static const skinOwnedDoc = 'owned';

  // users/{uid} fields
  static const nickname = 'nickname';
  static const email = 'email';
  static const highestScore = 'highestScore';
  static const currentLevel = 'currentLevel';
  static const exp = 'exp';
  static const coins = 'coins';
  static const rank = 'rank';
  static const wins = 'wins';
  static const losses = 'losses';
  static const friendsCount = 'friendsCount';
  static const totalGames = 'totalGames';
  static const highestTile = 'highestTile';
  static const favoriteSkin = 'favoriteSkin';
  static const isOnline = 'isOnline';
  static const createdAt = 'createdAt';
  static const lastSyncedAt = 'lastSyncedAt';

  // runs fields
  static const finalScore = 'finalScore';
  static const maxTile = 'maxTile';
  static const won = 'won';
  static const mode = 'mode';
}
