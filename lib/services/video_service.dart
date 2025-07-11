import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class VideoService {
  static void playVideo(BuildContext context, String videoId) {
    YoutubePlayerController controller = YoutubePlayerController(
      initialVideoId: videoId,
      flags: YoutubePlayerFlags(
        autoPlay: true,
        mute: false,
      ),
    );

    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => Scaffold(
        appBar: AppBar(
          title: Text('YouTube Video'),
          backgroundColor: Colors.black,
        ),
        backgroundColor: Colors.black,
        body: Center(
          child: Container(
            width: MediaQuery.of(context).size.width * 0.95,
            height: MediaQuery.of(context).size.height * 0.95,
            child: YoutubePlayer(
              controller: controller,
              showVideoProgressIndicator: true,
              progressIndicatorColor: Colors.red,
              progressColors: ProgressBarColors(
                playedColor: Colors.red,
                handleColor: Colors.redAccent,
              ),
              onReady: () {
                print('Player is ready.');
              },
              onEnded: (data) {
                print('Video ended.');
              },
              bottomActions: [
                CurrentPosition(),
                ProgressBar(isExpanded: true),
                RemainingDuration(),
                FullScreenButton(),
              ],
            ),
          ),
        ),
      ),
    ));
  }
} 