class FileModel {
  final String name;
  final String link;

  FileModel({required this.name, required this.link});

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'link': link,
    };
  }

  factory FileModel.fromMap(Map<String, dynamic> map) {
    return FileModel(
      name: map['name'],
      link: map['link'],
    );
  }
}
