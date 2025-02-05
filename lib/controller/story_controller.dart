import 'package:rxdart/rxdart.dart';

enum PlaybackState { pause, play, next, previous }

/// Controller to sync playback between animated child (story) views. This
/// helps make sure when stories are paused, the animation (gifs/slides) are
/// also paused.
/// Another reason for using the controller is to place the stories on `paused`
/// state when a media is loading.
class StoryController {
  /// Stream that broadcasts the playback state of the stories.
  final playbackNotifier = BehaviorSubject<PlaybackState>();
  final videoDurationNotifier = BehaviorSubject<Duration>();
  final bufferingNotifier = BehaviorSubject<bool>();
  final Map<String, Duration> durations = {};

  setDuration(String videoUrl, Duration duration) {
    durations[videoUrl] = duration;
    videoDurationNotifier.add(duration);
  }

  /// Notify listeners with a [PlaybackState.pause] state
  void pause() {
    playbackNotifier.add(PlaybackState.pause);
  }

  /// Notify listeners with a [PlaybackState.play] state
  void play() {
    playbackNotifier.add(PlaybackState.play);
  }

  void setBuffering(bool buffering) {
    bufferingNotifier.add(buffering);
  }

  void next() {
    playbackNotifier.add(PlaybackState.next);
  }

  void previous() {
    playbackNotifier.add(PlaybackState.previous);
  }

  /// Remember to call dispose when the story screen is disposed to close
  /// the notifier stream.
  void dispose() {
    playbackNotifier.close();
    bufferingNotifier.close();
    videoDurationNotifier.close();
  }
}
