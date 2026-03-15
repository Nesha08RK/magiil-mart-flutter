import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final onPrimary = theme.colorScheme.onPrimary;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('About Magiil Mart'),
        leading: const BackButton(),
        elevation: 0,
        backgroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [

            // Banner
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    primary.withAlpha(242),
                    primary.withAlpha(179),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: primary.withAlpha(64),
                    blurRadius: 18,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Magiil Mart',
                    style: theme.textTheme.headlineLarge?.copyWith(
                      color: onPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your Trusted Neighborhood Supermarket',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: onPrimary.withAlpha(230),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // About Us
            _SectionCard(
              title: 'About Us',
              icon: Icons.info_outline,
              child: const Text(
                'Magiil Mart is a trusted supermarket located on Erode Road, Pallipalayam, Tamil Nadu. We provide fresh groceries, vegetables, fruits, daily essentials, and household products at affordable prices.',
                style: TextStyle(fontSize: 15, height: 1.5),
              ),
            ),

            const SizedBox(height: 20),

            // Store Information
            Card(
              elevation: 6,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: const [
                    _InfoRow(
                      icon: Icons.location_on,
                      title: 'Location',
                      value: 'Erode Rd, Pallipalayam, Tamil Nadu 638006',
                    ),
                    Divider(),
                    _InfoRow(
                      icon: Icons.category,
                      title: 'Category',
                      value: 'Supermarket',
                    ),
                    Divider(),
                    _InfoRow(
                      icon: Icons.local_grocery_store,
                      title: 'Services',
                      value: 'Fresh Groceries, Daily Essentials, Home Delivery',
                    ),
                    Divider(),
                    _InfoRow(
                      icon: Icons.access_time,
                      title: 'Timings',
                      value: '9:00 AM – 10:30 PM',
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Why Choose Us
            Card(
              elevation: 6,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [

                    Row(
                      children: [
                        const Icon(Icons.thumb_up, color: Color(0xFF5A2E4A)),
                        const SizedBox(width: 10),
                        Text(
                          'Why Choose Us',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    GridView(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        mainAxisExtent: 120,
                      ),
                      children: const [
                        _FeatureCard(
                          icon: Icons.park,
                          title: 'Fresh Products',
                          subtitle: 'Quality fresh produce',
                        ),
                        _FeatureCard(
                          icon: Icons.attach_money,
                          title: 'Affordable Prices',
                          subtitle: 'Best prices for your budget',
                        ),
                        _FeatureCard(
                          icon: Icons.delivery_dining,
                          title: 'Fast Delivery',
                          subtitle: 'Quick home delivery',
                        ),
                        _FeatureCard(
                          icon: Icons.sentiment_satisfied,
                          title: 'Friendly Service',
                          subtitle: 'Helpful staff',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Contact
            Card(
              elevation: 6,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: const [
                    _ContactRow(
                      icon: Icons.phone,
                      label: 'Phone',
                      value: '9842062624, 9445883008',
                    ),
                    Divider(),
                    _ContactRow(
                      icon: Icons.email,
                      label: 'Email',
                      value: 'magiilmartppm@gmail.com',
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            Center(
              child: Text(
                'Thank you for shopping with Magiil Mart',
                style: theme.textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Icon(icon, color: const Color(0xFF5A2E4A)),
                const SizedBox(width: 10),
                Text(title,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF5A2E4A)),
      title: Text(title),
      subtitle: Text(value),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: const Color(0xFF5A2E4A)),
            const SizedBox(height: 8),
            Text(title,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 4),
            Text(subtitle, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _ContactRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF5A2E4A)),
      title: Text(label),
      subtitle: Text(value),
    );
  }
}