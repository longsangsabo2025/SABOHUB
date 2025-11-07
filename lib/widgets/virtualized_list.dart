import 'package:flutter/material.dart';

/// High-Performance Virtualized List Widget
/// For handling large datasets efficiently
class VirtualizedList<T> extends StatefulWidget {
  final List<T> items;
  final Widget Function(BuildContext, T, int) itemBuilder;
  final double itemHeight;
  final EdgeInsets? padding;
  final ScrollController? controller;
  final void Function()? onEndReached;
  
  const VirtualizedList({
    super.key,
    required this.items,
    required this.itemBuilder,
    required this.itemHeight,
    this.padding,
    this.controller,
    this.onEndReached,
  });
  
  @override
  State<VirtualizedList<T>> createState() => _VirtualizedListState<T>();
}

class _VirtualizedListState<T> extends State<VirtualizedList<T>> {
  late ScrollController _scrollController;
  
  @override
  void initState() {
    super.initState();
    _scrollController = widget.controller ?? ScrollController();
    _scrollController.addListener(_onScroll);
  }
  
  @override
  void dispose() {
    if (widget.controller == null) {
      _scrollController.dispose();
    }
    super.dispose();
  }
  
  void _onScroll() {
    if (_scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent - 200) {
      widget.onEndReached?.call();
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: _scrollController,
      padding: widget.padding,
      itemCount: widget.items.length,
      itemExtent: widget.itemHeight,
      cacheExtent: widget.itemHeight * 10, // Cache 10 items
      itemBuilder: (context, index) {
        return RepaintBoundary(
          child: widget.itemBuilder(context, widget.items[index], index),
        );
      },
    );
  }
}
