import 'package:flutter/material.dart';

class ResponsiveImage extends StatelessWidget {
  final String imageUrl;
  final double? maxHeight;
  final double? maxWidth;
  final BoxFit fit;
  final Widget? errorWidget;
  final Widget? loadingWidget;

  const ResponsiveImage({
    super.key,
    required this.imageUrl,
    this.maxHeight,
    this.maxWidth,
    this.fit = BoxFit.contain,
    this.errorWidget,
    this.loadingWidget,
  });

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final screenHeight = screenSize.height;
    final screenWidth = screenSize.width;

    // Calculate maximum dimensions based on screen size
    final effectiveMaxHeight = maxHeight ?? screenHeight * 0.4;
    final effectiveMaxWidth = maxWidth ?? screenWidth * 0.9;

    return Container(
      constraints: BoxConstraints(
        maxHeight: effectiveMaxHeight,
        maxWidth: effectiveMaxWidth,
      ),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          imageUrl,
          fit: fit,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return loadingWidget ??
                Container(
                  height: effectiveMaxHeight,
                  width: effectiveMaxWidth,
                  color: Colors.grey[200],
                  child: const Center(child: CircularProgressIndicator()),
                );
          },
          errorBuilder: (context, error, stackTrace) {
            return errorWidget ??
                Container(
                  height: effectiveMaxHeight,
                  width: effectiveMaxWidth,
                  color: Colors.grey[200],
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.broken_image, size: 40, color: Colors.grey),
                        SizedBox(height: 8),
                        Text(
                          'Image not available',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                );
          },
        ),
      ),
    );
  }
}

class GameQuestionImage extends StatelessWidget {
  final String imageUrl;
  final bool isInDialog;

  const GameQuestionImage({
    super.key,
    required this.imageUrl,
    this.isInDialog = false,
  });

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final screenHeight = screenSize.height;
    final screenWidth = screenSize.width;

    // Different sizing for dialog vs full screen
    final maxHeight = isInDialog
        ? screenHeight *
              0.3 // Smaller in dialogs
        : screenHeight * 0.4; // Larger in full game screen

    final maxWidth = screenWidth * 0.9;

    return ResponsiveImage(
      imageUrl: imageUrl,
      maxHeight: maxHeight,
      maxWidth: maxWidth,
      fit: BoxFit.contain,
    );
  }
}

class ImagePreview extends StatelessWidget {
  final String imageUrl;
  final VoidCallback? onRemove;

  const ImagePreview({super.key, required this.imageUrl, this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ResponsiveImage(
          imageUrl: imageUrl,
          maxHeight: 150,
          maxWidth: double.infinity,
          fit: BoxFit.cover,
        ),
        if (onRemove != null)
          Positioned(
            top: 8,
            right: 8,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 16),
              ),
            ),
          ),
      ],
    );
  }
}
