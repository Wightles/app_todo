class User {
  String name;
  String email;
  String? about;
  List<String> skills;
  String? photoPath;
  String id;
  List<String> friendsIds;
  bool? hideEmail;


  User({
    required this.name,
    required this.email,
    this.about,
    this.skills = const [],
    this.photoPath,
    required this.id,
    this.friendsIds = const [],
    this.hideEmail = false,

  });

  User copyWith({
    String? name,
    String? email,
    String? about,
    List<String>? skills,
    String? photoPath,
    String? id,
    List<String>? friendsIds,
    bool? hideEmail,
  }) {
    return User(
      name: name ?? this.name,
      email: email ?? this.email,
      about: about ?? this.about,
      skills: skills ?? this.skills,
      photoPath: photoPath ?? this.photoPath,
      id: id ?? this.id,
      friendsIds: friendsIds ?? this.friendsIds,
      hideEmail: hideEmail ?? this.hideEmail,

    );
  }
}