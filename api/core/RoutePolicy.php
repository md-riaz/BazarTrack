<?php

declare(strict_types=1);

namespace Core;

final class RoutePolicy
{
    private const PUBLIC_ROUTES = [
        'health.index',
        'auth.login',
    ];

    private const METHODS = [
        'health.index' => ['GET'],
        'auth.login' => ['POST'],
        'auth.me' => ['GET'],
        'auth.user' => ['GET', 'POST'],
        'auth.logout' => ['POST'],
        'setup.seed' => ['POST'],
        'setup.seedDemo' => ['POST'],
        'users.list' => ['GET'],
        'users.show' => ['GET'],
        'users.create' => ['POST'],
        'funds.list' => ['GET'],
        'funds.show' => ['GET'],
        'funds.create' => ['POST'],
        'funds.addManager' => ['POST'],
        'accounts.list' => ['GET'],
        'accounts.show' => ['GET'],
        'accounts.create' => ['POST'],
        'ledger.list' => ['GET'],
        'ledger.reconcile' => ['GET'],
        'money.list' => ['GET'],
        'money.give' => ['POST'],
        'returns.list' => ['GET'],
        'returns.create' => ['POST'],
        'returns.confirm' => ['POST'],
        'returns.reject' => ['POST'],
        'bazars.list' => ['GET'],
        'bazars.show' => ['GET'],
        'bazars.create' => ['POST'],
        'bazars.addItem' => ['POST'],
        'bazars.updateItem' => ['POST', 'PATCH'],
        'bazars.uploadReceipt' => ['POST'],
        'bazars.receipt' => ['GET'],
        'bazars.close' => ['POST'],
        'reports.summary' => ['GET'],
    ];

    private const ROLES = [
        'users.list' => ['admin'],
        'users.show' => ['admin'],
        'users.create' => ['admin'],
        'funds.create' => ['admin'],
        'funds.addManager' => ['admin'],
        'accounts.create' => ['admin'],
        'money.list' => ['admin', 'owner'],
        'money.give' => ['admin', 'owner'],
        'returns.confirm' => ['admin', 'owner'],
        'returns.reject' => ['admin', 'owner'],
        'ledger.list' => ['admin', 'owner'],
        'ledger.reconcile' => ['admin', 'owner'],
        'reports.summary' => ['admin', 'owner'],
    ];

    public static function authorize(string $cmd, string $action, array &$input): void
    {
        $route = $cmd . '.' . $action;
        if (!array_key_exists($route, self::METHODS)) {
            Response::error('Not found', 404);
        }
        self::requireMethod($route);

        if (strtolower($cmd) === 'setup') {
            self::requireDevelopmentDemoMode();
            return;
        }
        if (in_array($route, self::PUBLIC_ROUTES, true)) {
            if ($route === 'auth.login') {
                RateLimiter::consume('login:' . ($_SERVER['REMOTE_ADDR'] ?? 'unknown'), 10, 60);
            }
            return;
        }

        $principal = Auth::authenticate();
        if (Request::method() !== 'GET') {
            RateLimiter::consume('mutation:' . $principal->userId, 120, 60);
        }
        Validator::validate($cmd, $action, $input);
        $roles = self::ROLES[$route] ?? null;
        if ($roles !== null && !in_array($principal->role, $roles, true)) {
            Response::error('Forbidden', 403);
        }

        foreach (['companyId', 'createdBy', 'closedBy', 'confirmedBy', 'rejectedBy', 'requestedBy', 'paidBy', 'receivedBy'] as $field) {
            unset($input[$field]);
        }
        $input['companyId'] = $principal->companyId;
        $input['createdBy'] = $principal->userId;
        $input['closedBy'] = $principal->userId;
        $input['confirmedBy'] = $principal->userId;
        $input['rejectedBy'] = $principal->userId;
        $input['requestedBy'] = $principal->userId;
        $input['paidBy'] = $principal->userId;
        $input['receivedBy'] = $principal->userId;

        Authorizer::authorizeObject($cmd, $action, $input, $principal);
    }

    private static function requireMethod(string $route): void
    {
        $allowed = self::METHODS[$route] ?? null;
        if ($allowed === null) {
            return;
        }
        if (!in_array(Request::method(), $allowed, true)) {
            header('Allow: ' . implode(', ', $allowed));
            Response::error('Method not allowed', 405);
        }
    }

    private static function requireDevelopmentDemoMode(): void
    {
        $environment = (string)Config::get('app.environment', 'production');
        $demoMode = (bool)Config::get('app.demo_mode', false);
        if ($environment !== 'development' || !$demoMode) {
            Response::error('Not found', 404);
        }
        self::requireMethod('setup.' . ($_GET['action'] ?? 'seed'));
    }
}
