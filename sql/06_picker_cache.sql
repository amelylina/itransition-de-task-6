BEGIN;

CREATE TABLE IF NOT EXISTS picker_cache (
    cache_key TEXT PRIMARY KEY,
    ids BIGINT[] NOT NULL,
    weights INT[] NOT NULL
);

COMMIT;