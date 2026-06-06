import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'core/constants/app_colors.dart';
import 'core/constants/app_text_styles.dart';
import 'core/constants/app_theme.dart';
import 'core/l10n/app_strings.dart';
import 'core/widgets/sheet_wrapper.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/auth/presentation/household_link_screen.dart';
import 'features/auth/presentation/join_screen.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/auth/presentation/register_screen.dart';
import 'features/budget/presentation/set_budget_screen.dart';
import 'features/home/presentation/home_screen.dart';
import 'features/household/presentation/household_screen.dart' show HouseholdPage;
import 'features/transactions/presentation/category_management_screen.dart';
import 'features/profile/data/locale_provider.dart';
import 'features/profile/data/theme_provider.dart';
import 'features/profile/presentation/profile_screen.dart';
import 'features/reports/presentation/reports_screen.dart';
import 'features/savings/presentation/add_goal_screen.dart';
import 'features/transactions/presentation/add_transaction_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  final authAsync = ref.watch(authStateProvider);
  final profileAsync = ref.watch(currentProfileProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/home',
    redirect: (context, state) {
      final isLoading = authAsync.isLoading ||
          (authAsync.value?.session != null && profileAsync.isLoading);
      if (isLoading) {
        return state.matchedLocation == '/loading' ? null : '/loading';
      }

      final isLoggedIn = authAsync.value?.session != null;
      if (!isLoggedIn) {
        if (state.matchedLocation == '/register') return null;
        if (state.matchedLocation.startsWith('/join/')) return null;
        return '/login';
      }
      final hasHousehold = profileAsync.value?.householdId != null;
      if (!hasHousehold && state.matchedLocation != '/household-link') {
        return '/household-link';
      }
      if (hasHousehold && state.matchedLocation == '/household-link') {
        return '/home';
      }
      if (state.matchedLocation == '/login' ||
          state.matchedLocation == '/register' ||
          state.matchedLocation == '/loading') {
        return '/home';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/loading',
        builder: (ctx, st) => const _LoadingScreen(),
      ),
      GoRoute(
        path: '/categories',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (ctx, st) => const CategoryManagementScreen(),
      ),
      GoRoute(path: '/login', builder: (ctx, st) => const LoginScreen()),
      GoRoute(path: '/register', builder: (ctx, st) => const RegisterScreen()),
      GoRoute(
          path: '/household-link',
          builder: (ctx, st) => const HouseholdLinkScreen()),
      GoRoute(
        path: '/join/:code',
        builder: (ctx, st) =>
            JoinScreen(inviteCode: st.pathParameters['code']!),
      ),
      // Shell — bottom nav tabs
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => _AppShell(child: child),
        routes: [
          GoRoute(
            path: '/home',
            pageBuilder: (ctx, st) =>
                const NoTransitionPage(child: FinanceScreen()),
          ),
          GoRoute(
            path: '/reports',
            pageBuilder: (ctx, st) =>
                const NoTransitionPage(child: ReportsScreen()),
          ),
          GoRoute(
            path: '/household',
            pageBuilder: (ctx, st) =>
                const NoTransitionPage(child: HouseholdPage()),
          ),
          GoRoute(
            path: '/profile',
            pageBuilder: (ctx, st) =>
                const NoTransitionPage(child: ProfileScreen()),
          ),
        ],
      ),
    ],
  );
});


class _AppShell extends ConsumerStatefulWidget {
  final Widget child;
  const _AppShell({required this.child});

