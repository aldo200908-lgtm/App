import 'dart:convert';
import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

const bg = Color(0xFF0B0D10);
const panel = Color(0xFF191E22);
const neon = Color(0xFFA9F65D);
const grey = Color(0xFFA9B5BB);

class Song {
  const Song(this.id, this.title, this.artist);
  final String id;
  final String title;
  final String artist;
}

const demoSongs = <Song>[
  Song('kJQP7kiw5Fk', 'Despacito', 'Luis Fonsi ft. Daddy Yankee'),
  Song('JGwWNGJdvx8', 'Shape of You', 'Ed Sheeran'),
  Song('9bZkp7q19f0', 'Gangnam Style', 'PSY'),
  Song('DyDfgMOUjCI', 'bad guy', 'Billie Eilish'),
  Song('Cr8K88UcO0s', 'Titi Me Pregunto', 'Bad Bunny'),
];

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.aptitudlabs.musiclab.audio',
    androidNotificationChannelName: 'MusicLab - musica local',
    androidNotificationOngoing: true,
  );
  runApp(const MusicLab());
}

class MusicLab extends StatelessWidget {
  const MusicLab({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MusicLab',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: bg,
        colorScheme: const ColorScheme.dark(primary: neon, surface: panel),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: panel,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide.none,
          ),
        ),
      ),
      home: const LibraryHome(),
    );
  }
}

class LibraryHome extends StatefulWidget {
  const LibraryHome({super.key});
  @override
  State<LibraryHome> createState() => _LibraryHomeState();
}

class _LibraryHomeState extends State<LibraryHome> {
  final SharedPreferencesAsync prefs = SharedPreferencesAsync();
  final AudioPlayer player = AudioPlayer();
  final TextEditingController keyCtrl = TextEditingController();
  final TextEditingController searchCtrl = TextEditingController();
  int selectedTab = 0;
  bool loading = false;
  String error = '';
  String key = '';
  List<Song> matches = [];
  List<String> files = [];
  Set<String> favorites = {};
  String currentFile = '';

  @override
  void initState() {
    super.initState();
    _load();
    player.playerStateStream.listen((_) {
      if (mounted) setState(() {});
    });
  }

  Future<void> _load() async {
    key = await prefs.getString('youtube_key') ?? '';
    keyCtrl.text = key;
    files = await prefs.getStringList('music_files') ?? [];
    files = files.where((f) => File(f).existsSync()).toList();
    favorites = (await prefs.getStringList('favorites') ?? []).toSet();
    if (mounted) setState(() {});
  }

