<?php

declare(strict_types=1);

header_remove();

function emit(array $payload, int $exitCode = 0): never
{
    fwrite(
        STDOUT,
        json_encode(
            $payload,
            JSON_UNESCAPED_SLASHES |
            JSON_UNESCAPED_UNICODE
        )
    );

    exit($exitCode);
}

function redactText(string $value): string
{
    $rules = [
        [
            '/((?:password|passwd|pwd|secret|token|api[_-]?key|client[_-]?secret)\s*[:=]\s*)[^\s,;]+/i',
            '$1[REDACTED]',
        ],
        [
            '/("(?:password|passwd|pwd|secret|token|api[_-]?key|client[_-]?secret)"\s*:\s*")[^"]*(")/i',
            '$1[REDACTED]$2',
        ],
        [
            '/(authorization\s*:\s*(?:bearer|basic)\s+)[^\s]+/i',
            '$1[REDACTED]',
        ],
        [
            '/([?&](?:token|access_token|api_key|key|secret|password)=)[^&\s]+/i',
            '$1[REDACTED]',
        ],
    ];

    foreach ($rules as [$pattern, $replacement]) {

        $replaced = preg_replace(
            $pattern,
            $replacement,
            $value
        );

        if ($replaced !== null) {
            $value = $replaced;
        }
    }

    return $value;
}

function isSensitiveKey(string $key): bool
{
    return preg_match(
        '/(?:password|passwd|pwd|secret|token|api[_-]?key|client[_-]?secret|authorization|cookie|credential|private[_-]?key)/i',
        $key
    ) === 1;
}

function redactValue(
    mixed $value,
    ?string $key = null
): mixed {

    if ($key !== null && isSensitiveKey($key)) {
        return '[REDACTED]';
    }

    if (is_array($value)) {

        $output = [];

        foreach ($value as $childKey => $childValue) {

            $output[$childKey] = redactValue(
                $childValue,
                is_string($childKey)
                    ? $childKey
                    : null
            );
        }

        return $output;
    }

    if (is_string($value)) {
        return redactText($value);
    }

    return $value;
}

function redactRows(array $rows): array
{
    $output = [];

    foreach ($rows as $row) {

        if (is_array($row)) {
            $output[] = redactValue($row);
        } else {
            $output[] = redactValue($row);
        }
    }

    return $output;
}

function fail(string $message): never
{
    emit([
        'status' => 'error',
        'row_count' => 0,
        'result' => [],
        'warnings' => [
            redactText($message),
        ],
    ], 1);
}

$raw = stream_get_contents(STDIN);

if ($raw === false || trim($raw) === '') {
    fail('Missing JSON request.');
}

try {

    $request = json_decode(
        $raw,
        true,
        512,
        JSON_THROW_ON_ERROR
    );

} catch (Throwable $e) {

    fail('Invalid JSON request.');
}

$required = [
    'host',
    'port',
    'database',
    'user',
    'password',
    'operation',
    'max_rows',
];

foreach ($required as $key) {

    if (!array_key_exists($key, $request)) {
        fail('Missing required field: ' . $key);
    }
}

$host = (string) $request['host'];
$port = (int) $request['port'];
$database = (string) $request['database'];
$user = (string) $request['user'];
$password = (string) $request['password'];
$operation = (string) $request['operation'];

$maxRows = max(
    1,
    min(
        1000,
        (int) $request['max_rows']
    )
);

$table = isset($request['table'])
    ? (string) $request['table']
    : '';

$query = isset($request['query'])
    ? trim((string) $request['query'])
    : '';

$allowedOperations = [
    'tables',
    'columns',
    'query',
];

if (!in_array(
    $operation,
    $allowedOperations,
    true
)) {
    fail('Unsupported operation.');
}

if (
    $operation === 'columns' &&
    $table === ''
) {
    fail('Table is required.');
}

