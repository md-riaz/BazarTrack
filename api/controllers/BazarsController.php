<?php

declare(strict_types=1);

namespace Controllers;

use Core\Ar;
use Core\BaseController;
use Core\Request;
use Core\Response;
use Throwable;

final class BazarsController extends BaseController
{
    public function list(array $input): array
    {
        return Ar::all('Bazar', [
            'company_id' => $this->companyId($input),
            'fund_id' => $input['fundId'] ?? null,
            'account_id' => $input['accountId'] ?? null,
            'assigned_to' => $input['assignedTo'] ?? null,
            'status' => $input['status'] ?? null,
        ], (int)($input['limit'] ?? 100));
    }

    public function show(array $input): array
    {
        Request::require($input, ['id']);
        $bazar = Ar::find('Bazar', (string)$input['id']);
        if ($bazar === null) {
            Response::error('Bazar not found', 404);
        }
        return ['bazar' => $bazar, 'items' => Ar::all('BazarItem', ['bazar_id' => $bazar['id']], 500)];
    }

    public function create(array $input): array
    {
        Request::require($input, ['fundId', 'title', 'createdBy']);
        $now = $this->now();
        $bazar = Ar::create('Bazar', [
            'id' => $input['id'] ?? $this->uuid(),
            'company_id' => $this->companyId($input),
            'fund_id' => $input['fundId'],
            'account_id' => $input['accountId'] ?? null,
            'title' => $input['title'],
            'assigned_to' => $input['assignedTo'] ?? null,
            'bazar_date' => $input['bazarDate'] ?? substr($now, 0, 10),
            'status' => $input['status'] ?? 'draft',
            'created_by' => $input['createdBy'],
            'created_at' => $now,
            'updated_at' => $now,
        ]);
        $items = [];
        foreach (($input['items'] ?? []) as $item) {
            $items[] = $this->addItemToBazar((string)$bazar['id'], $item);
        }
        return ['bazar' => $bazar, 'items' => $items];
    }

    public function addItem(array $input): array
    {
        Request::require($input, ['bazarId', 'name']);
        return $this->addItemToBazar((string)$input['bazarId'], $input);
    }

    public function updateItem(array $input): array
    {
        Request::require($input, ['id']);
        $data = [];
        foreach (['name', 'quantity', 'price', 'status', 'note'] as $key) {
            if (array_key_exists($key, $input)) {
                $data[$key] = $input[$key];
            }
        }
        $data['updated_at'] = $this->now();
        return Ar::update('BazarItem', (string)$input['id'], $data);
    }

    public function uploadReceipt(array $input): array
    {
        Request::require($input, ['id', 'imageBase64']);
        if (!is_string($input['imageBase64'])) {
            Response::error('Invalid receipt image', 422);
        }
        $encoded = $input['imageBase64'];
        if (str_starts_with($encoded, 'data:')) {
            $parts = explode(',', $encoded, 2);
            $encoded = $parts[1] ?? '';
        }
        $bytes = base64_decode($encoded, true);
        if ($bytes === false || $bytes === '' || strlen($bytes) > 5 * 1024 * 1024) {
            Response::error('Receipt image must be a valid image up to 5 MB', 422);
        }
        $image = @getimagesizefromstring($bytes);
        if ($image === false || !in_array($image['mime'] ?? '', ['image/jpeg', 'image/png', 'image/webp'], true)) {
            Response::error('Receipt must be a JPEG, PNG, or WebP image', 422);
        }
        $width = (int)($image[0] ?? 0);
        $height = (int)($image[1] ?? 0);
        if ($width < 1 || $height < 1 || $width > 6000 || $height > 6000 || $width * $height > 20000000) {
            Response::error('Receipt image dimensions are too large', 422);
        }
        $extension = match ($image['mime']) {
            'image/jpeg' => 'jpg',
            'image/png' => 'png',
            default => 'webp',
        };
        $directory = dirname(__DIR__, 2) . '/bazartrack-private-receipts';
        if (!is_dir($directory) && !mkdir($directory, 0775, true) && !is_dir($directory)) {
            Response::error('Receipt storage is unavailable', 500);
        }
        $previousItem = Ar::find('BazarItem', (string)$input['id']);
        $previousReceipt = is_array($previousItem) ? ($previousItem['receipt_url'] ?? null) : null;
        $filename = bin2hex(random_bytes(16)) . '.' . $extension;
        if (file_put_contents($directory . '/' . $filename, $bytes, LOCK_EX) === false) {
            Response::error('Receipt could not be saved', 500);
        }
        $receiptRef = $filename;
        try {
            $item = Ar::update('BazarItem', (string)$input['id'], [
                'receipt_url' => $receiptRef,
                'updated_at' => $this->now(),
            ]);
        } catch (Throwable $error) {
            @unlink($directory . '/' . $filename);
            throw $error;
        }
        if (is_string($previousReceipt) && $previousReceipt !== $receiptRef
            && preg_match('/^[a-f0-9]{32}\.(jpg|png|webp)$/', $previousReceipt)) {
            @unlink($directory . '/' . $previousReceipt);
        }
        return ['item' => $item, 'receiptUrl' => $receiptRef];
    }

