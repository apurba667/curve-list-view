import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'curve_list_view.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Curved ListView Demo',
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Image.asset(
            'assets/Gemini_Generated_Image_1lqent1lqent1lqe.jpg',
            width: Get.width,
            height: Get.height,
            fit: BoxFit.cover,
          ),
          const CurvedListView(),
        ],
      ),
    );
  }
}

