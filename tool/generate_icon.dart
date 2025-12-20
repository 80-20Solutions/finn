// ignore_for_file: avoid_print
import 'dart:io';
import 'dart:math';
import 'package:image/image.dart' as img;

/// Generates app icons with Italian Brutalism aesthetic.
/// Run with: dart run tool/generate_icon.dart
void main() {
  print('Generating app icons...');

  // Colors from app_theme.dart
  const terracotta = 0xFFC75B39;
  const cream = 0xFFFAF7F2;
  const gold = 0xFFD4A84B;
  const parchment = 0xFFF5EDE0;

  // Generate main icon (1024x1024)
  final mainIcon = _generateMainIcon(1024, terracotta, cream, gold);
  File('assets/icons/app_icon.png').writeAsBytesSync(img.encodePng(mainIcon));
  print('Created: assets/icons/app_icon.png');

  // Generate adaptive foreground (1024x1024 with padding for safe zone)
  final foreground = _generateForeground(1024, terracotta, cream, gold);
  File('assets/icons/app_icon_foreground.png')
      .writeAsBytesSync(img.encodePng(foreground));
  print('Created: assets/icons/app_icon_foreground.png');

  print('Done! Now run: dart run flutter_launcher_icons');
}

img.Image _generateMainIcon(int size, int bg, int fg, int accent) {
  final image = img.Image(width: size, height: size);

  // Fill background with terracotta
  img.fill(image, color: img.ColorRgba8(
    (bg >> 16) & 0xFF,
    (bg >> 8) & 0xFF,
    bg & 0xFF,
    255,
  ));

  // Draw rounded rectangle background
  final cornerRadius = size ~/ 5;
  _drawRoundedRect(image, 0, 0, size, size, cornerRadius, bg);

  // Draw euro symbol (simplified geometric version)
  _drawEuroSymbol(image, size, fg);

  // Draw accent square in top-right
  final accentSize = size ~/ 7;
  final accentMargin = size ~/ 8;
  final accentRadius = size ~/ 25;
  _drawRoundedRect(
    image,
    size - accentMargin - accentSize,
    accentMargin,
    accentSize,
    accentSize,
    accentRadius,
    accent,
  );

  return image;
}

img.Image _generateForeground(int size, int bg, int fg, int accent) {
  final image = img.Image(width: size, height: size);

  // Transparent background for adaptive icon
  img.fill(image, color: img.ColorRgba8(0, 0, 0, 0));

  // Calculate safe zone (66% of total, centered)
  final safeZoneSize = (size * 0.66).toInt();
  final offset = (size - safeZoneSize) ~/ 2;

  // Draw terracotta background circle/rounded rect in safe zone
  final cornerRadius = safeZoneSize ~/ 5;
  _drawRoundedRect(
    image,
    offset,
    offset,
    safeZoneSize,
    safeZoneSize,
    cornerRadius,
    bg,
  );

  // Draw euro symbol
  _drawEuroSymbolCentered(image, size, safeZoneSize, offset, fg);

  // Draw accent square
  final accentSize = safeZoneSize ~/ 7;
  final accentMargin = offset + safeZoneSize ~/ 10;
  final accentRadius = safeZoneSize ~/ 30;
  _drawRoundedRect(
    image,
    offset + safeZoneSize - accentMargin - accentSize + offset,
    accentMargin,
    accentSize,
    accentSize,
    accentRadius,
    accent,
  );

  return image;
}

void _drawRoundedRect(
  img.Image image,
  int x,
  int y,
  int width,
  int height,
  int radius,
  int colorValue,
) {
  final color = img.ColorRgba8(
    (colorValue >> 16) & 0xFF,
    (colorValue >> 8) & 0xFF,
    colorValue & 0xFF,
    255,
  );

  // Draw filled rectangle
  for (var py = y; py < y + height; py++) {
    for (var px = x; px < x + width; px++) {
      // Check if point is inside rounded corners
      bool inside = true;

      // Top-left corner
      if (px < x + radius && py < y + radius) {
        final dx = px - (x + radius);
        final dy = py - (y + radius);
        inside = dx * dx + dy * dy <= radius * radius;
      }
      // Top-right corner
      else if (px >= x + width - radius && py < y + radius) {
        final dx = px - (x + width - radius);
        final dy = py - (y + radius);
        inside = dx * dx + dy * dy <= radius * radius;
      }
      // Bottom-left corner
      else if (px < x + radius && py >= y + height - radius) {
        final dx = px - (x + radius);
        final dy = py - (y + height - radius);
        inside = dx * dx + dy * dy <= radius * radius;
      }
      // Bottom-right corner
      else if (px >= x + width - radius && py >= y + height - radius) {
        final dx = px - (x + width - radius);
        final dy = py - (y + height - radius);
        inside = dx * dx + dy * dy <= radius * radius;
      }

      if (inside && px >= 0 && px < image.width && py >= 0 && py < image.height) {
        image.setPixel(px, py, color);
      }
    }
  }
}

