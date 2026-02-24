import 'package:flutter/material.dart';
import 'package:fmp_app/presentation/auth/welcome/welcome_screen.dart';
import 'package:fmp_app/presentation/auth/phone_input/phone_input_screen.dart';
import 'package:fmp_app/presentation/auth/otp_verify/otp_verify_screen.dart';
import 'package:fmp_app/presentation/role_router/account_resolver_screen.dart';
import 'package:fmp_app/presentation/onboarding/role_selection/role_selection_screen.dart';

import 'package:fmp_app/presentation/onboarding/sender_onboarding/sender_onboarding_screen.dart';
import 'package:fmp_app/presentation/onboarding/driver_onboarding/basic_details/driver_basic_details_screen.dart';
import 'package:fmp_app/presentation/onboarding/fleetmgr_onboarding/fleetmgr_onboarding_screen.dart';
import 'package:fmp_app/presentation/auth/approval_pending/approval_pending_screen.dart';
import 'package:fmp_app/presentation/driver/dashboard/driver_dashboard_screen.dart';
import 'package:fmp_app/presentation/sender/dashboard/sender_dashboard.dart';
import 'package:fmp_app/presentation/fleetmgr/dashboard/fleet_dashboard_screen.dart';
import 'package:fmp_app/presentation/sys_admin_dashboard/sys_admin_dashboard_screen.dart';
class AppRouter {
  static const welcome = '/welcome';
  static const phone = '/phone';
  static const otp = '/otp';
  static const resolver = '/resolver';
  static const roleSelection = '/role-selection';
  static const driverOnboarding = '/driver-onboarding';
  static const senderOnboarding = '/sender-onboarding';
  static const driverBasic = '/driver-basic';
  static const driverDocs = '/driver-docs';
  static const approvalPending = '/approval-pending';
  static const driverDashboard = '/driver-dashboard';
  static const sendrecvDashboard = '/organizationuser';
  static const fleetOnboarding = '/fleet-onboarding';
  static const fleetDashboard = '/fleet-dashboard';
  static const sysadmin = '/system_admin';
  static final routes = <String, WidgetBuilder>{
    welcome: (_) => const WelcomeScreen(),
    phone: (_) => const PhoneInputScreen(),
    otp: (_) => const OtpVerifyScreen(),
    resolver: (_) => const AccountResolverScreen(),
    roleSelection: (_) => const RoleSelectionScreen(),
    
    senderOnboarding: (_) => const SenderOnboardingScreen(),
    fleetOnboarding: (_) => const FleetmgrOnboardingScreen(),
    driverBasic: (_) => const DriverBasicDetailsScreen(),
    
    approvalPending: (_) => const ApprovalPendingScreen(),
    driverDashboard: (_) => const DriverDashboardScreen(),
    sendrecvDashboard: (_) => const SenderDashboardScreen(),
    fleetDashboard: (_) => const FleetDashboardScreen(),

    sysadmin: (_) => const SysAdminDashboardScreen(),

  };
}
