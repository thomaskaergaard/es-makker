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
                    'alle spillere, og de resterende kort lægges i midten som en talon:\n\n'
                    '• 4 spillere: 12 kort hver + 4 i talonén\n'
                    '• 5 spillere: 10 kort hver + 2 i talonén\n'
                    '• 6 spillere: 8 kort hver + 4 i talonén\n\n'
                    'Talonén ligger med bagsiden opad. Den spiller der vinder opbuddet '
                    'får lov at se talonén, inden runden begynder.',
              ),
              _RuleSection(
                icon: Icons.gavel_outlined,
                title: 'Opbud',
                body:
                    'Inden kortene spilles, byder spillerne på, hvor mange stik de '
                    'mener at kunne vinde sammen med deres makker.\n\n'
                    'Mulige bud (fra lavest til højest):\n'
                    '  2 i 9  –  3 i 9  –  4 i 9  –  2 i 10  –  3 i 10  –  4 i 10\n\n'
                    '"2 i 9" betyder, at makkerparet skal vinde mindst 9 stik, og at '
                    'hvert stik tæller 2 point.\n\n'
                    'Hvert bud skal overbyde det forrige. Det er tilladt at passe. '
                    'Den spiller der vinder opbuddet, er spilleren (melder) for '
                    'den pågældende runde. Alle andre spillere kan give pas hvis '
                    'de ikke vil byde.',
              ),
              _RuleSection(
                icon: Icons.swap_horiz,
                title: 'Spillets gang',
                body:
                    'Vinderen af opbuddet vælger trumf og melder et kort for at '
                    'identificere sin makker. Spilleren til venstre for den der melder '
                    'lægger ud. Spillet fortsætter med uret.\n\n'
                    'Hvert stik vindes af den spiller der lægger det højeste kort i '
                    'den udlagte farve – med mindre en trumf spilles.\n\n'
                    'Vinderen af et stik lægger ud til det næste stik. '
                    'Stikkene tælles op til sidst og omsættes til point.',
              ),
              _RuleSection(
                icon: Icons.calculate_outlined,
                title: 'Pointtælling',
                body:
                    'Makker-parrets resultat beregnes ud fra opbuddet:\n\n'
                    '• Parret vinder mindst det meldte antal stik → begge spillere '
                    'får tricksNeeded × pointsPerTrick point.\n'
                    '  Eks.: "2 i 9" opfyldt → 9 × 2 = 18 point\n\n'
                    '• Parret vinder færre stik end meldt → begge spillere taber '
                    'det samme antal point.\n\n'
                    'Modstanderne scorer altid det modsatte beløb: taberne betaler '
                    'til vinderne og omvendt.',
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
                    '2. Tryk "Spil runde" for at dele kort automatisk.\n'
                    '3. Spillerne byder i tur – den der vinder opbuddet er spilleren.\n'
                    '4. Spilleren vælger trumf og melder sin makker.\n'
                    '5. Spil kortene – appen holder styr på stik og beregner point.\n'
                    '6. Se den løbende stilling under fanen "Stilling".',
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
