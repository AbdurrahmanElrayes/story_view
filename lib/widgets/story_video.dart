import 'dart:async';
import 'dart:io';

import 'package:cached_video_player/cached_video_player.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

import '../controller/story_controller.dart';
import '../utils.dart';

class VideoLoader {
  String url;

  File? videoFile;

  Map<String, dynamic>? requestHeaders;

  LoadState state = LoadState.loading;

  VideoLoader(this.url, {this.requestHeaders});

  void loadVideo(VoidCallback onComplete) {
    if (this.videoFile != null) {
      this.state = LoadState.success;
      onComplete();
    }

    final fileStream = DefaultCacheManager().getFileStream(this.url,
        headers: this.requestHeaders as Map<String, String>?);

    fileStream.listen((fileResponse) {
      if (fileResponse is FileInfo) {
        if (this.videoFile == null) {
          this.state = LoadState.success;
          this.videoFile = fileResponse.file;
          onComplete();
        }
      }
    });
  }
}

class StoryVideo extends StatefulWidget {
  final StoryController? storyController;
  final VideoLoader videoLoader;

  StoryVideo(this.videoLoader, {this.storyController, Key? key})
      : super(key: key ?? UniqueKey());

  static StoryVideo url(String url,
      {StoryController? controller,
      Map<String, dynamic>? requestHeaders,
      Key? key}) {
    return StoryVideo(
      VideoLoader(url, requestHeaders: requestHeaders),
      storyController: controller,
      key: key,
    );
  }

  @override
  State<StatefulWidget> createState() {
    return StoryVideoState();
  }
}

class StoryVideoState extends State<StoryVideo> {
  Future<void>? playerLoader;

  StreamSubscription? _streamSubscription;

  CachedVideoPlayerController? videoPlayerController;

  @override
  void initState() {
    super.initState();

    widget.storyController!.pause();
    this.videoPlayerController =
        CachedVideoPlayerController.network(widget.videoLoader.url);

    videoPlayerController!.initialize().then((v) {
      videoInitialized();
    });
    // widget.videoLoader.loadVideo(() {
    // });
  }

  void videoInitialized() {
    videoPlayerController!.addListener(() {
      if (widget.storyController!.durations[widget.videoLoader.url] == null) {
        widget.storyController!.setDuration(
            widget.videoLoader.url, videoPlayerController!.value.duration);
      }
      if (videoPlayerController!.value.isBuffering) {
        widget.storyController!.setBuffering(true);
      } else {
        widget.storyController!.setBuffering(false);
      }
    });
    if (widget.storyController != null) {
      _streamSubscription =
          widget.storyController!.playbackNotifier.listen((playbackState) {
        if (playbackState == PlaybackState.pause) {
          videoPlayerController!.pause();
        } else {
          videoPlayerController!.play();
        }
      });
    }
    setState(() {
      widget.videoLoader.state = LoadState.success;
    });
    widget.storyController!.play();
  }

  Widget getContentView() {
    if (widget.videoLoader.state == LoadState.success &&
        videoPlayerController!.value.isInitialized) {
      return Center(
        child: AspectRatio(
          aspectRatio: videoPlayerController!.value.aspectRatio,
          child: CachedVideoPlayer(videoPlayerController!),
        ),
      );
    }

    return widget.videoLoader.state == LoadState.loading
        ? Center(
            child: Container(
              width: 70,
              height: 70,
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                strokeWidth: 3,
              ),
            ),
          )
        : Center(
            child: Text(
            "Media failed to load.",
            style: TextStyle(
              color: Colors.white,
            ),
          ));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      height: double.infinity,
      width: double.infinity,
      child: getContentView(),
    );
  }

  @override
  void dispose() {
    Future.delayed(Duration(minutes: 1)).then((value) {
      videoPlayerController?.dispose();
    });
    _streamSubscription?.cancel();
    super.dispose();
  }
}
