import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:mercato_frontend/core/constants/app_colors.dart';
import 'package:mercato_frontend/core/theme/app_theme.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  static const List<_FaqItem> _faqs = [
    _FaqItem(
      question: 'Comment compléter mon profil joueur ?',
      answer:
          'Rends-toi dans l\'onglet Profil puis appuie sur "Configurer le profil" (ou "Éditer le profil" s\'il existe déjà). '
          'Renseigne ton poste, ton niveau, ta date de naissance et ta ville : ton profil devient alors visible par les recruteurs.',
    ),
    _FaqItem(
      question: 'Comment ajouter un joueur à mes favoris ?',
      answer:
          'Depuis l\'onglet Explorer, ouvre le profil d\'un joueur puis appuie sur l\'icône favori. '
          'Tu retrouves ensuite tous tes joueurs favoris dans l\'onglet Favoris.',
    ),
    _FaqItem(
      question: 'Comment publier une vidéo ?',
      answer:
          'Utilise le bouton "+" en bas de l\'écran d\'accueil joueur pour importer une vidéo depuis ta galerie. '
          'Elle apparaîtra ensuite dans le fil d\'actualité des autres utilisateurs.',
    ),
    _FaqItem(
      question: 'Comment changer le thème de l\'application ?',
      answer: 'Dans l\'onglet Profil, active ou désactive l\'interrupteur "Thème sombre" pour basculer entre le mode clair et le mode sombre.',
    ),
    _FaqItem(
      question: 'Je n\'arrive pas à me connecter, que faire ?',
      answer: 'Vérifie ton adresse e-mail et ton mot de passe. Si le problème persiste, contacte le support via l\'adresse ci-dessous.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: Text(
          'AIDE & SUPPORT',
          style: TextStyle(
            fontSize: 18,
            fontWeight: context.weight(FontWeight.bold),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          FadeInDown(
            duration: const Duration(milliseconds: 400),
            child: Text(
              'Questions fréquentes',
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 18,
                fontWeight: context.weight(FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < _faqs.length; i++)
            FadeInUp(
              duration: const Duration(milliseconds: 400),
              delay: Duration(milliseconds: 60 * i),
              child: _buildFaqTile(context, colors, _faqs[i]),
            ),
          const SizedBox(height: 24),
          FadeInUp(
            duration: const Duration(milliseconds: 400),
            delay: Duration(milliseconds: 60 * _faqs.length),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colors.border),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.support_agent,
                    color: AppColors.primaryYellow,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Besoin d\'aide supplémentaire ?',
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontWeight: context.weight(FontWeight.bold),
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'contact@mercato-app.com',
                          style: TextStyle(
                            color: colors.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFaqTile(
    BuildContext context,
    AppSemanticColors colors,
    _FaqItem faq,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        iconColor: AppColors.primaryYellow,
        collapsedIconColor: colors.iconMuted,
        title: Text(
          faq.question,
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 15,
            fontWeight: context.weight(FontWeight.w600),
          ),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            faq.answer,
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 14,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _FaqItem {
  final String question;
  final String answer;

  const _FaqItem({required this.question, required this.answer});
}
