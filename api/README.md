# BazarTrack PHP API scaffold

Simple PHP OOP API for current backend prototype.

## Routing

All requests go through `api/index.php`.

```text
?cmd=<controller>&action=<method>&other=params
```

Examples:

```text
/api/index.php?cmd=health&action=index
/api/index.php?cmd=setup&action=seed
/api/index.php?cmd=users&action=list
/api/index.php?cmd=funds&action=list
/api/index.php?cmd=accounts&action=list&fundId=fund1
/api/index.php?cmd=money&action=give
/api/index.php?cmd=returns&action=create
/api/index.php?cmd=returns&action=confirm
/api/index.php?cmd=bazars&action=create
/api/index.php?cmd=reports&action=summary&from=2026-06-01&to=2026-06-30
```

Controller class mapping:

```text
cmd=money   -> Controllers\MoneyController
action=give -> MoneyController::give(array $input)
```

GET, POST form data, and JSON body are merged into one `$input` array. `cmd` and `action` are removed before dispatch.

## ActiveRecord setup

This API follows the php-activerecord Quick Start pattern without Composer. The library is already vendored in:

```text
api/vendor/php-activerecord/
```

Bootstrap loads:

```php
require_once 'vendor/php-activerecord/autoload.php';

ActiveRecord\Config::initialize(function($cfg) {
    $cfg->set_connections(['development' => 'mysql://user:pass@localhost/db']);
});

class User extends ActiveRecord\Model {}
```

Concrete models live in `api/models/` and extend `BaseModel`, which extends `ActiveRecord\Model`. No Composer or manual vendor install needed.

## Database

Development default is SQLite:

```text
api/storage/dev.sqlite
```

Production target is MySQL. Copy config and set driver:

```bash
cp api/config.example.php api/config.php
```

```php
'driver' => 'mysql'
```

Environment variables also work:

```text
DB_DRIVER=mysql
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=bazartrack
DB_USER=bazartrack
DB_PASSWORD=secret
```

Initial admin seed variables:

```text
INITIAL_COMPANY_NAME=BazarTrack Office
INITIAL_ADMIN_ID=admin1
INITIAL_ADMIN_NAME=System Admin
INITIAL_ADMIN_EMAIL=admin@example.com
INITIAL_ADMIN_PHONE=01711-000000
INITIAL_ADMIN_PASSWORD=change-this-before-production
```

`INITIAL_ADMIN_PASSWORD` defaults to `admin123` for local development only. Set it explicitly before production seeding.

## Local run

```bash
php -S 127.0.0.1:8080 -t api
```

Then run one setup URL. It creates tables and first admin in the same action:

```text
http://127.0.0.1:8080/index.php?cmd=setup&action=seed
http://127.0.0.1:8080/index.php?cmd=health&action=index
```

Demo data is separate:

```text
http://127.0.0.1:8080/index.php?cmd=setup&action=seedDemo
```

Only `action=seed` is required for real setup.

## Money flow

Supported current money model:

1. Fund Manager gives money to assistant: `cmd=money&action=give`
2. Assistant spends through bazar item prices. Closing bazar writes `bazar_spend` ledger.
3. Assistant keeps remaining cash for next bazar.
4. Assistant returns cash through two-step request:
   - `cmd=returns&action=create`
   - `cmd=returns&action=confirm`

No direct-expense flow exists in this API.

## Idempotency

Mutating money endpoints read:

```text
Idempotency-Key: <client_operation_id>
X-Client-Id: <device_id>
```

Current scaffold stores `Idempotency-Key` on money entries and return requests.

