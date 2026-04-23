BEGIN;

CREATE OR REPLACE FUNCTION fn_generate_full_name(
    p_seed   BIGINT,
    p_batch  INT,
    p_idx    INT,
    p_locale TEXT,
    p_gender TEXT
) RETURNS TEXT AS $$
DECLARE
    v_has_title  BOOLEAN;
    v_has_middle BOOLEAN;
    v_title      TEXT;
    v_first      TEXT;
    v_middle     TEXT;
    v_last       TEXT;
    v_parts      TEXT[] := ARRAY[]::TEXT[];
BEGIN
    v_has_title  := fn_hash_uniform(p_seed, p_batch, p_idx, 'name:has_title')  < 0.20;
    v_has_middle := fn_hash_uniform(p_seed, p_batch, p_idx, 'name:has_middle') < 0.40;

    v_first := fn_pick_name(p_seed, p_batch, p_idx, 'name:first',
        p_locale, 'first', p_gender);
    v_last  := fn_pick_name(p_seed, p_batch, p_idx, 'name:last',
        p_locale, 'last',  'u');

    IF v_has_title THEN
        v_title := fn_pick_title(p_seed, p_batch, p_idx, 'name:title',
            p_locale, p_gender);
        v_parts := v_parts || v_title;
    END IF;

    v_parts := v_parts || v_first;

    IF v_has_middle THEN
        v_middle := fn_pick_name(p_seed, p_batch, p_idx, 'name:middle',
            p_locale, 'middle', p_gender);
        v_parts := v_parts || v_middle;
    END IF;

    v_parts := v_parts || v_last;

    RETURN array_to_string(v_parts, ' ');
END;
$$ LANGUAGE plpgsql STABLE;

CREATE OR REPLACE FUNCTION fn_generate_address(
    p_seed   BIGINT,
    p_batch  INT,
    p_idx    INT,
    p_locale TEXT
) RETURNS TEXT AS $$
DECLARE
    v_house        BIGINT;
    v_street_name  TEXT;
    v_street_type  TEXT;
    v_street_fmt   TEXT;
    v_city         TEXT;
    v_region       TEXT;
    v_postal       TEXT;
    v_street_full  TEXT;
BEGIN
    v_house := fn_hash_int(p_seed, p_batch, p_idx, 'addr:house', 1, 9999);
    v_street_name := fn_pick_street_name(p_seed, p_batch, p_idx, 'addr:street_name', p_locale);

    SELECT * FROM fn_pick_street_type(p_seed, p_batch, p_idx, 'addr:street_type', p_locale)
    INTO v_street_type, v_street_fmt;

    IF v_street_fmt = 'suffix_nospace' THEN
        v_street_full := v_street_name || v_street_type;
    ELSE
        v_street_full := v_street_name || ' ' || v_street_type;
    END IF;

    SELECT * FROM fn_pick_city(p_seed, p_batch, p_idx, 'addr:city', p_locale)
    INTO v_city, v_region, v_postal;

    -- hardcoding, but i thought making a separate address_types tables just for these 2 was overkill
    IF p_locale = 'en_US' THEN
        RETURN v_house || ' ' || v_street_full
            || ', ' || v_city
            || ', ' || v_region
            || ' ' || v_postal;
    ELSIF p_locale = 'de_DE' THEN
        RETURN v_street_full || ' ' || v_house
            || ', ' || v_postal
            || ' ' || v_city;
    ELSE
        RAISE EXCEPTION 'fn_generate_address: unsupported locale %', p_locale;
    END IF;
END;
$$ LANGUAGE plpgsql STABLE;

COMMIT;