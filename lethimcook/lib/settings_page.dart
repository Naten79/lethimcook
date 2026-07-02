import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_theme.dart';
import 'settings_service.dart';

class SettingsPage extends StatefulWidget {
  final VoidCallback onDisplayChanged;
  const SettingsPage({super.key, required this.onDisplayChanged});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _compact = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final v = await SettingsService.isCompact();
    if (mounted) setState(() => _compact = v);
  }

  Future<void> _select(bool compact) async {
    await SettingsService.setCompact(compact);
    setState(() => _compact = compact);
    widget.onDisplayChanged();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(
                'Paramètres',
                style: GoogleFonts.dmSerifDisplay(
                  fontSize: 30,
                  fontStyle: FontStyle.italic,
                  color: kTextPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'AFFICHAGE',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: kTextSecondary,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _ModeCard(
                      label: 'Mode compact',
                      subtitle: '2 recettes par ligne',
                      compact: true,
                      selected: _compact,
                      onTap: () => _select(true),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ModeCard(
                      label: 'Mode aéré',
                      subtitle: '1 recette par ligne',
                      compact: false,
                      selected: !_compact,
                      onTap: () => _select(false),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 36),
              const Text(
                'À PROPOS',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: kTextSecondary,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [kPrimary, Color(0xFFFF8C42)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.local_fire_department,
                          color: Colors.white, size: 30),
                    ),
                    const SizedBox(width: 16),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('LetHimCook',
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: kTextPrimary)),
                        SizedBox(height: 2),
                        Text('Version 1.0',
                            style:
                                TextStyle(color: kTextSecondary, fontSize: 13)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Carte de sélection de mode ────────────────────────────────────────────────

class _ModeCard extends StatelessWidget {
  final String label;
  final String subtitle;
  final bool compact;
  final bool selected;
  final VoidCallback onTap;

  const _ModeCard({
    required this.label,
    required this.subtitle,
    required this.compact,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accent = selected ? kPrimary : const Color(0xFFCEC0A0);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? kPrimary.withValues(alpha: 0.07) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? kPrimary : kBorder,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _GridPreview(compact: compact, color: accent),
            const SizedBox(height: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: selected ? kPrimary : kTextPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 11, color: kTextSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _GridPreview extends StatelessWidget {
  final bool compact;
  final Color color;
  const _GridPreview({required this.compact, required this.color});

  @override
  Widget build(BuildContext context) {
    final bg = color.withValues(alpha: 0.28);
    const r = BorderRadius.all(Radius.circular(5));
    if (compact) {
      return SizedBox(
        height: 42,
        child: Row(
          children: [
            Expanded(child: Container(decoration: BoxDecoration(color: bg, borderRadius: r))),
            const SizedBox(width: 4),
            Expanded(child: Container(decoration: BoxDecoration(color: bg, borderRadius: r))),
          ],
        ),
      );
    } else {
      return SizedBox(
        height: 42,
        child: Column(
          children: [
            Expanded(child: Container(decoration: BoxDecoration(color: bg, borderRadius: r))),
            const SizedBox(height: 4),
            Expanded(child: Container(decoration: BoxDecoration(color: bg, borderRadius: r))),
          ],
        ),
      );
    }
  }
}
