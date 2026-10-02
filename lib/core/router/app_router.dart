import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/admin/dashboard/admin_dashboard_screen.dart';
import '../../features/auth/domain/auth_state.dart';
import '../../features/auth/presentation/auth_controller.dart';
import '../../features/auth/presentation/customer_register_screen.dart';
import '../../features/auth/presentation/forgot_password_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/restaurant_register_screen.dart';
import '../../features/customer/home/customer_home_screen.dart';
import '../../features/customer/hot_deals/customer_hot_deals_screen.dart';
import '../../features/customer/offers/presentation/customer_offer_details_screen.dart';
import '../../features/customer/profile/customer_profile_screen.dart';
import '../../features/customer/restaurants/presentation/customer_restaurant_details_screen.dart';
import '../../features/customer/search/customer_search_screen.dart';
import '../../features/customer/shell/customer_shell_screen.dart';
import '../../features/restaurant/dashboard/restaurant_dashboard_screen.dart';
import '../../features/restaurant/offers/presentation/create_offer_screen.dart';
import '../../features/restaurant/profile/restaurant_profile_screen.dart';
import '../../features/shared/presentation/splash_screen.dart';
import 'app_routes.dart';

/// Listens to auth state changes and triggers GoRouter redirection.
class AppRouterNotifier extends ChangeNotifier {
  AppRouterNotifier(this._ref) {
    _ref.listen(currentUserProfileProvider, (_, _) => notifyListeners());
    _ref.listen(authControllerProvider, (_, _) => notifyListeners());
  }

  final Ref _ref;

  String? redirect(BuildContext context, GoRouterState state) {
    final profile = _ref.read(currentUserProfileProvider);
    final authState = _ref.read(authControllerProvider);

    final location = state.matchedLocation;
    final isLoggingIn = location == AppRoutes.login;
    final isRegistering = location.startsWith('/register');
    final isForgotPassword = location == AppRoutes.forgotPassword;
    final isAuthRoute = isLoggingIn || isRegistering || isForgotPassword;
    final isSplash = location == AppRoutes.splash;

    // While determining initial session on app startup
    if (authState is AuthInitial) {
      return isSplash ? null : AppRoutes.splash;
    }

    // Unauthenticated user
    if (profile == null) {
      return isAuthRoute ? null : AppRoutes.login;
    }

    // Authenticated user landing on splash or auth pages
    if (isAuthRoute || isSplash) {
      if (profile.isRestaurant) return AppRoutes.restaurantDashboard;
      if (profile.isAdmin) return AppRoutes.adminDashboard;
      return AppRoutes.customerHome;
    }

    // Role-based route enforcement (Section 18)
    if (profile.isCustomer &&
        (location.startsWith('/restaurant') || location.startsWith('/admin'))) {
      return AppRoutes.customerHome;
    }

    if (profile.isRestaurant &&
        (location.startsWith('/admin') || location.startsWith('/customer'))) {
      return AppRoutes.restaurantDashboard;
    }

    return null;
  }
}

/// Global root navigator key for pushing full-screen dialogs and modal bottom sheets
/// above the shell navigation routes.
final rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

/// Riverpod provider for GoRouter configuration with role-based routing (Section 18).
final routerProvider = Provider<GoRouter>((ref) {
  final notifier = AppRouterNotifier(ref);

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: AppRoutes.splash,
    refreshListenable: notifier,
    redirect: notifier.redirect,
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.customerRegister,
        name: 'customerRegister',
        builder: (context, state) => const CustomerRegisterScreen(),
      ),
      GoRoute(
        path: AppRoutes.restaurantRegister,
        name: 'restaurantRegister',
        builder: (context, state) => const RestaurantRegisterScreen(),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        name: 'forgotPassword',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),

      // Customer Navigation Shell (Section 19: Home, Search, Profile)
      StatefulShellRoute.indexedStack(
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state, navigationShell) {
          return CustomerShellScreen(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.customerHome,
                name: 'customerHome',
                builder: (context, state) => const CustomerHomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.customerSearch,
                name: 'customerSearch',
                builder: (context, state) => const CustomerSearchScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.customerProfile,
                name: 'customerProfile',
                builder: (context, state) => const CustomerProfileScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.customerHotDeals,
                name: 'customerHotDeals',
                builder: (context, state) => const CustomerHotDealsScreen(),
              ),
            ],
          ),
        ],
      ),

      // Customer stack details routes
      GoRoute(
        path: AppRoutes.customerOfferDetails,
        name: 'customerOfferDetails',
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return CustomerOfferDetailsScreen(offerId: id);
        },
      ),
      GoRoute(
        path: AppRoutes.customerRestaurantDetails,
        name: 'customerRestaurantDetails',
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return CustomerRestaurantDetailsScreen(restaurantId: id);
        },
      ),

      // Restaurant routes
      GoRoute(
        path: AppRoutes.restaurantDashboard,
        name: 'restaurantDashboard',
        builder: (context, state) => const RestaurantDashboardScreen(),
      ),
      GoRoute(
        path: AppRoutes.restaurantProfile,
        name: 'restaurantProfile',
        builder: (context, state) => const RestaurantProfileScreen(),
      ),
      GoRoute(
        path: AppRoutes.restaurantCreateOffer,
        name: 'restaurantCreateOffer',
        builder: (context, state) => const CreateOfferScreen(),
      ),

      // Admin routes
      GoRoute(
        path: AppRoutes.adminDashboard,
        name: 'adminDashboard',
        builder: (context, state) => const AdminDashboardScreen(),
      ),
    ],
    errorBuilder: (context, state) =>
        Scaffold(body: Center(child: Text('Page not found: ${state.uri}'))),
  );
});
