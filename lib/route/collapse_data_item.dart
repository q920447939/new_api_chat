import 'package:flutter/material.dart';

class CollapseDataItem {
  CollapseDataItem({
    required this.headerValue,
    required this.items,
    this.isExpanded = false,
  });

  final String headerValue;
  final List<Item> items;
  bool isExpanded;
}



class Item {
  final String title;
  final String page;
  final Widget targetPage;
  Item({required this.title, required this.page, required this.targetPage});
}
