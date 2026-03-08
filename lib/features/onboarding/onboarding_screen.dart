import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/theme/app_theme.dart';
import '../../routes/app_routes.dart';
import '../../shared/widgets/chip_tag.dart';
import '../../shared/widgets/reusable_button.dart';

/// Onboarding walks the user through 3 steps:
/// 1. Display Name
/// 2. Interests (multi-select chips)
/// 3. Intent (what they're here for)
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final _nameController = TextEditingController();
  final _allInterests = [
    '🎵 Music', '🎨 Art', '🧘 Yoga', '🏋️ Fitness', '🎮 Gaming',
    '📚 Books', '✈️ Travel', '🍕 Foodie', '💻 Tech', '🎤 Karaoke',
    '🌿 Nature', '📷 Photography', '🎭 Theatre', '🏄 Surfing', '🎸 Guitar',
  ];
  final Set<String> _selectedInterests = {};
  String _selectedIntent = 'friends';
  bool _isSaving = false;

  final _intents = [
    {'id': 'friends',    'label': 'Make Friends',    'icon': '🤝'},
    {'id': 'dating',     'label': 'Dating',           'icon': '❤️'},
    {'id': 'networking', 'label': 'Networking',       'icon': '💼'},
    {'id': 'explore',    'label': 'Just Exploring',   'icon': '🌍'},
  ];

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
      setState(() => _currentPage++);
    } else {
      _saveAndNavigate();
    }
  }

  Future<void> _saveAndNavigate() async {
    setState(() => _isSaving = true);
    await Future.delayed(const Duration(milliseconds: 600));
    if (mounted) setState(() => _isSaving = false);
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (r) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Progress bar
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              child: Row(
                children: List.generate(3, (i) {
                  return Expanded(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.only(right: 6),
                      height: 4,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        color: i <= _currentPage ? AppTheme.mint : Colors.white12,
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 8),

            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _NamePage(controller: _nameController),
                  _InterestsPage(
                    all: _allInterests,
                    selected: _selectedInterests,
                    onToggle: (tag) => setState(() {
                      _selectedInterests.contains(tag)
                          ? _selectedInterests.remove(tag)
                          : _selectedInterests.add(tag);
                    }),
                  ),
                  _IntentPage(
                    intents: _intents,
                    selected: _selectedIntent,
                    onSelect: (id) => setState(() => _selectedIntent = id),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: _isSaving
                  ? const Center(child: CircularProgressIndicator(color: AppTheme.mint))
                  : ReusableButton(
                      text: _currentPage == 2 ? 'Start Exploring 🚀' : 'Next',
                      onPressed: _nextPage,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NamePage extends StatelessWidget {
  final TextEditingController controller;
  const _NamePage({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 30),
          const Text('What should we\ncall you?', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, height: 1.3)),
          const SizedBox(height: 8),
          const Text('This is how you appear to\npeople near you.', style: TextStyle(color: Colors.white54, fontSize: 14, height: 1.5)),
          const SizedBox(height: 40),
          TextField(
            controller: controller,
            autofocus: true,
            style: const TextStyle(color: Colors.white, fontSize: 20),
            decoration: const InputDecoration(hintText: 'Your display name'),
          ),
        ],
      ),
    );
  }
}

class _InterestsPage extends StatelessWidget {
  final List<String> all;
  final Set<String> selected;
  final Function(String) onToggle;

  const _InterestsPage({required this.all, required this.selected, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 30),
          const Text('What are you\ninto?', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, height: 1.3)),
          const SizedBox(height: 8),
          const Text('Select at least 3 interests to help\nus find your vibe tribe.', style: TextStyle(color: Colors.white54, fontSize: 14, height: 1.5)),
          const SizedBox(height: 28),
          Expanded(
            child: SingleChildScrollView(
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                children: all.map((tag) => ChipTag(
                  label: tag,
                  isSelected: selected.contains(tag),
                  onTap: () => onToggle(tag),
                )).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _IntentPage extends StatelessWidget {
  final List<Map<String, String>> intents;
  final String selected;
  final Function(String) onSelect;

  const _IntentPage({required this.intents, required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 30),
          const Text("What's your\nvibe?", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, height: 1.3)),
          const SizedBox(height: 8),
          const Text('Tell nearby people why you\'re here.\nYou can change this later.', style: TextStyle(color: Colors.white54, fontSize: 14, height: 1.5)),
          const SizedBox(height: 32),
          ...intents.map((intent) {
            final isSelected = intent['id'] == selected;
            return GestureDetector(
              onTap: () => onSelect(intent['id']!),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                decoration: BoxDecoration(
                  gradient: isSelected ? AppTheme.primaryGradient : null,
                  color: isSelected ? null : AppTheme.surfaceAlt,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? Colors.transparent : Colors.white12,
                  ),
                ),
                child: Row(
                  children: [
                    Text(intent['icon']!, style: const TextStyle(fontSize: 26)),
                    const SizedBox(width: 16),
                    Text(
                      intent['label']!,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: Colors.white,
                      ),
                    ),
                    const Spacer(),
                    if (isSelected)
                      const Icon(Icons.check_circle, color: Colors.white),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