  void notice(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> search() async {
    final q = searchCtrl.text.trim();
    if (q.isEmpty) return;
    if (key.isEmpty) {
      notice('Configura una clave de YouTube Data API en Ajustes.');
      setState(() => selectedTab = 3);
      return;
    }
    setState(() { selectedTab = 1; loading = true; error = ''; matches = []; });
    try {
      final uri = Uri.https('www.googleapis.com', '/youtube/v3/search', {
        'part': 'snippet',
        'type': 'video',
        'videoEmbeddable': 'true',
        'maxResults': '20',
        'q': q,
        'key': key,
      });
      final response = await http.get(uri).timeout(const Duration(seconds: 20));
      if (response.statusCode != 200) {
        throw Exception('Error de YouTube: ${response.statusCode}. Revisa tu clave o cuota.');
      }
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      matches = (data['items'] as List).map((item) {
        final id = (item['id'] as Map)['videoId']?.toString() ?? '';
        final snippet = item['snippet'] as Map;
        return Song(id, snippet['title']?.toString() ?? 'Cancion', snippet['channelTitle']?.toString() ?? 'Artista');
      }).where((v) => v.id.isNotEmpty).toList();
    } catch (e) {
      error = e.toString();
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void openSong(Song s) {
    if (player.playing) player.pause();
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => VideoPage(song: s, favorite: favorites.contains(s.id), onFavorite: () {
        setState(() {
          if (favorites.contains(s.id)) {
            favorites.remove(s.id);
          } else {
            favorites.add(s.id);
          }
        });
        prefs.setStringList('favorites', favorites.toList());
      }),
    ));
  }

  Future<void> addFiles() async {
    try {
      final picked = await FilePicker.platform.pickFiles(
        type: FileType.audio, allowMultiple: true, withData: false,
      );
      if (picked == null) return;
      final dir = Directory('${(await getApplicationDocumentsDirectory()).path}/songs');
      await dir.create(recursive: true);
      int added = 0;
      for (final item in picked.files) {
        if (item.path == null) continue;
        final original = File(item.path!);
        if (!await original.exists()) continue;
        final safe = item.name.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
        final dest = File('${dir.path}/${DateTime.now().microsecondsSinceEpoch}_$safe');
        await original.copy(dest.path);
        files.add(dest.path);
        added++;
      }
      await prefs.setStringList('music_files', files);
      if (mounted) setState(() {});
      notice('Se importaron $added archivos.');
    } catch (e) {
      notice('No se pudieron importar archivos: $e');
    }
  }

  Future<void> playLocal(String file) async {
    try {
      final name = file.split('/').last.replaceFirst(RegExp(r'^\\d+_'), '');
      await player.setAudioSource(AudioSource.uri(
        Uri.file(file),
        tag: MediaItem(id: file, title: name, artist: 'Tu biblioteca'),
      ));
      setState(() => currentFile = file);
      player.play();
    } catch (e) {
      notice('Error al reproducir: $e');
    }
  }

  Widget songCard(Song song) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 5, horizontal: 7),
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(9),
        child: Image.network('https://i.ytimg.com/vi/${song.id}/mqdefault.jpg',
          width: 68, height: 55, fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const Icon(Icons.music_note, size: 36)),
      ),
      title: Text(song.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text(song.artist, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: grey)),
      trailing: const Icon(Icons.play_circle_fill, color: neon, size: 31),
      onTap: () => openSong(song),
    );
  }

  Widget homeTab() => ListView(
    padding: const EdgeInsets.all(22),
    children: [
      const Text('MUSICLAB', style: TextStyle(fontSize: 23, fontWeight: FontWeight.w900, letterSpacing: 3)),
      const SizedBox(height: 14),
      Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF294D3B), Color(0xFF17232B)]),
          borderRadius: BorderRadius.circular(25),
        ),
        child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(Icons.graphic_eq, color: neon, size: 42),
          SizedBox(height: 24),
          Text('Tu musica.\nTu espacio.', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900)),
          SizedBox(height: 12),
          Text('Videos musicales oficiales y tus canciones locales.', style: TextStyle(color: grey)),
        ]),
      ),
      const SizedBox(height: 26),
      const Text('Grandes exitos para probar', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
      const SizedBox(height: 10),
      ...demoSongs.map(songCard),
    ],
  );

  Widget searchTab() => ListView(
    padding: const EdgeInsets.all(20),
    children: [
      const Text('Buscar musica', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
      const SizedBox(height: 18),
      TextField(
        controller: searchCtrl,
        decoration: InputDecoration(
          hintText: 'Bad Bunny, Feid, Karol G...',
          suffixIcon: IconButton(onPressed: search, icon: const Icon(Icons.search, color: neon)),
        ),
        textInputAction: TextInputAction.search, onSubmitted: (_) => search(),
      ),
      const SizedBox(height: 16),
      if (key.isEmpty) const Text('Para buscar cualquier artista, introduce tu clave de YouTube Data API en Ajustes.', style: TextStyle(color: grey)),
      if (loading) const Center(child: CircularProgressIndicator()),
      if (error.isNotEmpty) Text(error, style: const TextStyle(color: Colors.orangeAccent)),
      ...matches.map(songCard),
    ],
  );

  Widget libraryTab() => ListView(
    padding: const EdgeInsets.all(20),
    children: [
      const Text('Mi biblioteca', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
      const SizedBox(height: 8),
      const Text('Musica de tu telefono. Puedes escucharla con la pantalla bloqueada.', style: TextStyle(color: grey)),
      const SizedBox(height: 18),
      FilledButton.icon(onPressed: addFiles, icon: const Icon(Icons.add), label: const Text('Importar MP3 y audio')),
      const SizedBox(height: 22),
      ...files.map((f) => ListTile(
        leading: const Icon(Icons.library_music, color: neon),
        title: Text(f.split('/').last.replaceFirst(RegExp(r'^\\d+_'), ''), maxLines: 1, overflow: TextOverflow.ellipsis),
        trailing: Icon(currentFile == f && player.playing ? Icons.equalizer : Icons.play_arrow, color: neon),
        onTap: () => playLocal(f),
      )),
      if (files.isEmpty) const Padding(padding: EdgeInsets.all(28), child: Text('Todavia no has importado canciones.', textAlign: TextAlign.center, style: TextStyle(color: grey))),
      if (currentFile.isNotEmpty)
        Card(child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(children: [
            const Icon(Icons.music_note, color: neon),
            const SizedBox(width: 9),
            const Expanded(child: Text('Reproductor local')),
            IconButton(onPressed: () async {
              if (player.playing) { await player.pause(); } else { await player.play(); }
              if (mounted) setState(() {});
            }, icon: Icon(player.playing ? Icons.pause_circle : Icons.play_circle, size: 35, color: neon)),
          ]),
        )),
    ],
  );

  Widget settingsTab() => ListView(
    padding: const EdgeInsets.all(22),
    children: [
      const Text('Ajustes', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
      const SizedBox(height: 22),
      const Text('YouTube Data API v3', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
      const SizedBox(height: 9),
      const Text('La clave solo se guarda en tu telefono. Se necesita para buscar videos; los exitos de Inicio funcionan sin clave.', style: TextStyle(color: grey)),
      const SizedBox(height: 12),
      TextField(controller: keyCtrl, autocorrect: false, decoration: const InputDecoration(labelText: 'Clave de API')),
      const SizedBox(height: 12),
      FilledButton(onPressed: () async {
        key = keyCtrl.text.trim();
        await prefs.setString('youtube_key', key);
        if (mounted) setState(() {});
        notice('Clave guardada en este dispositivo.');
      }, child: const Text('Guardar clave')),
      const SizedBox(height: 22),
      const Text('MusicLab Alpha 01 - APK privada de pruebas. YouTube utiliza su reproductor integrado y no permite extraccion de audio ni segundo plano.', style: TextStyle(color: grey)),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final pages = [homeTab(), searchTab(), libraryTab(), settingsTab()];
    return Scaffold(
      body: SafeArea(child: pages[selectedTab]),
      bottomNavigationBar: NavigationBar(
        backgroundColor: panel, indicatorColor: const Color(0xFF345331),
        selectedIndex: selectedTab,
        onDestinationSelected: (i) => setState(() => selectedTab = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home, color: neon), label: 'Inicio'),
          NavigationDestination(icon: Icon(Icons.search), label: 'Buscar'),
          NavigationDestination(icon: Icon(Icons.library_music_outlined), label: 'Biblioteca'),
          NavigationDestination(icon: Icon(Icons.settings_outlined), label: 'Ajustes'),
        ],
      ),
    );
  }

  @override
  void dispose() {
    keyCtrl.dispose(); searchCtrl.dispose(); player.dispose();
    super.dispose();
  }
}

class VideoPage extends StatefulWidget {
  const VideoPage({super.key, required this.song, required this.favorite, required this.onFavorite});
  final Song song;
  final bool favorite;
  final VoidCallback onFavorite;
  @override
  State<VideoPage> createState() => _VideoPageState();
}

class _VideoPageState extends State<VideoPage> {
  late final YoutubePlayerController yt;
  late bool isFavorite;
  @override
  void initState() {
    super.initState();
    isFavorite = widget.favorite;
    yt = YoutubePlayerController.fromVideoId(
      videoId: widget.song.id, autoPlay: false,
      params: const YoutubePlayerParams(showControls: true, showFullscreenButton: true),
    );
  }
  @override
  void dispose() {
    yt.close();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Reproductor'), backgroundColor: bg),
    body: SafeArea(child: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const SizedBox(height: 40),
        YoutubePlayer(controller: yt),
        const SizedBox(height: 26),
        Text(widget.song.title, style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w900)),
        const SizedBox(height: 5),
        Text(widget.song.artist, style: const TextStyle(color: grey)),
        const SizedBox(height: 22),
        FilledButton.icon(
          onPressed: () { widget.onFavorite(); setState(() => isFavorite = !isFavorite); },
          icon: Icon(isFavorite ? Icons.favorite : Icons.favorite_border),
          label: Text(isFavorite ? 'En favoritos' : 'Agregar a favoritos'),
        ),
        const SizedBox(height: 12),
        const Text('Video oficial incorporado con las reglas de reproduccion de YouTube.', style: TextStyle(color: grey)),
      ],
    )),
  );
}