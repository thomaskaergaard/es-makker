import 'package:flutter/material.dart';

/// Screen that displays the rules for the Es Makker card game.
class RulesScreen extends StatelessWidget {
  const RulesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Regler – Es Makker'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _RuleSection(
                icon: Icons.info_outline,
                title: 'Om spillet',
                body:
                    'Es Makker er et dansk stikspil for 4–6 spillere, der spilles '
                    'med et fuldt kortdæk (52 kort). Målet er at samle flest mulige '
                    'point over flere runder ved at vinde stik.',
              ),
              _RuleSection(
                icon: Icons.people_outline,
                title: 'Spillere og makker-par',
                body:
                    'I starten af hver runde vælger én spiller (spilleren) en makker '
                    'ved at melde et bestemt kort – f.eks. "Spar Es". Den spiller der '
                    'har kortet på hånden er makkerens partner for den runde.\n\n'
                    'Spilleren og makkeren udgør et par og spiller mod de øvrige spillere. '
                    'Makkeren forbliver hemmelig indtil vedkommendes kort spilles.',
              ),
              _RuleSection(
                icon: Icons.style_outlined,
                title: 'Kortdæk og uddeling',
                body:
                    'Der bruges et fuldt kortdæk med 52 kort. Kortene deles ud til '
                    'alle spillere. Antallet af kort per spiller afhænger af spillerantal:\n\n'
                    '• 4 spillere: 13 kort hver\n'
                    '• 5 spillere: 10 kort hver (2 kort tages ud)\n'
                    '• 6 spillere: 8 kort hver (4 kort tages ud)\n\n'
                    'Trumf afgøres ved opbud eller aftale inden runden starter.',
              ),
              _RuleSection(
                icon: Icons.swap_horiz,
                title: 'Spillets gang',
                body:
                    'Spilleren til venstre for giveren lægger ud. Spillet fortsætter '
                    'med uret. Hvert stik vindes af den spiller der lægger det højeste '
                    'kort i den udlagte farve – med mindre en trumf spilles.\n\n'
                    'Vinderen af et stik lægger ud til det næste stik. '
                    'Stikkene tælles op til sidst og omsættes til point.',
              ),
              _RuleSection(
                icon: Icons.calculate_outlined,
                title: 'Pointtælling',
                body:
                    'Makker-parrets samlede antal vundne stik afgør resultatet:\n\n'
                    '• Parret opfylder sin melding → begge spillere får positive point\n'
                    '• Parret opfylder ikke sin melding → begge spillere får negative point\n\n'
                    'Modstanderne scorer det modsatte beløb: hvis makker-parret vinder '
                    'point, taber modstanderne tilsvarende point, og omvendt.\n\n'
                    'Det præcise pointantal aftales inden spillet begynder.',
              ),
              _RuleSection(
                icon: Icons.emoji_events_outlined,
                title: 'At vinde',
                body:
                    'Spillet afsluttes efter et aftalt antal runder eller når en '
                    'spiller når et bestemt pointmål. Den spiller med flest point '
                    'vinder spillet.',
              ),
              _RuleSection(
                icon: Icons.smartphone_outlined,
                title: 'Brug af appen',
                body:
                    'Appen holder styr på point på tværs af runder:\n\n'
                    '1. Opret spillere i opsætningsskærmen.\n'
                    '2. Vælg spiller og makker (valgfrit) inden hver runde.\n'
                    '3. Appen synkroniserer automatisk makker-parrets point og '
                    'sætter modstandernes point til det modsatte.\n'
                    '4. Tryk "Gem runde" for at gemme rundens point.\n'
                    '5. Se den løbende stilling under fanen "Stilling".',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A card that displays a single rule section with an icon, title, and body text.
class _RuleSection extends StatelessWidget {
  const _RuleSection({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: theme.colorScheme.primary, size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            Text(
              body,
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}