  @override
  ConsumerState<_AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<_AppShell> {
  int _prevIndex = 0;

  static const _tabs = ['/home', '/reports', '/household', '/profile'];

  int _indexForLocation(String location) {
    if (location.startsWith('/reports')) return 1;
    if (location.startsWith('/household')) return 2;
    if (location.startsWith('/profile')) return 3;
    return 0;
  }

  FloatingActionButton? _buildFab(
      BuildContext context, int navIndex, int financeTab) {
    if (navIndex != 0) return null;
    switch (financeTab) {
      case 0:
        return FloatingActionButton(
          onPressed: () => AddTransactionScreen.show(context),
          backgroundColor: AppColors.black,
          foregroundColor: Colors.white,
          elevation: 4,
          child: const Icon(Icons.add, size: 28),
        );
      case 1:
        return FloatingActionButton(
          onPressed: () => _showAddBudget(context),
          backgroundColor: AppColors.amber,
          foregroundColor: Colors.white,
          elevation: 4,
          child: const Icon(Icons.add, size: 28),
        );
      case 2:
        return FloatingActionButton(
          onPressed: () => AddGoalScreen.show(context),
          backgroundColor: AppColors.amber,
          foregroundColor: Colors.white,
          elevation: 4,
          child: const Icon(Icons.add, size: 28),
        );
      default:
        return null;
    }
  }

  Widget _buildNavBar(BuildContext context, int currentIndex) {
    final hasFab = currentIndex == 0;
    return BottomAppBar(
      height: 64,
      padding: EdgeInsets.zero,
      color: context.colors.surface,
      elevation: 8,
      shadowColor: Colors.black12,
      shape: hasFab ? const CircularNotchedRectangle() : null,
      notchMargin: hasFab ? 8 : 0,
      child: Row(
        children: [
          Expanded(
            child: _NavItem(
              icon: Icons.wallet_outlined,
              selectedIcon: Icons.wallet,
              label: S.tabHome,
              selected: currentIndex == 0,
              onTap: () => context.go('/home'),
            ),
          ),
          Expanded(
            child: _NavItem(
              icon: Icons.bar_chart_outlined,
              selectedIcon: Icons.bar_chart,
              label: S.tabReports,
              selected: currentIndex == 1,
              onTap: () => context.go('/reports'),
            ),
          ),
          if (hasFab) const SizedBox(width: 72),
          Expanded(
            child: _NavItem(
              icon: Icons.people_outline,
              selectedIcon: Icons.people,
              label: S.tabHousehold,
              selected: currentIndex == 2,
              onTap: () => context.go('/household'),
            ),
          ),
          Expanded(
            child: _NavItem(
              icon: Icons.person_outline,
              selectedIcon: Icons.person,
              label: S.tabProfile,
              selected: currentIndex == 3,
              onTap: () => context.go('/profile'),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddBudget(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.72,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        builder: (_, _) => const SheetWrapper(child: SetBudgetScreen()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final currentIndex = _indexForLocation(location);
    final financeTab = ref.watch(financeTabProvider);
    final goingRight = currentIndex > _prevIndex;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _prevIndex = currentIndex;
    });

    return Scaffold(
      body: GestureDetector(
        onHorizontalDragEnd: (details) {
          final v = details.primaryVelocity ?? 0;
          if (v < -600 && currentIndex < _tabs.length - 1) {
            context.go(_tabs[currentIndex + 1]);
          } else if (v > 600 && currentIndex > 0) {
            context.go(_tabs[currentIndex - 1]);
          }
        },
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 280),
          transitionBuilder: (child, animation) {
            final begin = Offset(goingRight ? 1.0 : -1.0, 0);
            final slide =
                Tween<Offset>(begin: begin, end: Offset.zero).animate(
              CurvedAnimation(
                  parent: animation, curve: Curves.easeOutCubic),
            );
            return SlideTransition(position: slide, child: child);
          },
          child: KeyedSubtree(
            key: ValueKey(location),
            child: widget.child,
          ),
        ),
      ),
      floatingActionButton: _buildFab(context, currentIndex, financeTab),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: _buildNavBar(context, currentIndex),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? context.colors.textPrimary : AppColors.textSecondary;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        height: 64,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(selected ? selectedIcon : icon, color: color, size: 22),
            const SizedBox(height: 3),
            Text(
              label,
              style: AppTextStyles.labelSmall.copyWith(
                color: color,
                fontSize: 10,
                letterSpacing: 0,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('🐝', style: TextStyle(fontSize: 48)),
            SizedBox(height: 16),
            CircularProgressIndicator(color: AppColors.black),
          ],
        ),
      ),
    );
  }
}

class MyMoneyApp extends ConsumerWidget {
  const MyMoneyApp({super.key});

  static ThemeData _buildTheme({required bool dark}) {
    final bg = dark ? AppThemeColors.dark.background : AppThemeColors.light.background;
    final surface = dark ? AppThemeColors.dark.surface : AppThemeColors.light.surface;
    final onSurface = dark ? AppThemeColors.dark.textPrimary : AppThemeColors.light.textPrimary;
    final divider = dark ? AppThemeColors.dark.divider : AppThemeColors.light.divider;

    return ThemeData(
      brightness: dark ? Brightness.dark : Brightness.light,
      colorScheme: dark
          ? ColorScheme.dark(
              primary: Colors.white,
              onPrimary: AppColors.black,
              secondary: const Color(0xFFE5E5E5),
              onSecondary: AppColors.black,
              surface: surface,
              onSurface: onSurface,
            )
          : const ColorScheme.light(
              primary: AppColors.black,
              onPrimary: Colors.white,
              secondary: AppColors.blackSoft,
              onSecondary: Colors.white,
              surface: AppColors.surface,
              onSurface: AppColors.textPrimary,
            ),
      scaffoldBackgroundColor: bg,
      dividerColor: divider,
      useMaterial3: true,
      splashColor: dark ? Colors.white12 : Colors.black12,
      highlightColor: dark
          ? Colors.white.withValues(alpha: 0.06)
          : Colors.black.withValues(alpha: 0.06),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: dark ? Colors.white : AppColors.black, width: 1.5),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: dark ? Colors.white : AppColors.black,
          foregroundColor: dark ? AppColors.black : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);
    return MaterialApp.router(
      title: S.appName,
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('vi'), Locale('en')],
      locale: locale,
      theme: _buildTheme(dark: false),
      darkTheme: _buildTheme(dark: true),
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
