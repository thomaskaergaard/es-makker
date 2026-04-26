// Player model
class Player {
  final String name;

  const Player({required this.name});

  Player copyWith({String? name}) {
    return Player(name: name ?? this.name);
  }

  Map<String, dynamic> toJson() => {'name': name};

  factory Player.fromJson(Map<String, dynamic> json) =>
      Player(name: json['name'] as String);

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Player && name == other.name;

  @override
  int get hashCode => name.hashCode;

  @override
  String toString() => 'Player(name: $name)';
}
