import 'dart:async';
import 'package:flutter/material.dart';

import 'product_list_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final PageController _bannerController;
  late Timer _bannerTimer;
  int _currentBannerIndex = 0;

  // Default banner images: you can replace these with asset paths
  // e.g. 'assets/images/banners/banner1.jpg'
  final List<String> bannerImages = [
    'assets/images/banners/banner1.jpg',
    'assets/images/banners/banner2.jpg',
    'assets/images/banners/banner3.jpg',
  ];

  @override
  void initState() {
    super.initState();
    _bannerController = PageController();
    _bannerTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (_bannerController.hasClients && bannerImages.isNotEmpty) {
        final next = (_currentBannerIndex + 1) % bannerImages.length;
        _bannerController.animateToPage(
          next,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _bannerTimer.cancel();
    _bannerController.dispose();
    super.dispose();
  }

  Widget _buildImage(String src) {
    if (src.startsWith('http')) {
      return Image.network(src, fit: BoxFit.cover, width: double.infinity, height: double.infinity);
    }
    return Image.asset(src, fit: BoxFit.cover, width: double.infinity, height: double.infinity);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF9F7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 2,
        centerTitle: true,
        title: const Text(
          'Magiil Mart',
          style: TextStyle(
            color: Color(0xFF6B3E5E),
            fontSize: 22,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            // Search bar (tap to open product list)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ProductListScreen(category: 'All'),
                    ),
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 12,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                    child: Row(
                      children: [
                        Icon(Icons.search, color: Color(0xFFA0789A)),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text('Search for products...', style: TextStyle(color: Colors.grey)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Banner: fixed height + BoxFit.cover
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                height: 172,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Stack(
                    children: [
                      PageView.builder(
                        controller: _bannerController,
                        onPageChanged: (i) => setState(() => _currentBannerIndex = i),
                        itemCount: bannerImages.length,
                        itemBuilder: (context, index) {
                          return _buildImage(bannerImages[index]);
                        },
                      ),
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Colors.transparent, Colors.black.withOpacity(0.16)],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 8),

            // Indicator
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  bannerImages.length,
                  (i) => Container(
                    width: _currentBannerIndex == i ? 22 : 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: _currentBannerIndex == i ? const Color(0xFF6B3E5E) : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Categories
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Shop by Category', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  InkWell(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProductListScreen(category: 'All'))),
                    child: const Text('View all', style: TextStyle(color: Color(0xFF6B3E5E), fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 1,
                children: const [
                  CategoryCard(title: 'Vegetables', imagePath: 'assets/images/categories/vegetables.jpg'),
                  CategoryCard(title: 'Fruits', imagePath: 'assets/images/categories/fruits.jpg'),
                  CategoryCard(title: 'Groceries', imagePath: 'assets/images/categories/groceries.jpg'),
                  CategoryCard(title: 'Snacks', imagePath: 'assets/images/categories/snacks.jpg'),
                ],
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class CategoryCard extends StatelessWidget {
  final String title;
  final String imagePath;

  const CategoryCard({super.key, required this.title, required this.imagePath});

  @override
  Widget build(BuildContext context) {
    Widget img;
    if (imagePath.startsWith('http')) {
      img = Image.network(imagePath, fit: BoxFit.cover);
    } else {
      img = Image.asset(imagePath, fit: BoxFit.cover);
    }

    return AspectRatio(
      aspectRatio: 1,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProductListScreen(category: title))),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Stack(
            fit: StackFit.expand,
            children: [
              img,
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withOpacity(0.4)],
                  ),
                ),
              ),
              Center(
                child: Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
