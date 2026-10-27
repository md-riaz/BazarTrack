import 'package:bazar/core/router/app_router.dart';
import 'package:bazar/shared/models/app_enums.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('recognizes admin wallet edit deep links for API-mode redirect', () {
    expect(isWalletEditLocation('/admin/wallets/fund-1/edit'), isTrue);
    expect(isWalletEditLocation('/admin/wallets/add'), isFalse);
    expect(isWalletEditLocation('/admin'), isFalse);
    expect(isWalletEditLocation('/wallets/fund-1'), isFalse);
  });

  test('API admin edit redirects while API add remains allowed', () {
    expect(
      apiAdminRouteRedirect(
        apiEnabled: true,
        location: '/admin/wallets/fund-1/edit',
        role: UserRole.admin,
      ),
      AppRoutes.admin,
    );
    expect(
      apiAdminRouteRedirect(
        apiEnabled: true,
        location: AppRoutes.addWallet,
        role: UserRole.admin,
      ),
      isNull,
    );
  });

  test('non-admin concrete edit deep link is rejected', () {
    expect(
      canAccessRoute('/admin/wallets/fund-1/edit', UserRole.owner),
      isFalse,
    );
    expect(
      apiAdminRouteRedirect(
        apiEnabled: false,
        location: '/admin/wallets/fund-1/edit',
        role: UserRole.assistant,
      ),
      AppRoutes.home,
    );
  });

  test('local admin concrete edit deep link remains allowed', () {
    expect(
      canAccessRoute('/admin/wallets/fund-1/edit', UserRole.admin),
      isTrue,
    );
    expect(
      apiAdminRouteRedirect(
        apiEnabled: false,
        location: '/admin/wallets/fund-1/edit',
        role: UserRole.admin,
      ),
      isNull,
    );
  });
}
