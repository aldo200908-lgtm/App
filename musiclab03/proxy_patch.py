from pathlib import Path
p=Path('lib/music_player.dart')
s=p.read_text()
assert "import 'package:just_audio/just_audio.dart';" in s
s=s.replace("import 'package:just_audio/just_audio.dart';", "import 'package:just_audio/just_audio.dart';\nimport 'package:http/http.dart' as http;", 1)
old="""      await player.setAudioSource(AudioSource.uri(uri, tag: MediaItem(
        id: song.key,
        title: song.title,
        artist: song.artist,
        album: song.source.label,
        artUri: art != null && art.hasScheme ? art : null,
        duration: song.live ? null : (song.duration > 0 ? Duration(seconds: song.duration) : null),
      )));"""
new="""      final media = MediaItem(
        id: song.key,
        title: song.title,
        artist: song.artist,
        album: song.source.label,
        artUri: art != null && art.hasScheme ? art : null,
        duration: song.live ? null : (song.duration > 0 ? Duration(seconds: song.duration) : null),
      );
      // Route requests through the same Dart HTTP stack used by the probe.
      await player.setAudioSource(song.source == MusicSource.youtube
          ? _HttpAudioStreamSource(uri, tag: media)
          : AudioSource.uri(uri, tag: media));"""
if old not in s: raise Exception('Unable to locate original AudioSource.uri block')
s=s.replace(old,new,1)
s+='''

/// Local byte-range bridge: ExoPlayer requests a localhost stream; Dart
/// retrieves source bytes using the same networking stack as the HTTP probe.
/// Experimental: this cannot override a source server's access restriction.
class _HttpAudioStreamSource extends StreamAudioSource {
  _HttpAudioStreamSource(this.uri, {super.tag});
  final Uri uri;
  final http.Client _http = http.Client();

  @override
  Future<StreamAudioResponse> request([int? start, int? end]) async {
    final beginning = start ?? 0;
    final request = http.Request('GET', uri);
    request.headers['Accept-Encoding'] = 'identity';
    if (end != null && end > beginning) {
      request.headers['Range'] = 'bytes=$beginning-${end - 1}';
    } else if (beginning > 0) {
      request.headers['Range'] = 'bytes=$beginning-';
    }
    final response = await _http.send(request).timeout(const Duration(seconds: 18));
    if (response.statusCode != 200 && response.statusCode != 206) {
      throw StateError('Fuente rechazada (HTTP ${response.statusCode}).');
    }
    if (beginning > 0 && response.statusCode != 206) {
      throw StateError('El servidor no admite Range desde $beginning.');
    }
    final contentRange = response.headers['content-range'];
    final total = contentRange != null && contentRange.contains('/')
        ? int.tryParse(contentRange.split('/').last)
        : null;
    final length = response.contentLength;
    final mime = uri.queryParameters['mime'] ??
        response.headers['content-type']?.split(';').first ?? 'audio/mp4';
    return StreamAudioResponse(
      rangeRequestsSupported: response.statusCode == 206,
      sourceLength: response.statusCode == 206 ? total : null,
      contentLength: length,
      offset: response.statusCode == 206 ? beginning : null,
      stream: response.stream,
      contentType: mime,
    );
  }
}
'''
p.write_text(s)
print('StreamAudioSource inserted')
