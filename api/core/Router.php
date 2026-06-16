<?php

declare(strict_types=1);

namespace Core;

use ReflectionMethod;

final class Router
{
    public static function dispatch(): never
    {
        $cmd = self::studly($_GET['cmd'] ?? 'health');
        $action = self::camel($_GET['action'] ?? 'index');
        $class = 'Controllers\\' . $cmd . 'Controller';

        if (!class_exists($class)) {
            Response::error('Unknown cmd', 404, ['cmd' => $_GET['cmd'] ?? 'health']);
        }

        $controller = new $class();
        if (!method_exists($controller, $action)) {
            Response::error('Unknown action', 404, ['cmd' => $cmd, 'action' => $action]);
        }

        $method = new ReflectionMethod($controller, $action);
        if (!$method->isPublic() || $method->isConstructor() || str_starts_with($action, '_')) {
            Response::error('Action not allowed', 403);
        }

        $result = $controller->$action(Request::input());
        Response::json($result);
    }

    private static function studly(string $value): string
    {
        $value = preg_replace('/[^a-zA-Z0-9_-]/', '', $value) ?: 'health';
        $parts = preg_split('/[-_]/', $value) ?: [$value];
        return implode('', array_map(static fn (string $part): string => ucfirst($part), $parts));
    }

    private static function camel(string $value): string
    {
        $studly = self::studly($value);
        return lcfirst($studly);
    }
}
