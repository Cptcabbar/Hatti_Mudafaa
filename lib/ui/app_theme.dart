import 'package:flutter/material.dart';

/// "Cephe" teması — `docs/theme-bible.md` §3. Faz 5'teki tema motoru bu
/// değerleri config'ten okuyacak; şimdilik sabit. Tek vurgu rengi **amber**
/// (tehlike / mayın / seçili durum); gerisi soluk haki-toprak.
abstract final class AppPalette {
  /// En koyu zemin (scaffold, degradenin dibi).
  static const base = Color(0xFF0E0C08);

  /// Panel / kart yüzeyi.
  static const surface = Color(0xFF1A160F);

  /// Yükseltilmiş yüzey (seçilmemiş çip, alan girişi).
  static const surfaceHi = Color(0xFF241E14);

  /// İnce ayraç / kenar çizgisi.
  static const line = Color(0xFF574F35);

  /// Tek vurgu — tehlike, mayın, seçili düğme, birincil eylem.
  static const amber = Color(0xFFE0A72E);

  /// Amber'in sönük tonu (ikincil vurgular, çizgiler).
  static const amberDim = Color(0xFF8A6A22);

  /// Gövde metni.
  static const text = Color(0xFFB7AE97);

  /// Başlık / yüksek kontrast metin.
  static const title = Color(0xFFEDE7D6);

  /// Oyuncu 1 — "mavi" taraf: soluk arduvaz (asker miğfer boyasıyla aynı,
  /// bkz. `board_component.dart` `_Faction.p1`). Parlak takım rengi değil.
  static const p1 = Color(0xFF47607A);

  /// Oyuncu 2 — "kırmızı" taraf: soluk pas kırmızısı (`_Faction.p2`).
  static const p2 = Color(0xFF8A4A3E);
}

/// Uygulama geneli koyu tema. `main.dart` bunu `MaterialApp.theme`'e verir.
ThemeData buildAppTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: AppPalette.amber,
    brightness: Brightness.dark,
  ).copyWith(
    primary: AppPalette.amber,
    onPrimary: const Color(0xFF201404),
    secondary: AppPalette.p1,
    onSecondary: AppPalette.title,
    surface: AppPalette.base,
    onSurface: AppPalette.text,
    surfaceContainerHighest: AppPalette.surfaceHi,
    onSurfaceVariant: AppPalette.text,
    outline: AppPalette.line,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppPalette.base,
    splashColor: AppPalette.amber.withValues(alpha: 0.12),
    highlightColor: AppPalette.amber.withValues(alpha: 0.08),
    textSelectionTheme: const TextSelectionThemeData(
      cursorColor: AppPalette.amber,
      selectionHandleColor: AppPalette.amber,
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected)
            ? AppPalette.title
            : AppPalette.text,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected)
            ? AppPalette.amber
            : AppPalette.surfaceHi,
      ),
      trackOutlineColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected)
            ? AppPalette.amber
            : AppPalette.line,
      ),
    ),
  );
}
