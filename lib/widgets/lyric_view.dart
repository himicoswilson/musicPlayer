import 'package:flutter/material.dart';
import '../models/lyric.dart';

class LyricView extends StatefulWidget {
  final Lyric? lyric;
  final Duration position;
  final double lineHeight;
  final TextStyle normalStyle;
  final TextStyle activeStyle;
  final bool enableDrag;

  const LyricView({
    Key? key,
    required this.lyric,
    required this.position,
    this.lineHeight = 32.0,
    this.normalStyle = const TextStyle(
      color: Colors.grey,
      fontSize: 16,
      height: 1.5,
    ),
    this.activeStyle = const TextStyle(
      color: Colors.white,
      fontSize: 18,
      height: 1.5,
      fontWeight: FontWeight.bold,
    ),
    this.enableDrag = true,
  }) : super(key: key);

  @override
  State<LyricView> createState() => _LyricViewState();
}

class _LyricViewState extends State<LyricView> {
  late ScrollController _scrollController;
  int _currentIndex = 0;
  bool _isDragging = false;
  double _dragOffset = 0;

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

  @override
  void didUpdateWidget(LyricView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isDragging && widget.lyric != null) {
      _updateCurrentIndex();
      _scrollToCurrentIndex();
    }
  }

  void _updateCurrentIndex() {
    if (widget.lyric == null || widget.lyric!.lines.isEmpty) return;

    final currentLine = widget.lyric!.findLyricLine(widget.position);
    if (currentLine == null) {
      _currentIndex = 0;
    } else {
      _currentIndex = widget.lyric!.lines.indexOf(currentLine);
    }
  }

  void _scrollToCurrentIndex() {
    if (_currentIndex < 0 || widget.lyric == null) return;

    final offset = _currentIndex * widget.lineHeight;
    _scrollController.animateTo(
      offset,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.lyric == null || widget.lyric!.lines.isEmpty) {
      return const Center(
        child: Text(
          '暂无歌词',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return GestureDetector(
      onVerticalDragStart: widget.enableDrag ? _onDragStart : null,
      onVerticalDragUpdate: widget.enableDrag ? _onDragUpdate : null,
      onVerticalDragEnd: widget.enableDrag ? _onDragEnd : null,
      child: Container(
        color: Colors.transparent,
        child: ListView.builder(
          controller: _scrollController,
          physics: widget.enableDrag 
              ? const NeverScrollableScrollPhysics()
              : const ClampingScrollPhysics(),
          itemCount: widget.lyric!.lines.length,
          itemBuilder: (context, index) {
            final line = widget.lyric!.lines[index];
            final isActive = index == _currentIndex;

            return Container(
              height: widget.lineHeight,
              alignment: Alignment.center,
              child: Text(
                line.text,
                style: isActive ? widget.activeStyle : widget.normalStyle,
                textAlign: TextAlign.center,
              ),
            );
          },
        ),
      ),
    );
  }

  void _onDragStart(DragStartDetails details) {
    _isDragging = true;
    _dragOffset = 0;
  }

  void _onDragUpdate(DragUpdateDetails details) {
    _dragOffset += details.delta.dy;
    final offset = _scrollController.offset - details.delta.dy;
    _scrollController.jumpTo(offset.clamp(
      0.0,
      _scrollController.position.maxScrollExtent,
    ));
  }

  void _onDragEnd(DragEndDetails details) {
    _isDragging = false;
    // 如果拖动距离很小，认为是点击，恢复到当前��放位置
    if (_dragOffset.abs() < 10) {
      _scrollToCurrentIndex();
    }
  }
} 