import 'package:flutter/material.dart';

class RapportTestPage extends StatefulWidget {
  const RapportTestPage({super.key});

  @override
  State<RapportTestPage> createState() => _RapportTestPageState();
}

class _RapportTestPageState extends State<RapportTestPage> {
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Swipe test")),
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              physics: const BouncingScrollPhysics(), // 👈 swipe aktiveret
              itemCount: 3, // bare tre sider til test
              itemBuilder: (context, index) {
                return _TestSkarm("Anlæg $index");
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// En helt simpel side
class _TestSkarm extends StatelessWidget {
  final String navn;
  const _TestSkarm(this.navn);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        scrollDirection: Axis.vertical,           // kun lodret
        physics: const ClampingScrollPhysics(),   // ingen horisontal konflikt
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(navn, style: const TextStyle(fontSize: 32)),
            const SizedBox(height: 400, child: ColoredBox(color: Colors.green)),
            const SizedBox(height: 400, child: ColoredBox(color: Colors.blue)),
            const SizedBox(height: 400, child: ColoredBox(color: Colors.orange)),
          ],
        ),
      ),
    );
  }
}