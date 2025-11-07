import 'package:flutter/material.dart';

/// Pagination Mixin for Large Lists
mixin PaginationMixin<T extends StatefulWidget> on State<T> {
  int currentPage = 1;
  int itemsPerPage = 20;
  bool isLoadingMore = false;
  bool hasMoreData = true;
  
  void loadNextPage() {
    if (isLoadingMore || !hasMoreData) return;
    
    setState(() {
      isLoadingMore = true;
    });
    
    // Override in your widget
    onLoadMore();
  }
  
  void onLoadMore(); // Override this method
  
  void resetPagination() {
    setState(() {
      currentPage = 1;
      hasMoreData = true;
      isLoadingMore = false;
    });
  }
}
