import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers.dart';
import '../ui/components.dart';
import '../ui/illustrations.dart';
import '../ui/motion.dart';
import '../ui/theme.dart';

class _Page {
  const _Page({required this.art, required this.title, required this.detail});

  final Widget art;
  final String title;
  final String detail;
}

const _pages = [
  _Page(
    art: ScanArt(),
    title: 'Scan anything',
    detail: 'Point the camera at a page. PDF Editor finds the edges, straightens it '
        'and saves a clean PDF.',
  ),
  _Page(
    art: StackArt(),
    title: 'Keep it in order',
    detail: 'Merge files, drag pages where they belong, drop the ones you do not need, '
        'and sort the rest into folders.',
  ),
  _Page(
    art: ConvertArt(),
    title: 'Turn it into anything',
    detail: 'Read the words off a scan, or send the whole document out as images, '
        'a Word file or a slide deck.',
  ),
  _Page(
    art: PrivacyArt(),
    title: 'Nothing leaves your phone',
    detail: 'No account, no server, no analytics. PDF Editor keeps working with the '
        'network switched off, because it never needed it.',
  ),
];

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _controller = PageController();
  int _index = 0;

  bool get _last => _index == _pages.length - 1;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: _last ? 0 : 1,
                child: IgnorePointer(
                  ignoring: _last,
                  child: PressScale(
                    onTap: _finish,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
                      child: Text(
                        'Skip',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: colors.muted,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _pages.length,
                onPageChanged: (index) => setState(() => _index = index),
                itemBuilder: (context, index) => _PageView(page: _pages[index]),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var index = 0; index < _pages.length; index++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 260),
                    curve: Curves.easeOut,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: index == _index ? 20 : 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: index == _index ? colors.accent : colors.hairline,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 26, 24, 14),
              child: AppButton(
                label: _last ? 'Get started' : 'Continue',
                onPressed: _next,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _next() {
    if (_last) {
      _finish();
      return;
    }

    _controller.nextPage(
      duration: const Duration(milliseconds: 340),
      curve: Curves.easeOutCubic,
    );
  }

  void _finish() => ref.read(onboardingProvider.notifier).complete();
}

class _PageView extends StatelessWidget {
  const _PageView({required this.page});

  final _Page page;

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          page.art,
          const SizedBox(height: 44),
          FadeSlideIn(
            delay: const Duration(milliseconds: 120),
            child: Text(
              page.title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 27,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
                color: colors.ink,
              ),
            ),
          ),
          const SizedBox(height: 12),
          FadeSlideIn(
            delay: const Duration(milliseconds: 220),
            child: Text(
              page.detail,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15.5, height: 1.5, color: colors.muted),
            ),
          ),
        ],
      ),
    );
  }
}
