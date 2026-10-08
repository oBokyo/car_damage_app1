import 'package:flutter/material.dart';

class AsyncListView<T> extends StatelessWidget {
  final bool isLoading;
  final bool hasError;
  final String errorMessage;
  final List<T> items;
  final VoidCallback onRetry;
  final Future<void> Function() onRefresh;
  final Widget Function(T item) itemBuilder;
  final String emptyMessage;

  const AsyncListView({
    super.key,
    required this.isLoading,
    required this.hasError,
    required this.errorMessage,
    required this.items,
    required this.onRetry,
    required this.onRefresh,
    required this.itemBuilder,
    required this.emptyMessage,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 800),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (hasError) {
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.wifi_off_rounded, color: Color(0xFF94A3B8), size: 48),
              const SizedBox(height: 16),
              Text(errorMessage, style: const TextStyle(color: Color(0xFF64748B))),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('ลองใหม่'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB), 
                  foregroundColor: Colors.white
                ),
              )
            ],
          ),
        ),
      );
    }

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800),
        child: RefreshIndicator(
          onRefresh: onRefresh,
          child: items.isEmpty
              ? SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Container(
                    height: MediaQuery.of(context).size.height * 0.6,
                    alignment: Alignment.center,
                    child: Text(emptyMessage, style: const TextStyle(color: Color(0xFF94A3B8))),
                  ),
                )
              : ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  itemBuilder: (context, index) => itemBuilder(items[index]),
                ),
        ),
      ),
    );
  }
}