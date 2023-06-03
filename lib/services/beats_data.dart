class BeatsData {
  String? _id;
  String? _album;
  String? _title;
  String? _url;

  BeatsData({String? id, String? album, String? title, String? url}) {
    if (id != null) {
      this._id = id;
    }
    if (album != null) {
      this._album = album;
    }
    if (title != null) {
      this._title = title;
    }
    if (url != null) {
      this._url = url;
    }
  }

  String? get id => _id;
  set id(String? id) => _id = id;
  String? get album => _album;
  set album(String? album) => _album = album;
  String? get title => _title;
  set title(String? title) => _title = title;
  String? get url => _url;
  set url(String? url) => _url = url;

  BeatsData.fromJson(Map<String, dynamic> json) {
    _id = json['id'];
    _album = json['album'];
    _title = json['title'];
    _url = json['url'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this._id;
    data['album'] = this._album;
    data['title'] = this._title;
    data['url'] = this._url;
    return data;
  }
}