class User {
  final int id;
  final String name;
  final String username;
  final String email;
  final String password;
  final String image;

  const User(
      {required this.name,
      required this.id,
      required this.username,
      required this.email,
      required this.password,
      required this.image});

  factory User.fromJson(Map<String, dynamic> json) => User(
      id: json['id'],
      name: json['firstName'],
      username: json['username'],
      email: json['email'],
      password: json['password'] ?? "",
      image: json['image'] ?? '');

  Map<String, dynamic> toJson() => {
        "id": id,
        "firstName": name,
        "username": username,
        "email": email,
        "password": password,
        "image": image
      };
}
