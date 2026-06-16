<?php

declare(strict_types=1);

namespace Controllers;

use Core\Ar;
use Core\BaseController;
use Core\Config;
use Core\Schema;

final class SetupController extends BaseController
{
    public function seed(array $input): array
    {
        Schema::migrate($this->pdo());
        $now = $this->now();
        $companyId = (string)($input['companyId'] ?? Config::get('app.default_company_id', 'company1'));
        $adminId = (string)($input['adminId'] ?? Config::get('seed.admin_id', 'admin1'));
        $password = (string)($input['adminPassword'] ?? Config::get('seed.admin_password', 'admin123'));
        $connection = $this->db();

        $connection->transaction();
        try {
            $this->insertIgnore('Company', [
                'id' => $companyId,
                'name' => $input['companyName'] ?? Config::get('seed.company_name', 'BazarTrack Office'),
                'created_at' => $now,
                'updated_at' => $now,
            ]);
            $adminCreated = $this->insertIgnore('User', [
                'id' => $adminId,
                'company_id' => $companyId,
                'role' => 'admin',
                'name' => $input['adminName'] ?? Config::get('seed.admin_name', 'System Admin'),
                'phone' => $input['adminPhone'] ?? Config::get('seed.admin_phone'),
                'email' => $input['adminEmail'] ?? Config::get('seed.admin_email', 'admin@example.com'),
                'password_hash' => password_hash($password, PASSWORD_DEFAULT),
                'is_active' => 1,
                'created_at' => $now,
                'updated_at' => $now,
            ]);
            $connection->commit();
        } catch (\Throwable $e) {
            $connection->rollback();
            throw $e;
        }

        return [
            'migrated' => true,
            'statements' => count(Schema::statements()),
            'seeded' => true,
            'companyId' => $companyId,
            'adminId' => $adminId,
            'adminCreated' => $adminCreated,
            'adminEmail' => $input['adminEmail'] ?? Config::get('seed.admin_email', 'admin@example.com'),
            'defaultPasswordWasUsed' => $password === 'admin123',
        ];
    }

    public function seedDemo(array $input): array
    {
        $admin = $this->seed($input);
        $now = $this->now();
        $companyId = $admin['companyId'];
        $connection = $this->db();

        $connection->transaction();
        try {
            $this->insertIgnore('User', ['id' => 'manager1', 'company_id' => $companyId, 'role' => 'owner', 'name' => 'Mr. CEO', 'phone' => null, 'email' => 'manager@example.com', 'password_hash' => null, 'is_active' => 1, 'created_at' => $now, 'updated_at' => $now]);
            $this->insertIgnore('User', ['id' => 'assistant1', 'company_id' => $companyId, 'role' => 'assistant', 'name' => 'Rahim Uddin', 'phone' => '01711-XXXXXX', 'email' => null, 'password_hash' => null, 'is_active' => 1, 'created_at' => $now, 'updated_at' => $now]);
            $this->insertIgnore('Fund', ['id' => 'fund1', 'company_id' => $companyId, 'name' => 'Office Lunch Bazar', 'type' => 'office_bazar', 'status' => 'active', 'created_by' => $admin['adminId'], 'created_at' => $now, 'updated_at' => $now]);
            $this->insertIgnore('FundManager', ['id' => 'fm1', 'company_id' => $companyId, 'fund_id' => 'fund1', 'user_id' => 'manager1', 'can_give_money' => 1, 'can_confirm_return' => 1, 'can_view_reports' => 1, 'created_at' => $now]);
            $this->insertIgnore('FundAssistantAccount', ['id' => 'acc1', 'company_id' => $companyId, 'fund_id' => 'fund1', 'assistant_id' => 'assistant1', 'status' => 'active', 'current_balance' => 0, 'created_at' => $now, 'updated_at' => $now]);
            $connection->commit();
        } catch (\Throwable $e) {
            $connection->rollback();
            throw $e;
        }

        return $admin + ['demoSeeded' => true];
    }

    private function insertIgnore(string $class, array $data): bool
    {
        if (Ar::find($class, (string)$data['id']) !== null) {
            return false;
        }
        Ar::create($class, $data);
        return true;
    }
}
