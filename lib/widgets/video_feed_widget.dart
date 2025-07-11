import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class VideoFeedWidget extends StatefulWidget {
  final Function(String) onVideoTap;

  const VideoFeedWidget({
    Key? key,
    required this.onVideoTap,
  }) : super(key: key);

  @override
  State<VideoFeedWidget> createState() => _VideoFeedWidgetState();
}

class _VideoFeedWidgetState extends State<VideoFeedWidget> {
  final PageController _feedPageController = PageController(viewportFraction: 0.8);
  int _currentPage = 0;

  final List<Map<String, String>> videoData = [
    {
      'id': '9MArp9H2YCM',
      'title': 'Introducing Falcon 180B: The Worlds Most Powerful Open LLM!',
      'thumbnail': 'https://img.youtube.com/vi/9MArp9H2YCM/hqdefault.jpg',
    },
    {
      'id': '_8MlpZkHKaI',
      'title': 'Making AI accessible: AI for All',
      'thumbnail': 'https://img.youtube.com/vi/_8MlpZkHKaI/hqdefault.jpg',
    },
    {
      'id': '5MN9u9KiwIc',
      'title': 'UAE is building an open source GenAI model called Falcon',
      'thumbnail': 'https://img.youtube.com/vi/5MN9u9KiwIc/hqdefault.jpg',
    },
    {
      'id': '24nRqjRJcXg',
      'title': 'Falcon 40B our game-changing AI model is now open source',
      'thumbnail': 'https://img.youtube.com/vi/24nRqjRJcXg/hqdefault.jpg',
    },
  ];

  @override
  void initState() {
    super.initState();
    _feedPageController.addListener(() {
      int next = _feedPageController.page!.round();
      if (_currentPage != next) {
        setState(() {
          _currentPage = next;
        });
      }
    });
  }

  @override
  void dispose() {
    _feedPageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 250,
      child: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _feedPageController,
              itemCount: videoData.length,
              scrollDirection: Axis.horizontal,
              itemBuilder: (context, index) {
                return _buildVideoCard(videoData[index], index);
              },
            ),
          ),
          SizedBox(height: 10),
          _buildPageIndicator(),
        ],
      ),
    );
  }

  Widget _buildVideoCard(Map<String, String> video, int index) {
    return AnimatedBuilder(
      animation: _feedPageController,
      builder: (context, child) {
        double value = 1.0;
        if (_feedPageController.position.haveDimensions) {
          value = _feedPageController.page! - index;
          value = (1 - (value.abs() * 0.3)).clamp(0.0, 1.0);
        }
        return Center(
          child: SizedBox(
            height: Curves.easeInOut.transform(value) * 200,
            width: Curves.easeInOut.transform(value) * 350,
            child: child,
          ),
        );
      },
      child: GestureDetector(
        onTap: () => widget.onVideoTap(video['id']!),
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              image: DecorationImage(
                image: NetworkImage(video['thumbnail']!),
                fit: BoxFit.cover,
              ),
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      video['title']!,
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPageIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List<Widget>.generate(videoData.length, (int index) {
        return Container(
          width: 8.0,
          height: 8.0,
          margin: EdgeInsets.symmetric(horizontal: 4.0),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _currentPage == index ? Colors.deepPurple : Colors.grey,
          ),
        );
      }),
    );
  }
} 