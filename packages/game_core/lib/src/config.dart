import 'coord.dart';

/// Oyunun yapılandırılabilir sayıları. `docs/rules.md` §8 ile birebir.
///
/// `game_core` bu değerleri asla sabit yazmaz; her zaman bir [GameConfig]
/// örneğinden okur. Böylece playtest'te tahta boyutu / cephanelik gibi
/// sayılar tek yerden değişir.
class GameConfig {
  const GameConfig({
    this.boardSize = 7,
    this.armoryPoints = 8,
    this.mineCost = 1,
    this.wireCost = 2,
    this.startP1 = const Square(3, 0), // d1
    this.startP2 = const Square(3, 6), // d7
    this.obstacleCountMin = 0,
    this.obstacleCountMax = 0,
  });

  /// Kare tahtanın kenar uzunluğu (kare sayısı).
  final int boardSize;

  /// Oyuncu başına toplam engel puanı.
  final int armoryPoints;

  /// Bir mayının cephanelik maliyeti.
  final int mineCost;

  /// Bir dikenli telin cephanelik maliyeti.
  final int wireCost;

  /// Oyuncu 1 (Mavi) başlangıç karesi. Hedefi: en üst satır.
  final Square startP1;

  /// Oyuncu 2 (Kırmızı) başlangıç karesi. Hedefi: en alt satır.
  final Square startP2;

  /// Oyun başında konan kare-kapatan engel (`docs/rules.md` §2.1) sayısının
  /// alt/üst sınırı. `0/0` → engel karesi yok (v1). Üretim `ObstacleField.roll`.
  final int obstacleCountMin;
  final int obstacleCountMax;

  /// v1 varsayılan yapılandırması (7×7, 8 puan, engel karesi yok).
  static const GameConfig v1 = GameConfig();

  /// "Geniş Arazi" — 9×9, oyuncu başına 11 puan, `e1`/`e9` başlangıç, oyun
  /// başında 2–4 rastgele ağaç (§2.1). Arayüzde karlı savaş alanı teması.
  static const GameConfig wideTerrain = GameConfig(
    boardSize: 9,
    armoryPoints: 11,
    startP1: Square(4, 0), // e1
    startP2: Square(4, 8), // e9
    obstacleCountMin: 2,
    obstacleCountMax: 4,
  );

  /// Bir engel tipinin maliyeti.
  int costOf(bool isWire) => isWire ? wireCost : mineCost;

  /// Geçerli kare indeks aralığı: `0 <= i < boardSize`.
  bool isSquareInBounds(Square s) =>
      s.col >= 0 && s.col < boardSize && s.row >= 0 && s.row < boardSize;

  /// Geçerli pivot indeks aralığı: `0 <= i < boardSize - 1` (yani a–f × 1–6).
  bool isPivotInBounds(Square p) =>
      p.col >= 0 && p.col < boardSize - 1 && p.row >= 0 && p.row < boardSize - 1;

  GameConfig copyWith({
    int? boardSize,
    int? armoryPoints,
    int? mineCost,
    int? wireCost,
    Square? startP1,
    Square? startP2,
    int? obstacleCountMin,
    int? obstacleCountMax,
  }) {
    return GameConfig(
      boardSize: boardSize ?? this.boardSize,
      armoryPoints: armoryPoints ?? this.armoryPoints,
      mineCost: mineCost ?? this.mineCost,
      wireCost: wireCost ?? this.wireCost,
      startP1: startP1 ?? this.startP1,
      startP2: startP2 ?? this.startP2,
      obstacleCountMin: obstacleCountMin ?? this.obstacleCountMin,
      obstacleCountMax: obstacleCountMax ?? this.obstacleCountMax,
    );
  }

  Map<String, dynamic> toJson() => {
        'boardSize': boardSize,
        'armoryPoints': armoryPoints,
        'mineCost': mineCost,
        'wireCost': wireCost,
        'startP1': startP1.toString(),
        'startP2': startP2.toString(),
        'obstacleCountMin': obstacleCountMin,
        'obstacleCountMax': obstacleCountMax,
      };

  factory GameConfig.fromJson(Map<String, dynamic> json) => GameConfig(
        boardSize: json['boardSize'] as int,
        armoryPoints: json['armoryPoints'] as int,
        mineCost: json['mineCost'] as int,
        wireCost: json['wireCost'] as int,
        startP1: Square.parse(json['startP1'] as String),
        startP2: Square.parse(json['startP2'] as String),
        obstacleCountMin: json['obstacleCountMin'] as int? ?? 0,
        obstacleCountMax: json['obstacleCountMax'] as int? ?? 0,
      );
}
