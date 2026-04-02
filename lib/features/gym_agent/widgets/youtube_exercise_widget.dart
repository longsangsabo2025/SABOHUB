import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// YouTube video search widget — opens YouTube search in browser.
///
/// Why not embed? Flutter web YouTube embed has CORS issues and
/// adds iframe overhead. Link-out is faster, lighter, and reliable.
/// YouTube handles adaptive quality on their server — zero bandwidth cost.
class YouTubeExerciseButton extends StatelessWidget {
  final String exerciseName;
  final String? label;

  const YouTubeExerciseButton({
    super.key,
    required this.exerciseName,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () => _openYouTubeSearch(),
      icon: const Icon(Icons.play_circle_outline, color: Color(0xFFFF0000)),
      label: Text(
        label ?? '▶ Xem video hướng dẫn',
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        side: const BorderSide(color: Color(0xFFFF0000), width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _openYouTubeSearch() async {
    final query = Uri.encodeComponent('$exerciseName exercise form tutorial');
    final url = Uri.parse('https://www.youtube.com/results?search_query=$query');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }
}

/// Inline YouTube thumbnail card — shows a preview and opens on tap.
class YouTubeExerciseCard extends StatelessWidget {
  final String exerciseName;

  const YouTubeExerciseCard({super.key, required this.exerciseName});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final query =
            Uri.encodeComponent('$exerciseName exercise form tutorial');
        final url =
            Uri.parse('https://www.youtube.com/results?search_query=$query');
        if (await canLaunchUrl(url)) {
          await launchUrl(url, mode: LaunchMode.externalApplication);
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF0F0),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFFFCDD2)),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: const Color(0xFFFF0000),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.play_arrow, color: Colors.white, size: 32),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '🎬 Video hướng dẫn form',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Xem trên YouTube: $exerciseName',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(Icons.open_in_new, size: 18, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
