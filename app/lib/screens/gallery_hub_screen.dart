import 'package:flutter/material.dart';

import 'archive_screen.dart';
import 'practice_room_screen.dart';
import 'research_laboratory_screen.dart';

class GalleryHubScreen extends StatelessWidget {
  const GalleryHubScreen({super.key});

  static const destinations = [
    ('Practice Rooms', Icons.auto_stories_outlined),
    ('Archive', Icons.inventory_2_outlined),
    ('Research Laboratory', Icons.science_outlined),
    ('Completed Works', Icons.collections_bookmark_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1B1D1E), Color(0xFF0A0B0C)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 980),
              child: Padding(
                padding: const EdgeInsets.all(36),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('THE INNER GALLERY', style: TextStyle(color: Color(0xFFC09A52), fontSize: 12, letterSpacing: 3.5)),
                    const SizedBox(height: 10),
                    const Text('Gallery Hall', style: TextStyle(color: Color(0xFFF1E7D0), fontSize: 38)),
                    const SizedBox(height: 8),
                    const Text('A first glimpse into the rooms beyond the entrance.', style: TextStyle(color: Color(0xFFA9A294), fontSize: 16)),
                    const SizedBox(height: 34),
                    Expanded(
                      child: GridView.builder(
                        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 360,
                          mainAxisExtent: 190,
                          crossAxisSpacing: 20,
                          mainAxisSpacing: 20,
                        ),
                        itemCount: destinations.length,
                        itemBuilder: (context, index) {
                          final destination = destinations[index];
                          return _GalleryFrame(
                            title: destination.$1,
                            icon: destination.$2,
                            onTap: destination.$1 == 'Practice Rooms'
                                ? () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const PracticeRoomScreen()))
                              : destination.$1 == 'Archive'
                                ? () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const ArchiveScreen()))
                              : destination.$1 == 'Research Laboratory'
                                ? () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const ResearchLaboratoryScreen()))
                                : null,
                          );
                        },
                      ),
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
}

class _GalleryFrame extends StatelessWidget {
  const _GalleryFrame({required this.title, required this.icon, this.onTap});

  final String title;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: onTap != null,
      label: onTap == null ? title : 'Open $title',
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF151718),
            border: Border.all(color: const Color(0xFF876E43), width: 2),
            boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 14, offset: Offset(0, 6))],
          ),
          padding: const EdgeInsets.all(9),
          child: DecoratedBox(
            decoration: BoxDecoration(border: Border.all(color: const Color(0xFF4E422F)), color: const Color(0xFF202222)),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: const Color(0xFFC09A52), size: 40),
                const SizedBox(height: 18),
                Text(title, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFFE0D3B8), fontSize: 17)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
