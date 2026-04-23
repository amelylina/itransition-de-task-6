BEGIN;

CREATE OR REPLACE FUNCTION fn_rebuild_picker_cache()
RETURNS VOID AS $$
BEGIN
    TRUNCATE picker_cache;

    INSERT INTO picker_cache (cache_key, ids, weights)
    SELECT 'names:' || locale || ':' || name_type || ':' || gender,
        array_agg(id ORDER BY id),
        array_agg(freq_weight ORDER BY id)
    FROM names
    GROUP BY locale, name_type, gender;

    INSERT INTO picker_cache (cache_key, ids, weights)
    SELECT 'titles:' || locale || ':' || gender,
        array_agg(id ORDER BY id),
        array_agg(freq_weight ORDER BY id)
    FROM titles
    GROUP BY locale, gender;

    INSERT INTO picker_cache (cache_key, ids, weights)
    SELECT 'cities:' || locale,
        array_agg(id ORDER BY id),
        array_agg(freq_weight ORDER BY id)
    FROM cities
    GROUP BY locale;

    INSERT INTO picker_cache (cache_key, ids, weights)
    SELECT 'street_names:' || locale,
        array_agg(id ORDER BY id),
        array_agg(freq_weight ORDER BY id)
    FROM street_names
    GROUP BY locale;

    INSERT INTO picker_cache (cache_key, ids, weights)
    SELECT 'street_types:' || locale,
        array_agg(id ORDER BY id),
        array_agg(freq_weight ORDER BY id)
    FROM street_types
    GROUP BY locale;

    INSERT INTO picker_cache (cache_key, ids, weights)
    SELECT 'eye_colors:' || locale,
        array_agg(id ORDER BY id),
        array_agg(freq_weight ORDER BY id)
    FROM eye_colors
    GROUP BY locale;

    INSERT INTO picker_cache (cache_key, ids, weights)
    SELECT 'hair_colors:' || locale,
        array_agg(id ORDER BY id),
        array_agg(freq_weight ORDER BY id)
    FROM hair_colors
    GROUP BY locale;

    INSERT INTO picker_cache (cache_key, ids, weights)
    SELECT 'phone_formats:' || locale,
        array_agg(id ORDER BY id),
        array_agg(freq_weight ORDER BY id)
    FROM phone_formats
    GROUP BY locale;

    INSERT INTO picker_cache (cache_key, ids, weights)
    SELECT 'email_domains:' || l.code,
        array_agg(ed.id ORDER BY ed.id),
        array_agg(ed.freq_weight ORDER BY ed.id)
    FROM locales l
    JOIN email_domains ed ON ed.locale = l.code OR ed.locale IS NULL
    GROUP BY l.code;
END;
$$ LANGUAGE plpgsql;

COMMIT;