if ($operation === 'query') {

    if ($query === '') {
        fail('Query is required.');
    }

    $query = rtrim(
        $query,
        " \t\n\r\0\x0B;"
    );

    if (str_contains($query, ';')) {
        fail('Multiple SQL statements are forbidden.');
    }

    /*
     * Conservative policy:
     * SQL comments are forbidden so mutation/locking
     * tokens cannot be hidden from the guard parser.
     */
    if (preg_match(
        '/(--|#|\/\*)/',
        $query
    )) {
        fail('SQL comments are forbidden.');
    }

    if (!preg_match(
        '/^\s*(SELECT|SHOW|EXPLAIN|DESCRIBE|DESC)\b/i',
        $query
    )) {
        fail('Only read-only SQL statements are allowed.');
    }

    $forbiddenPatterns = [
        '/\bINSERT\b/i',
        '/\bUPDATE\b/i',
        '/\bDELETE\b/i',
        '/\bDROP\b/i',
        '/\bALTER\b/i',
        '/\bCREATE\b/i',
        '/\bTRUNCATE\b/i',
        '/\bREPLACE\b/i',
        '/\bGRANT\b/i',
        '/\bREVOKE\b/i',
        '/\bCALL\b/i',
        '/\bLOAD\b/i',

        '/\bINTO\s+OUTFILE\b/i',
        '/\bINTO\s+DUMPFILE\b/i',
        '/\bINTO\s+@/i',

        '/\bFOR\s+UPDATE\b/i',
        '/\bFOR\s+SHARE\b/i',
        '/\bLOCK\s+IN\s+SHARE\s+MODE\b/i',

        '/\bGET_LOCK\s*\(/i',
        '/\bRELEASE_LOCK\s*\(/i',
        '/\bSLEEP\s*\(/i',
        '/\bBENCHMARK\s*\(/i',

        '/:=/',
    ];

    foreach ($forbiddenPatterns as $pattern) {

        if (preg_match(
            $pattern,
            $query
        )) {
            fail(
                'Unsafe read-only query construct detected.'
            );
        }
    }
}

$dsn = sprintf(
    'mysql:host=%s;port=%d;dbname=%s;charset=utf8mb4',
    $host,
    $port,
    $database
);

try {

    $pdo = new PDO(
        $dsn,
        $user,
        $password,
        [
            PDO::ATTR_ERRMODE =>
                PDO::ERRMODE_EXCEPTION,

            PDO::ATTR_DEFAULT_FETCH_MODE =>
                PDO::FETCH_ASSOC,

            PDO::ATTR_EMULATE_PREPARES =>
                false,
        ]
    );

    $password = '';

    if ($operation === 'tables') {

        $statement = $pdo->query(
            'SHOW TABLES'
        );

        $rows = $statement->fetchAll();

        $rows = array_slice(
            $rows,
            0,
            $maxRows
        );
    }
    elseif ($operation === 'columns') {

        if (!preg_match(
            '/^[A-Za-z0-9_$-]+$/',
            $table
        )) {
            fail('Unsafe table identifier.');
        }

        $quotedTable = '`' .
            str_replace(
                '`',
                '``',
                $table
            ) .
            '`';

        $statement = $pdo->query(
            'DESCRIBE ' . $quotedTable
        );

        $rows = $statement->fetchAll();

        $rows = array_slice(
            $rows,
            0,
            $maxRows
        );
    }
    else {

        $limitedQuery = $query;

        if (
            preg_match(
                '/^\s*SELECT\b/i',
                $query
            ) &&
            !preg_match(
                '/\bLIMIT\s+\d+/i',
                $query
            )
        ) {

            $limitedQuery .= (
                ' LIMIT ' .
                $maxRows
            );
        }

        $statement = $pdo->query(
            $limitedQuery
        );

        $rows = $statement->fetchAll();

        $rows = array_slice(
            $rows,
            0,
            $maxRows
        );
    }

    $safeRows = redactRows($rows);

    emit([
        'status' => 'pass',
        'row_count' => count($safeRows),
        'result' => $safeRows,
        'warnings' => [],
    ]);

} catch (Throwable $e) {

    fail(
        redactText(
            $e->getMessage()
        )
    );
}
