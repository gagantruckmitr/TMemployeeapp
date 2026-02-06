import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../../core/config/api_config.dart';

class TermsPolicyService {
  static Future<void> showPrivacyPolicy(BuildContext context) async {
    await _fetchAndShow(context, ApiConfig.privacyPolicyApi, 'Privacy Policy');
  }

  static Future<void> showTermsAndConditions(BuildContext context) async {
    await _fetchAndShow(
      context,
      ApiConfig.termsAndConditionsApi,
      'Terms & Conditions',
    );
  }

  static Future<void> _fetchAndShow(
    BuildContext context,
    String url,
    String title,
  ) async {
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Loading...'),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      final uri = Uri.parse(url);
      final response = await http.get(uri).timeout(const Duration(seconds: 10));

      if (context.mounted) Navigator.pop(context); // Dismiss loading

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == true && data['data'] != null) {
          final htmlContent = data['data'].toString();
          if (context.mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SimpleHtmlViewerScreen(
                  title: title,
                  htmlContent: htmlContent,
                ),
              ),
            );
          }
        } else {
          throw Exception(data['message'] ?? 'Failed to load data');
        }
      } else {
        throw Exception('HTTP ${response.statusCode}');
      }
    } catch (e) {
      try {
        if (context.mounted && Navigator.canPop(context)) {
          // Check if the loading dialog is the top route, if so pop it
          // This strict check is hard, but usually safe to rely on flow
          // If we are here, likely the dialog is still up if we didn't pop above
        }
      } catch (_) {}

      print('Error fetching $title: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load $title: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

class SimpleHtmlViewerScreen extends StatelessWidget {
  final String title;
  final String htmlContent;

  const SimpleHtmlViewerScreen({
    super.key,
    required this.title,
    required this.htmlContent,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title, style: const TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: _HtmlRenderer(htmlContent: htmlContent),
      ),
    );
  }
}

class _HtmlRenderer extends StatelessWidget {
  final String htmlContent;

  const _HtmlRenderer({required this.htmlContent});

  @override
  Widget build(BuildContext context) {
    // Basic cleaning
    String content = htmlContent;

    // Remove DOCTYPE, html, head, body tags (keep body content)
    // This is a very rough parser specialized for the expected input
    final bodyMatch = RegExp(
      r'<body[^>]*>(.*?)</body>',
      dotAll: true,
    ).firstMatch(content);
    if (bodyMatch != null) {
      content = bodyMatch.group(1) ?? content;
    }

    // Split into lines/blocks by generic block tags for simplified rendering
    // We will render a Column of widgets
    List<Widget> widgets = [];

    // Helper to add text
    void addText(
      String text, {
      double fontSize = 14,
      FontWeight fontWeight = FontWeight.normal,
      double topMargin = 8,
    }) {
      if (text.trim().isEmpty) return;
      widgets.add(
        Padding(
          padding: EdgeInsets.only(top: topMargin, bottom: 4),
          child: Text(
            text.trim(),
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: fontWeight,
              color: Colors.black87,
              height: 1.5,
            ),
          ),
        ),
      );
    }

    // Tokenize by Block Tags
    // We'll just regex replace standard tags with markers we can split on,
    // or iterate through the string.
    // Given the complexity, let's try a regex replace strategy to meaningful plain text with specific delimiters
    // WARNING: This is a "good enough" approximation for a specific known HTML structure (Header, P, UL/LI)

    // 1. Headers
    content = content.replaceAllMapped(
      RegExp(r'<(h[1-6])>(.*?)</\1>', dotAll: true),
      (match) => '\n[[HEADER:${match.group(1)}]]${match.group(2)}[[/HEADER]]\n',
    );

    // 2. Paragraphs
    content = content.replaceAllMapped(
      RegExp(r'<p>(.*?)</p>', dotAll: true),
      (match) => '\n[[P]]${match.group(1)}[[/P]]\n',
    );

    // 3. Lists
    content = content.replaceAll('<ul>', '\n[[UL]]');
    content = content.replaceAll('</ul>', '[[/UL]]\n');
    content = content.replaceAllMapped(
      RegExp(r'<li>(.*?)</li>', dotAll: true),
      (match) => '\n[[LI]]${match.group(1)}[[/LI]]',
    );

    // 4. Update Breaks
    content = content.replaceAll('<br>', '\n');
    content = content.replaceAll('<br/>', '\n');
    content = content.replaceAll('<br />', '\n');

    // 5. Clean remaining tags (like strong, em, div, spans inside) - rudimentary
    // We will handle strong in the Render logic if possible, otherwise strip
    // For now, let's strip other tags to keep it clean text, but try to keep 'strong' logic if we can?
    // Let's just strip others for safety to avoid garbage text

    // Split by our custom markers
    final lines = content.split('\n');

    for (String line in lines) {
      if (line.trim().isEmpty) continue;

      if (line.contains('[[HEADER:h1]]')) {
        String text = _stripTags(
          line.replaceAll('[[HEADER:h1]]', '').replaceAll('[[/HEADER]]', ''),
        );
        addText(text, fontSize: 22, fontWeight: FontWeight.bold, topMargin: 20);
      } else if (line.contains('[[HEADER:h2]]')) {
        String text = _stripTags(
          line.replaceAll('[[HEADER:h2]]', '').replaceAll('[[/HEADER]]', ''),
        );
        addText(text, fontSize: 18, fontWeight: FontWeight.bold, topMargin: 16);
      } else if (line.contains('[[HEADER:h3]]')) {
        String text = _stripTags(
          line.replaceAll('[[HEADER:h3]]', '').replaceAll('[[/HEADER]]', ''),
        );
        addText(text, fontSize: 16, fontWeight: FontWeight.bold, topMargin: 12);
      } else if (line.contains('[[P]]')) {
        String text = line.replaceAll('[[P]]', '').replaceAll('[[/P]]', '');
        widgets.add(
          _buildRichText(text),
        ); // Use rich text for P to support bold inside
      } else if (line.contains('[[LI]]')) {
        String text = line.replaceAll('[[LI]]', '').replaceAll('[[/LI]]', '');
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 4, left: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '• ',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Expanded(child: _buildRichText(text)),
              ],
            ),
          ),
        );
      } else {
        // Fallback for untagged text
        if (!line.contains('[[UL]]') && !line.contains('[[/UL]]')) {
          widgets.add(_buildRichText(line));
        }
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }

  // Helper to strip all remaining XML tags
  String _stripTags(String htmlString) {
    return htmlString.replaceAll(RegExp(r'<[^>]*>'), '');
  }

  // Helper to build RichText from string with <strong> tags
  Widget _buildRichText(String text) {
    List<TextSpan> spans = [];

    // This regex splits by strong tags, keeping the delimiters to know where they are
    // But Dart split doesn't keep delimiters easily.
    // We will just match strong tags and iterate.

    // Simple implementation:
    // 1. Replace <strong> with [[B]]
    String processed = text
        .replaceAll('<strong>', '[[B]]')
        .replaceAll('</strong>', '[[/B]]')
        .replaceAll('<b>', '[[B]]')
        .replaceAll('</b>', '[[/B]]')
        .replaceAll('<em>', '[[I]]')
        .replaceAll('</em>', '[[/I]]');

    // Remove other tags
    processed = _stripTags(processed);

    // Now split by [[B]]
    final parts = processed.split('[[B]]');

    for (int i = 0; i < parts.length; i++) {
      String part = parts[i];
      if (i == 0) {
        // First part is always normal (unless string started with bold, then it's empty)
        if (part.isNotEmpty) _addSpan(spans, part, false);
      } else {
        // Subsequent parts started with a [[B]].
        // They might contain [[/B]].
        if (part.contains('[[/B]]')) {
          final split = part.split('[[/B]]');
          _addSpan(spans, split[0], true); // Bold part
          if (split.length > 1) _addSpan(spans, split[1], false); // Remainder
        } else {
          // No closing tag? Treat entire as bold
          _addSpan(spans, part, true);
        }
      }
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(
            fontSize: 14,
            color: Colors.black87,
            height: 1.5,
          ),
          children: spans,
        ),
      ),
    );
  }

  void _addSpan(List<TextSpan> spans, String text, bool isBold) {
    // Handle Entities basics
    String dec = text
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"');

    spans.add(
      TextSpan(
        text: dec,
        style: TextStyle(
          fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }
}