void _drawEuroSymbol(img.Image image, int size, int colorValue) {
  final color = img.ColorRgba8(
    (colorValue >> 16) & 0xFF,
    (colorValue >> 8) & 0xFF,
    colorValue & 0xFF,
    255,
  );

  final centerX = size ~/ 2;
  final centerY = size ~/ 2;
  final outerRadius = (size * 0.32).toInt();
  final innerRadius = (size * 0.22).toInt();
  final strokeWidth = outerRadius - innerRadius;

  // Draw C shape (arc)
  for (var py = 0; py < size; py++) {
    for (var px = 0; px < size; px++) {
      final dx = px - centerX;
      final dy = py - centerY;
      final distance = sqrt(dx * dx + dy * dy);

      // Check if in ring
      if (distance >= innerRadius && distance <= outerRadius) {
        // Only draw right portion (C shape - opening on the right)
        final angle = atan2(dy.toDouble(), dx.toDouble());
        // Skip the right side opening (-45 to +45 degrees)
        if (angle.abs() > 0.7) {
          image.setPixel(px, py, color);
        }
      }
    }
  }

  // Draw two horizontal bars
  final barHeight = (size * 0.04).toInt();
  final barWidth = (size * 0.35).toInt();
  final barStartX = centerX - (size * 0.25).toInt();
  final barY1 = centerY - (size * 0.08).toInt();
  final barY2 = centerY + (size * 0.04).toInt();

  for (var y = barY1; y < barY1 + barHeight; y++) {
    for (var x = barStartX; x < barStartX + barWidth; x++) {
      if (x >= 0 && x < size && y >= 0 && y < size) {
        image.setPixel(x, y, color);
      }
    }
  }

  for (var y = barY2; y < barY2 + barHeight; y++) {
    for (var x = barStartX; x < barStartX + barWidth; x++) {
      if (x >= 0 && x < size && y >= 0 && y < size) {
        image.setPixel(x, y, color);
      }
    }
  }
}

void _drawEuroSymbolCentered(
  img.Image image,
  int totalSize,
  int safeSize,
  int offset,
  int colorValue,
) {
  final color = img.ColorRgba8(
    (colorValue >> 16) & 0xFF,
    (colorValue >> 8) & 0xFF,
    colorValue & 0xFF,
    255,
  );

  final centerX = totalSize ~/ 2;
  final centerY = totalSize ~/ 2;
  final outerRadius = (safeSize * 0.30).toInt();
  final innerRadius = (safeSize * 0.20).toInt();

  // Draw C shape (arc)
  for (var py = 0; py < totalSize; py++) {
    for (var px = 0; px < totalSize; px++) {
      final dx = px - centerX;
      final dy = py - centerY;
      final distance = sqrt(dx * dx + dy * dy);

      if (distance >= innerRadius && distance <= outerRadius) {
        final angle = atan2(dy.toDouble(), dx.toDouble());
        if (angle.abs() > 0.7) {
          image.setPixel(px, py, color);
        }
      }
    }
  }

  // Draw horizontal bars
  final barHeight = (safeSize * 0.035).toInt();
  final barWidth = (safeSize * 0.32).toInt();
  final barStartX = centerX - (safeSize * 0.22).toInt();
  final barY1 = centerY - (safeSize * 0.07).toInt();
  final barY2 = centerY + (safeSize * 0.035).toInt();

  for (var y = barY1; y < barY1 + barHeight; y++) {
    for (var x = barStartX; x < barStartX + barWidth; x++) {
      if (x >= 0 && x < totalSize && y >= 0 && y < totalSize) {
        image.setPixel(x, y, color);
      }
    }
  }

  for (var y = barY2; y < barY2 + barHeight; y++) {
    for (var x = barStartX; x < barStartX + barWidth; x++) {
      if (x >= 0 && x < totalSize && y >= 0 && y < totalSize) {
        image.setPixel(x, y, color);
      }
    }
  }
}