    public function receipt(array $input): never
    {
        Request::require($input, ['id']);
        $item = Ar::find('BazarItem', (string)$input['id']);
        $receiptRef = $item['receipt_url'] ?? null;
        if (!is_string($receiptRef) || !preg_match('/^[a-f0-9]{32}\.(jpg|png|webp)$/', $receiptRef)) {
            Response::error('Receipt not found', 404);
        }
        $path = dirname(__DIR__, 2) . '/bazartrack-private-receipts/' . $receiptRef;
        if (!is_file($path)) {
            Response::error('Receipt not found', 404);
        }
        $mime = match (pathinfo($path, PATHINFO_EXTENSION)) {
            'jpg' => 'image/jpeg',
            'png' => 'image/png',
            default => 'image/webp',
        };
        header('Content-Type: ' . $mime);
        header('Content-Length: ' . (string)filesize($path));
        header('Cache-Control: private, max-age=86400');
        header('X-Content-Type-Options: nosniff');
        readfile($path);
        exit;
    }

    public function close(array $input): array
    {
        Request::require($input, ['id', 'closedBy']);
        $this->beginWriteTransaction();
        try {
            $bazar = $this->lockRow('bazars', (string)$input['id']);
            if ($bazar === null) {
                Response::error('Bazar not found', 404);
            }
            if (!$bazar['account_id']) {
                Response::error('Bazar must have account_id before closing', 422);
            }
            $existingLedger = $this->one(
                "select * from ledger_entries where source_type = 'bazar' and source_id = :source_id and type = 'bazar_spend'",
                ['source_id' => $bazar['id']]
            );
            if ($bazar['status'] === 'closed' || $existingLedger !== null) {
                $account = $this->lockRow('fund_assistant_accounts', (string)$bazar['account_id']);
                $this->commitWriteTransaction();
                return [
                    'bazar' => $bazar,
                    'bazarSpent' => (float)($existingLedger['amount'] ?? 0),
                    'accountBalance' => (float)($account['current_balance'] ?? 0),
                    'idempotentReplay' => true,
                ];
            }
            if (!in_array($bazar['status'], ['draft', 'open'], true)) {
                Response::error('Only draft or open bazars can be closed', 409);
            }

            $account = $this->lockRow('fund_assistant_accounts', (string)$bazar['account_id']);
            if ($account === null) {
                Response::error('Account not found', 404);
            }
            $totalRow = $this->one(
                "select coalesce(sum(price), 0) as total from bazar_items where bazar_id = :bazar_id and status = 'done'",
                ['bazar_id' => $bazar['id']]
            );
            $total = round((float)($totalRow['total'] ?? 0), 2);
            $now = $this->now();
            $updated = Ar::update('Bazar', (string)$bazar['id'], [
                'status' => 'closed',
                'closed_at' => $now,
                'updated_at' => $now,
            ]);
            $balance = (float)$account['current_balance'];
            if ($total > 0) {
                Ar::create('LedgerEntry', [
                    'id' => $this->uuid(),
                    'company_id' => $bazar['company_id'],
                    'fund_id' => $bazar['fund_id'],
                    'account_id' => $bazar['account_id'],
                    'type' => 'bazar_spend',
                    'amount' => $total,
                    'signed_amount' => -$total,
                    'source_type' => 'bazar',
                    'source_id' => $bazar['id'],
                    'created_by' => $input['closedBy'],
                    'note' => $input['note'] ?? null,
                    'entry_date' => $input['entryDate'] ?? substr($now, 0, 10),
                    'created_at' => $now,
                ]);
                $balance -= $total;
                Ar::update('FundAssistantAccount', (string)$account['id'], [
                    'current_balance' => $balance,
                    'updated_at' => $now,
                ]);
            }
            $this->commitWriteTransaction();
            return ['bazar' => $updated, 'bazarSpent' => $total, 'accountBalance' => $balance];
        } catch (Throwable $error) {
            $this->rollbackWriteTransaction();
            throw $error;
        }
    }

    private function addItemToBazar(string $bazarId, array $item): array
    {
        $now = $this->now();
        return Ar::create('BazarItem', [
            'id' => $item['id'] ?? $this->uuid(),
            'bazar_id' => $bazarId,
            'name' => $item['name'],
            'quantity' => $item['quantity'] ?? null,
            'price' => $item['price'] ?? null,
            'status' => $item['status'] ?? 'pending',
            'note' => $item['note'] ?? null,
            'created_at' => $now,
            'updated_at' => $now,
        ]);
    }
}
