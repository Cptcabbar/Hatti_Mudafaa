import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'game_marks.dart';
import 'theme_backdrop.dart';

/// Kısa, net kurallar ekranı. Ana menüdeki "?" düğmesinden açılır.
/// `docs/rules.md`'nin oyuncuya yönelik özeti — sıkmayacak kadar kısa.
class HowToPlayScreen extends StatelessWidget {
  const HowToPlayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          const ThemeBackdrop(),
          SafeArea(
            child: Column(
              children: [
                _Header(onClose: () => Navigator.of(context).maybePop()),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 460),
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(18, 16, 18, 20),
                          decoration: BoxDecoration(
                            color: AppPalette.surface.withValues(alpha: 0.94),
                            border: Border.all(color: AppPalette.line),
                          ),
                          child: const _Rules(),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 6, 12, 10),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Geri',
            onPressed: onClose,
            icon: const Icon(Icons.arrow_back),
            color: AppPalette.text,
          ),
          const SizedBox(width: 2),
          const Text(
            'NASIL OYNANIR',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              letterSpacing: 4,
              color: AppPalette.title,
            ),
          ),
        ],
      ),
    );
  }
}

class _Rules extends StatelessWidget {
  const _Rules();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Section(
          'AMAÇ',
          'Askerini tahtanın karşı ucundaki kenara ulaştır. İlk ulaşan '
              'kazanır — beraberlik yoktur.',
        ),
        _Section(
          'SIRA',
          'Mavi başlar, sırayla oynanır. Her turda ya askerini bir kare '
              'oynatırsın ya da bir engel koyarsın — ikisi birden değil, pas '
              'geçmek de yok.',
        ),
        _Section(
          'HAREKET',
          'Asker yukarı, aşağı, sağa veya sola 1 kare gider. Aradaki geçişte '
              'engel varsa ya da tahta biterse o yöne geçemezsin.\n\n'
              'Rakip askerle yan yana gelirsen üstünden atlarsın; arkası '
              'kapalıysa (engel veya tahta kenarı) yanından çapraz geçersin.',
        ),
        _EngellerSection(),
        _Section(
          'SÜRE',
          '"Süreli mod" açıkken her tur 30 saniye. Süre biterse askerin '
              'hedefe doğru kendiliğinden bir adım atar.',
        ),
        _Section(
          'GENİŞ ARAZİ',
          'Menüdeki "Geniş Arazi" bölümü farklı bir sahne açar: 9×9 karlı '
              'savaş alanı, oyuncu başına 11 kredi ve oyun başında sahaya '
              'serpiştirilmiş 2–4 ağaç. Ağaç karesine girilemez, üstünden '
              'atlanamaz — etrafından dolaşırsın. Her yeni oyunda ağaçlar '
              'başka yerlere düşer.',
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section(this.title, this.body);

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Label(title),
          const SizedBox(height: 6),
          Text(
            body,
            style: const TextStyle(
              color: AppPalette.text,
              fontSize: 13.5,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _EngellerSection extends StatelessWidget {
  const _EngellerSection();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _Label('ENGELLER'),
          const SizedBox(height: 8),
          const Row(
            children: [
              SupplyMark(size: 15),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Her oyuncunun 8 puanlık cephaneliği var; istediğin gibi '
                      'harcarsın.',
                  style: TextStyle(
                    color: AppPalette.text,
                    fontSize: 13.5,
                    height: 1.45,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _BarrierRow(
            mark: MineMark(size: 18, color: AppPalette.text),
            name: 'Mayın',
            cost: '1 puan',
            desc: 'iki kare arasındaki tek geçişi kapatır.',
          ),
          const SizedBox(height: 8),
          _BarrierRow(
            mark: WireMark(size: 18, color: AppPalette.text),
            name: 'Dikenli tel',
            cost: '2 puan',
            desc: 'aynı hat üzerinde arka arkaya iki geçişi kapatır.',
          ),
          const SizedBox(height: 12),
          const Text(
            'Tek kısıt: rakibin hedefine giden bütün yolları kapatamazsın — '
                'her zaman en az bir geçiş açık kalmalı. İki dikenli tel aynı '
                'noktada artı (+) şeklinde kesişemez.',
            style: TextStyle(
              color: AppPalette.text,
              fontSize: 13.5,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _BarrierRow extends StatelessWidget {
  const _BarrierRow({
    required this.mark,
    required this.name,
    required this.cost,
    required this.desc,
  });

  final Widget mark;
  final String name;
  final String cost;
  final String desc;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: SizedBox(width: 20, child: Center(child: mark)),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text.rich(
            TextSpan(
              style: const TextStyle(
                color: AppPalette.text,
                fontSize: 13.5,
                height: 1.45,
              ),
              children: [
                TextSpan(
                  text: '$name — ',
                  style: const TextStyle(
                    color: AppPalette.title,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                TextSpan(
                  text: '$cost · ',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                TextSpan(text: desc),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: AppPalette.amber,
        fontSize: 12,
        fontWeight: FontWeight.w800,
        letterSpacing: 3,
      ),
    );
  }
}
