import 'dart:async';
import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:azi_music_mobile/components/audio_player.dart';
import 'package:hive/hive.dart';
import 'package:just_audio/just_audio.dart';
import 'package:rxdart/rxdart.dart';

class AudioPlayerHandlerImpl extends BaseAudioHandler
    with QueueHandler, SeekHandler
    implements AudioPlayerHandler {
  int? count;
  Timer? _sleepTimer;
  bool recommend = true;
  bool loadStart = true;
  bool useDown = true;
  AndroidEqualizerParameters? _equalizerParams;

  late AudioPlayer? _player;
  late String preferredQuality;
  late bool resetOnSkip;

  final _equalizer = AndroidEqualizer();

  Box downloadsBox = Hive.box('downloads');

  final BehaviorSubject<List<MediaItem>> _recentSubject =
      BehaviorSubject.seeded(<MediaItem>[]);

  final _playlist = ConcatenatingAudioSource(children: []);

  @override
  final BehaviorSubject<double> volume = BehaviorSubject.seeded(1.0);
  @override
  final BehaviorSubject<double> speed = BehaviorSubject.seeded(1.0);

  final _mediaItemExpando = Expando<MediaItem>();

  // TODO: RX
  Stream<List<IndexedAudioSource>> get _effectiveSequence => Rx.combineLatest3<
              List<IndexedAudioSource>?,
              List<int>?,
              bool,
              List<IndexedAudioSource>?>(_player!.sequenceStream,
          _player!.shuffleIndicesStream, _player!.shuffleModeEnabledStream,
          (sequence, shuffleIndices, shuffleModeEnabled) {
        if (sequence == null) return [];
        if (!shuffleModeEnabled) return sequence;
        if (shuffleIndices == null) return null;
        if (shuffleIndices.length != sequence.length) return null;
        return shuffleIndices.map((e) => sequence[e]).toList();
      }).whereType<List<IndexedAudioSource>>();

  int? getQueueIndex(int? currentIndex, List<int>? shuffleIndices,
      {bool shuffleModeEnabled = false}) {
    final effectiveIndices = _player!.effectiveIndices ?? [];
    final shuffleIndicesInv = List.filled(effectiveIndices.length, 0);
    for (var i = 0; i < effectiveIndices.length; i++) {
      shuffleIndicesInv[effectiveIndices[i]] = i;
    }

    return (shuffleModeEnabled &&
            ((currentIndex ?? 0) < shuffleIndicesInv.length))
        ? shuffleIndicesInv[currentIndex ?? 0]
        : currentIndex;
  }

  @override
  Stream<QueueState> get queueState =>
      Rx.combineLatest3<List<MediaItem>, PlaybackState, List<int>, QueueState>(
        queue,
        playbackState,
        _player!.shuffleIndicesStream.whereType<List<int>>(),
        (queue, playbackState, shuffleIndices) => QueueState(
          queue,
          playbackState.queueIndex,
          playbackState.shuffleMode == AudioServiceShuffleMode.all
              ? shuffleIndices
              : null,
          playbackState.repeatMode,
        ),
      ).where(
        (state) =>
            state.shuffleIndices == null ||
            state.queue.length == state.shuffleIndices!.length,
      );

  AudioPlayerHandlerImpl() {
    _init();
  }

  Future<void> _init() async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());

    await startService();

    speed.debounceTime(const Duration(milliseconds: 250)).listen((event) {
      playbackState.add(playbackState.value.copyWith(speed: event));
    });

    preferredQuality = Hive.box('settings')
        .get('streamingQuality', defaultValue: '320 kbps')
        .toString();

    resetOnSkip = Hive.box('settings').get('resetOnSkip', defaultValue: false);

    recommend = Hive.box('settings').get('autoplay', defaultValue: true);

    loadStart = Hive.box('settings').get('loadStart', defaultValue: true);

    mediaItem.whereType<MediaItem>().listen((event) {
      if (count != null) {
        count = count! - 1;
        if (count! <= 0) {
          count = null;
          stop();
        }
      }
    });

    // TODO

    Rx.combineLatest4<int?, List<MediaItem>, bool, List<int>?, MediaItem?>(
        _player!.currentIndexStream,
        queue,
        _player!.shuffleModeEnabledStream,
        _player!.shuffleIndicesStream,
        (index, queue, shuffleModeEnabled, shuffleIndices) {
      final queueIndex = getQueueIndex(index, shuffleIndices,
          shuffleModeEnabled: shuffleModeEnabled);

      return (queueIndex != null && queueIndex < queue.length)
          ? queue[queueIndex]
          : null;
    }).whereType<MediaItem>().distinct().listen(mediaItem.add);

    // Propagate all events from the audio player to AudioService clients.
    _player!.playbackEventStream.listen(_broadcastState);

    _player!.shuffleModeEnabledStream
        .listen((enabled) => _broadcastState(_player!.playbackEvent));

    _player!.loopModeStream
        .listen((event) => _broadcastState(_player!.playbackEvent));

    _player!.processingStateStream.listen((state) {
      if (state == ProcessingState.completed) {
        stop();
        _player!.seek(Duration.zero, index: 0);
      }
    });

    // Broadcast the current queue.
    _effectiveSequence
        .map((sequence) =>
            sequence.map((source) => _mediaItemExpando[source]!).toList())
        .pipe(queue);

    if (loadStart) {
      final List lastQueueList = await Hive.box('cache')
          .get('lastQueue', defaultValue: [])?.toList() as List;

      // TODO:
    } else {
      await _player!.setAudioSource(_playlist, preload: false);
    }
  }

  Future<void> startService() async {
    final bool withPipeLine =
        Hive.box('settings').get('supportEq', defaultValue: false);

    if (withPipeLine && Platform.isAndroid) {
      final AudioPipeline pipeline =
          AudioPipeline(androidAudioEffects: [_equalizer]);
      _player = AudioPlayer(audioPipeline: pipeline);
    } else {
      _player = AudioPlayer();
    }
  }

  /// Broadcasts the current state to all clients.
  void _broadcastState(PlaybackEvent event) async {
    final playing = _player!.playing;
    final queueIndex = getQueueIndex(
        event.currentIndex, _player!.shuffleIndices,
        shuffleModeEnabled: _player!.shuffleModeEnabled);

    playbackState.add(playbackState.value.copyWith(
        controls: [
          MediaControl.skipToPrevious,
          if (playing) MediaControl.pause else MediaControl.play,
          MediaControl.skipToNext,
          MediaControl.stop
        ],
        systemActions: const {
          MediaAction.seek,
          MediaAction.seekForward,
          MediaAction.seekBackward
        },
        androidCompactActionIndices: const [
          0,
          1,
          2
        ],
        processingState: const {
          ProcessingState.idle: AudioProcessingState.idle,
          ProcessingState.loading: AudioProcessingState.loading,
          ProcessingState.buffering: AudioProcessingState.buffering,
          ProcessingState.ready: AudioProcessingState.ready,
          ProcessingState.completed: AudioProcessingState.completed
        }[_player!.processingState]!,
        playing: playing,
        updatePosition: _player!.position,
        bufferedPosition: _player!.bufferedPosition,
        speed: _player!.speed,
        queueIndex: queueIndex));
  }

  AudioSource _itemToSource(MediaItem mediaItem) {
    AudioSource audioSource;
    if (mediaItem.artUri.toString().startsWith('file:')) {
      audioSource =
          AudioSource.uri(Uri.file(mediaItem.extras!['url'].toString()));
    } else {
      if (downloadsBox.containsKey(mediaItem.id) && useDown) {
        audioSource = AudioSource.uri(Uri.file(
            (downloadsBox.get(mediaItem.id) as Map)['path'].toString()));
      } else {
        // TODO
        audioSource = AudioSource.uri(
            Uri.parse(mediaItem.extras!['url'].toString().replaceAll(
                  '_320.',
                  '_${preferredQuality.replaceAll(' kbps', '')}.',
                )));
      }
    }

    _mediaItemExpando[audioSource] = mediaItem;
    return audioSource;
  }

  List<AudioSource> _itemsToSource(List<MediaItem> mediaItems) {
    preferredQuality = Hive.box('settings')
        .get('stramingQuality', defaultValue: '320kbps')
        .toString();

    useDown = Hive.box('settings').get('useDown', defaultValue: true);
    return mediaItems.map(_itemToSource).toList();
  }

  @override
  Future<void> onTaskRemoved() async {
    final bool stopForegroundService =
        Hive.box('settings').get('stopForegroundService', defaultValue: true);
    if (stopForegroundService) {
      await stop();
    }
  }

  @override
  Future<List<MediaItem>> getChildren(String parentMediaId,
      [Map<String, dynamic>? options]) async {
    switch (parentMediaId) {
      case AudioService.recentRootId:
        return _recentSubject.value;
      default:
        return queue.value;
    }
  }

  @override
  ValueStream<Map<String, dynamic>> subscribeToChildren(String parentMediaId) {
    switch (parentMediaId) {
      case AudioService.recentRootId:
        final stream = _recentSubject.map((event) => <String, dynamic>{});
        return _recentSubject.hasValue
            ? stream.shareValueSeeded(<String, dynamic>{})
            : stream.shareValue();
      default:
        return Stream.value(queue.value)
            .map((event) => <String, dynamic>{})
            .shareValue();
    }
  }

  Future<void> addRecentlyPlayed(MediaItem mediaItem) async {
    List recentList =
        Hive.box('cache').get('recentSongs', defaultValue: []).toList();

    // TODO
  }

  Future<void> addLastQueue(List<MediaItem> queue) async {
    // TODO
  }

  @override
  Future<void> addQueueItem(MediaItem mediaItem) async {
    await _playlist.add(_itemToSource(mediaItem));
  }

  @override
  Future<void> addQueueItems(List<MediaItem> mediaItems) async {
    await _playlist.addAll(_itemsToSource(mediaItems));
  }

  @override
  Future<void> insertQueueItem(int index, MediaItem mediaItem) async {
    _playlist.insert(index, _itemToSource(mediaItem));
  }

  @override
  Future<void> moveQueueItem(int currentIndex, int newIndex) async {
    await _playlist.move(currentIndex, newIndex);
  }

  @override
  Future<void> updateQueue(List<MediaItem> newQueue) async {
    await _playlist.clear();
    await _playlist.addAll(_itemsToSource(newQueue));
    addLastQueue(newQueue);
  }

  @override
  Future<void> updateMediaItem(MediaItem mediaItem) async {
    final index =
        queue.value.indexWhere((element) => element.id == mediaItem.id);
    _mediaItemExpando[_player!.sequence![index]] = mediaItem;
  }

  @override
  Future<void> removeQueueItem(MediaItem mediaItem) async {
    final index = queue.value.indexOf(mediaItem);
    await _playlist.removeAt(index);
  }

  @override
  Future<void> removeQueueItemAt(int index) async {
    await _playlist.removeAt(index);
  }

  @override
  Future<void> skipToNext() => _player!.seekToNext();

  @override
  Future<void> skipToPrevious() async {
    resetOnSkip = Hive.box('settings').get('resetOnSkip', defaultValue: false);
    if (resetOnSkip) {
      if ((_player?.position.inSeconds ?? 5) <= 5) {
        _player!.seekToPrevious();
      } else {
        _player!.seek(Duration.zero);
      }
    } else {
      _player!.seekToPrevious();
    }
  }

  @override
  Future<void> skipToQueueItem(int index) async {
    if (index < 0 || index >= _playlist.children.length) return;
    _player!.seek(
      Duration.zero,
      index: _player!.shuffleModeEnabled ? _player!.shuffleIndices![index]: index
    );
  }

  @override
  Future<void> play() => _player!.play();

  @override
  Future<void> pause() async {
    _player!.pause();
  }

  @override
  Future<void> seek(Duration position) => _player!.seek(position);

  @override
  Future<void> stop() async {
    await _player!.stop();
    await playbackState.firstWhere((element) => element.processingState == AudioProcessingState.idle);
  }

  @override
  Future customAction(String name, [Map<String, dynamic>? extras]) {
    if(name == 'sleepTimer') {
      _sleepTimer?.cancel();
      if(extras?['time'] != null && extras!['time'].runtimeType == int && extras['time'] > 0 as bool) {
        _sleepTimer = Timer(Duration(minutes: extras['time']), () {
          stop();
        });
      }
    }

    if(name == 'sleepCounter') {
      if(extras?['count'] != null && extras!['count'].runtimeType == int && extras['count'] > 0) {
        count = extras['count'];
      }
    }

    if (name == 'setBandGain') {
      final bandIdx = extras!['band'] as int;
      final gain = extras['gain'] as double;
      _equalizerParams!.bands[bandIdx].setGain(gain);
    }

    if (name == 'setEqualizer') {
      _equalizer.setEnabled(extras!['value'] as bool);
    }

    if (name == 'getEqualizerParams') {
      return getEqParms();
    }
    return super.customAction(name, extras);
  }

  Future<Map> getEqParms() async {
    _equalizerParams ??= await _equalizer.parameters;
    final List<AndroidEqualizerBand> bands = _equalizerParams!.bands;
    final List bandsList = bands.map((e) => {
      'centerFrequency': e.centerFrequency,
      'gain': e.gain,
      'index': e.index
    }).toList();

    return {
      'maxDecibles': _equalizerParams!.maxDecibels,
      'minDecibles': _equalizerParams!.minDecibels,
      'bands': bandsList
    };
  }

  @override
  Future<void> setShuffleMode(AudioServiceShuffleMode shuffleMode) async {
    final enabled = shuffleMode == AudioServiceShuffleMode.all;
    if(enabled) {
      await _player!.shuffle();
    }

    playbackState.add(playbackState.value.copyWith(shuffleMode: shuffleMode));
    await _player!.setShuffleModeEnabled(enabled);
  }

  @override
  Future<void> setRepeatMode(AudioServiceRepeatMode repeatMode) async {
    playbackState.add(playbackState.value.copyWith(repeatMode: repeatMode));
    await _player!.setLoopMode(LoopMode.values[repeatMode.index]);
  }

  @override
  Future<void> setSpeed(double speed) async {
    this.speed.add(speed);
    await _player!.setSpeed(speed);
  }

  @override
  Future<void> setVolume(double volume)  async {
    this.volume.add(volume);
    await _player!.setVolume(volume);
  }

  @override
  Future<void> click([MediaButton button = MediaButton.media]) async {
    switch(button) {
      case MediaButton.media:
        _handleMediaActionPressed();
        break;
      case MediaButton.next:
        await skipToNext();
        break;
      case MediaButton.previous:
        await skipToPrevious();
        break;
    }
  }

  late BehaviorSubject<int> _tappedMediaActionNumber;
  Timer? _timer;

  void _handleMediaActionPressed() {
    if(_timer == null) {
      _tappedMediaActionNumber = BehaviorSubject.seeded(1);
      _timer = Timer(const Duration(milliseconds: 800), () {
        final tappedNumber = _tappedMediaActionNumber.value;
        switch(tappedNumber) {
          case 1:
            if(playbackState.value.playing) {
              pause();
            } else {
              play();
            }
            break;
          case 2:
            skipToNext();
            break;
          case 3:
            skipToPrevious();
            break;
          default:
            break;
        }
        _tappedMediaActionNumber.close();
        _timer!.cancel();
        _timer = null;
      });
    } else {
      final currentNumber = _tappedMediaActionNumber.value;
      _tappedMediaActionNumber.add(currentNumber + 1);
    }
  } 
}
