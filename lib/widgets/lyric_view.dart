import 'package:flutter/material.dart';
import '../models/lyric.dart';

class LyricView extends StatefulWidget {
  final Lyric? lyric;
  final Duration position;
  final double lineHeight;
  final TextStyle normalStyle;
  final TextStyle activeStyle;
  final Function(Duration)? onPositionChanged;

  const LyricView({
    Key? key,
    required this.lyric,
    required this.position,
    this.lineHeight = 32.0,
    required this.normalStyle,
    required this.activeStyle,
    this.onPositionChanged,
  }) : super(key: key);

  @override
  State<LyricView> createState() => _LyricViewState();
}

class _LyricViewState extends State<LyricView> {
  late ScrollController _scrollController;
  bool _isDragging = false;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToCurrentLine() {
    if (_isDragging || widget.lyric == null) return;

    final currentLine = widget.lyric!.findLyricLine(widget.position);
    if (currentLine == null) return;

    final index = widget.lyric!.lyrics.indexOf(currentLine);
    if (index != _currentIndex) {
      _currentIndex = index;
      _scrollController.animateTo(
        index * widget.lineHeight,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.lyric == null) {
      return const Center(
        child: Text('暂无歌词'),
      );
    }

    _scrollToCurrentLine();

    return GestureDetector(
      onVerticalDragStart: (_) {
        _isDragging = true;
      },
      onVerticalDragEnd: (_) {
        _isDragging = false;
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted && !_isDragging) {
            _scrollToCurrentLine();
          }
        });
      },
      child: ListView.builder(
        controller: _scrollController,
        itemCount: widget.lyric!.lyrics.length,
        itemBuilder: (context, index) {
          final line = widget.lyric!.lyrics[index];
          final isActive = line == widget.lyric!.findLyricLine(widget.position);

          return GestureDetector(
            onTap: () {
              if (widget.onPositionChanged != null) {
                widget.onPositionChanged!(line.timestamp);
              }
            },
            child: Container(
              height: widget.lineHeight,
              alignment: Alignment.center,
              child: Text(
                line.text,
                style: isActive ? widget.activeStyle : widget.normalStyle,
                textAlign: TextAlign.center,
              ),
            ),
          );
        },
      ),
    );
  }
} 