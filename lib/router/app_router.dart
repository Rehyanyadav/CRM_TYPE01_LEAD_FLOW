import 'package:crm_app/features/clients/presentation/add_client_screen.dart';
import 'package:crm_app/features/clients/presentation/admin_dashboard.dart';
import 'package:crm_app/features/clients/presentation/client_form_screen.dart';
import 'package:crm_app/features/clients/presentation/client_list_screen.dart';
import 'package:crm_app/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:crm_app/features/clients/presentation/dashboard_screen.dart';
import 'package:crm_app/features/auth/presentation/home_screen.dart';

final goRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
    GoRoute(path: '/login', builder: (context, state) => const HomeScreen()),
    GoRoute(
      path: '/dashboard',
      builder: (context, state) => const DashboardScreen(),
    ),
    GoRoute(
      path: '/client-list',
      builder: (context, state) => ClientListScreen(),
    ),
    GoRoute(
      path: '/add-client',
      builder: (context, state) => AddClientScreen(),
    ),
    GoRoute(
      path: '/client-form',
      builder: (context, state) => const ClientFormScreen(),
    ),

    GoRoute(
      path: '/admin/dashboard',
      builder: (context, state) => const AdminDashboardScreen(),
    ),
  ],
);
