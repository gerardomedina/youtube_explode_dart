import 'dart:convert';

import 'package:youtube_explode_dart/src/exceptions/exceptions.dart';
import 'package:youtube_explode_dart/src/retry.dart';
import 'package:youtube_explode_dart/src/reverse_engineering/reverse_engineering.dart';

class PlaylistResponse {
  // Json parsed map
  final Map<String, dynamic> _root;

  PlaylistResponse(this._root);

  String get title => _root['title'];

  String get author => _root['author'];

  String get description => _root['description'];

  int get viewCount => int.tryParse(_root['views'] ?? '');

  int get likeCount => int.tryParse(_root['likes']);

  int get dislikeCount => int.tryParse(_root['dislikes']);

  Iterable<Video> get videos =>
      _root['video']?.map((e) => Video(e)) ?? const [];

  PlaylistResponse.parse(String raw) : _root = json.tryDecode(raw) {
    if (_root == null) {
      throw TransientFailureException('Playerlist response is broken.');
    }
  }

  static Future<PlaylistResponse> get(YoutubeHttpClient httpClient, String id,
      {int index = 0}) {
    var url =
        'https://youtube.com/list_ajax?style=json&action_get_list=1&list=$id&index=$index&hl=en';
    return retry(() async {
      var raw = await httpClient.getString(url);
      return PlaylistResponse.parse(raw);
    });
  }

  static Future<PlaylistResponse> searchResults(
      YoutubeHttpClient httpClient, String query,
      {int page = 0}) {
    var url = 'https://youtube.com/search_ajax?style=json&search_query='
        '${Uri.encodeQueryComponent(query)}&page=$page&hl=en';
    return retry(() async {
      var raw = await httpClient.getString(url, validate: false);
      return PlaylistResponse.parse(raw);
    });
  }
}

class Video {
  // Json parsed map
  final Map<String, dynamic> _root;

  Video(this._root);

  String get id => _root['encrypted_id'];

  String get author => _root['author'];

  //TODO: Check if date is correctS
  DateTime get uploadDate =>
      DateTime.fromMillisecondsSinceEpoch(_root['time_created'] * 1000);

  String get title => _root['title'];

  String get description => _root['description'];

  Duration get duration => Duration(seconds: _root['length_seconds']);

  int get viewCount => int.parse(_root['views'].stripNonDigits());

  int get likes => int.parse(_root['likes']);

  int get dislikes => int.parse(_root['dislikes']);

  Iterable<String> get keywords => RegExp(r'"[^\"]+"|\S+')
      .allMatches(_root['keywords'])
      .map((e) => e.group(0))
      .toList(growable: false);
}

extension on String {
  static final _exp = RegExp(r'\D');

  /// Strips out all non digit characters.
  String stripNonDigits() => replaceAll(_exp, '');
}

extension on JsonCodec {
  dynamic tryDecode(String source) {
    try {
      return json.decode(source);
    } on FormatException {
      return null;
    }
  }
}