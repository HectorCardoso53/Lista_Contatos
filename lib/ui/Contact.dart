class Contact {
  final String? name;

  Contact({this.name});

  Contact.fromMap(Map<String, dynamic> map) : name = map['name'];

  Map<String, dynamic> toMap() {
    return {
      'name': name,
    };
  }
}
