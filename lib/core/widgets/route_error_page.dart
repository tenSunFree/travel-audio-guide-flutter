import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class RouteErrorPage extends StatelessWidget {
  const RouteErrorPage({super.key, required this.message, this.title = '資料錯誤'});

  final String message;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.grey),
              const SizedBox(height: 16),
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 24),
              TextButton.icon(
                onPressed: () => context.go('/'),
                icon: const Icon(Icons.home_outlined),
                label: const Text('回首頁'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
