BEGIN;

CREATE OR REPLACE FUNCTION fn_generate_full_name(
    p_seed BIGINT,
    p_batch INT,
    p_idx INT,
    p_locale TEXT,
    p_gender TEXT
) RETURNS TEXT AS $$
DECLARE
    v_has_title BOOLEAN;
    v_has_middle BOOLEAN;
    v_title TEXT;
    v_first TEXT;
    v_middle TEXT;
    v_last TEXT;
    v_parts TEXT[] := ARRAY[]::TEXT[];
BEGIN
    v_has_title := fn_hash_uniform(p_seed, p_batch, p_idx, 'name:has_title')  < 0.20;
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
    p_seed BIGINT,
    p_batch INT,
    p_idx INT,
    p_locale TEXT
) RETURNS TEXT AS $$
DECLARE
    v_house BIGINT;
    v_street_name TEXT;
    v_street_type TEXT;
    v_street_fmt TEXT;
    v_city TEXT;
    v_region TEXT;
    v_postal TEXT;
    v_street_full TEXT;
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

CREATE OR REPLACE FUNCTION fn_generate_phone(
    p_seed BIGINT,
    p_batch INT,
    p_idx INT,
    p_locale TEXT
) RETURNS TEXT AS $$
DECLARE
    v_pattern TEXT;
    v_result TEXT := '';
    v_char TEXT;
    v_digit INT;
    v_digit_counter INT := 0;
    i INT;
BEGIN
    v_pattern := fn_pick_phone_format(p_seed, p_batch, p_idx, 'phone:format', p_locale);

    FOR i IN 1 .. length(v_pattern) LOOP
        v_char := substring(v_pattern FROM i FOR 1);
        IF v_char = '#' THEN
            v_digit := fn_hash_int(p_seed, p_batch, p_idx, 'phone:digit_' || v_digit_counter::TEXT, 0, 9)::INT;
            v_result := v_result || v_digit::TEXT;
            v_digit_counter := v_digit_counter + 1;
        ELSE
            v_result := v_result || v_char;
        END IF;
    END LOOP;

    RETURN v_result;
END;
$$ LANGUAGE plpgsql STABLE;

CREATE OR REPLACE FUNCTION fn_generate_email(
    p_seed BIGINT,
    p_batch INT,
    p_idx INT,
    p_locale TEXT,
    p_gender TEXT
) RETURNS TEXT AS $$
DECLARE
    v_first TEXT;
    v_last TEXT;
    v_domain TEXT;
    v_pattern DOUBLE PRECISION;
    v_suffix INT;
    v_local TEXT;
BEGIN
    v_first := fn_pick_name(p_seed, p_batch, p_idx, 'name:first', p_locale, 'first', p_gender);
    v_last := fn_pick_name(p_seed, p_batch, p_idx, 'name:last', p_locale, 'last',  'u');

    v_first := replace(lower(v_first), 'ß', 'ss');
    v_first := translate(v_first, 'äöüéèêàáâñç', 'aoueeeaaanc');
    v_first := regexp_replace(v_first, '[^a-z0-9]', '', 'g');

    v_last := replace(lower(v_last), 'ß', 'ss');
    v_last := translate(v_last, 'äöüéèêàáâñç', 'aoueeeaaanc');
    v_last := regexp_replace(v_last, '[^a-z0-9]', '', 'g');

    v_pattern := fn_hash_uniform(p_seed, p_batch, p_idx, 'email:pattern');

    IF v_pattern < 0.50 THEN
        v_local := v_first || '.' || v_last;
    ELSIF v_pattern < 0.80 THEN
        v_local := substring(v_first FROM 1 FOR 1) || v_last;
    ELSE
        v_suffix := fn_hash_int(p_seed, p_batch, p_idx, 'email:suffix', 0, 99)::INT;
        v_local := v_first || '_' || v_last || lpad(v_suffix::TEXT, 2, '0');
    END IF;

    v_domain := fn_pick_email_domain(p_seed, p_batch, p_idx, 'email:domain', p_locale);

    RETURN v_local || '@' || v_domain;
END;
$$ LANGUAGE plpgsql STABLE;

CREATE OR REPLACE FUNCTION fn_generate_geolocation(
    p_seed BIGINT,
    p_batch INT,
    p_idx INT,
    OUT lat DOUBLE PRECISION,
    OUT lon DOUBLE PRECISION
) AS $$
BEGIN
    SELECT * FROM fn_hash_sphere_point(p_seed, p_batch, p_idx)
    INTO lat, lon;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

COMMIT;