BEGIN;

CREATE OR REPLACE FUNCTION fn_pick_name(
    p_seed      BIGINT,
    p_batch     INT,
    p_idx       INT,
    p_field     TEXT,
    p_locale    TEXT,
    p_name_type TEXT,
    p_gender    TEXT
) RETURNS TEXT AS $$
DECLARE
    v_ids       BIGINT[];
    v_weights   INT[];
    v_picked_id BIGINT;
BEGIN
    SELECT array_agg(id ORDER BY id),
        array_agg(freq_weight ORDER BY id)
    INTO v_ids, v_weights
    FROM names
    WHERE locale = p_locale
        AND name_type = p_name_type
        AND (gender = p_gender OR gender = 'u');

    IF v_ids IS NULL THEN
        RAISE EXCEPTION 'fn_pick_name: no names for locale=%, name_type=%, gender=%',
            p_locale, p_name_type, p_gender;
    END IF;

    v_picked_id := fn_hash_weighted_pick_id(
        p_seed, p_batch, p_idx, p_field, v_ids, v_weights
    );
    RETURN (SELECT value FROM names WHERE id = v_picked_id);
END;
$$ LANGUAGE plpgsql STABLE;

CREATE OR REPLACE FUNCTION fn_pick_city(
    p_seed   BIGINT,
    p_batch  INT,
    p_idx    INT,
    p_field  TEXT,
    p_locale TEXT,
    OUT city TEXT,
    OUT region TEXT,
    OUT postal_code TEXT
) AS $$
DECLARE
    v_ids     BIGINT[];
    v_weights INT[];
    v_picked_id BIGINT;
BEGIN
    SELECT array_agg(id ORDER BY id),
        array_agg(freq_weight ORDER BY id)
    INTO v_ids, v_weights
    FROM cities
    WHERE locale = p_locale;

    IF v_ids IS NULL THEN
        RAISE EXCEPTION 'fn_pick_city: no cities for locale=%', p_locale;
    END IF;

    v_picked_id := fn_hash_weighted_pick_id(
        p_seed, p_batch, p_idx, p_field, v_ids, v_weights
    );

    SELECT c.city, c.region, c.postal_code
    INTO city, region, postal_code
    FROM cities c WHERE c.id = v_picked_id;
END;
$$ LANGUAGE plpgsql STABLE;

CREATE OR REPLACE FUNCTION fn_pick_title(
    p_seed      BIGINT,
    p_batch     INT,
    p_idx       INT,
    p_field     TEXT,
    p_locale    TEXT,
    p_gender    TEXT
) RETURNS TEXT AS $$
DECLARE
    v_ids       BIGINT[];
    v_weights   INT[];
    v_picked_id BIGINT;
BEGIN
    SELECT array_agg(id ORDER BY id),
        array_agg(freq_weight ORDER BY id)
    INTO v_ids, v_weights
    FROM titles
    WHERE locale = p_locale
        AND (gender = p_gender OR gender = 'u');

    IF v_ids IS NULL THEN
        RAISE EXCEPTION 'fn_pick_title: no titles for locale=%, gender=%',
            p_locale, p_gender;
    END IF;

    v_picked_id := fn_hash_weighted_pick_id(
        p_seed, p_batch, p_idx, p_field, v_ids, v_weights
    );
    RETURN (SELECT value FROM titles WHERE id = v_picked_id);
END;
$$ LANGUAGE plpgsql STABLE;

CREATE OR REPLACE FUNCTION fn_pick_eye_color(
    p_seed      BIGINT,
    p_batch     INT,
    p_idx       INT,
    p_field     TEXT,
    p_locale    TEXT
) RETURNS TEXT AS $$
DECLARE
    v_ids       BIGINT[];
    v_weights   INT[];
    v_picked_id BIGINT;
BEGIN
    SELECT array_agg(id ORDER BY id),
        array_agg(freq_weight ORDER BY id)
    INTO v_ids, v_weights
    FROM eye_colors
    WHERE locale = p_locale;

    IF v_ids IS NULL THEN
        RAISE EXCEPTION 'fn_pick_eye_color: no colors for locale=%',
            p_locale;
    END IF;

    v_picked_id := fn_hash_weighted_pick_id(
        p_seed, p_batch, p_idx, p_field, v_ids, v_weights
    );
    RETURN (SELECT value FROM eye_colors WHERE id = v_picked_id);
END;
$$ LANGUAGE plpgsql STABLE;

CREATE OR REPLACE FUNCTION fn_pick_hair_color(
    p_seed      BIGINT,
    p_batch     INT,
    p_idx       INT,
    p_field     TEXT,
    p_locale    TEXT
) RETURNS TEXT AS $$
DECLARE
    v_ids       BIGINT[];
    v_weights   INT[];
    v_picked_id BIGINT;
BEGIN
    SELECT array_agg(id ORDER BY id),
        array_agg(freq_weight ORDER BY id)
    INTO v_ids, v_weights
    FROM hair_colors
    WHERE locale = p_locale;

    IF v_ids IS NULL THEN
        RAISE EXCEPTION 'fn_pick_hair_color: no colors for locale=%',
            p_locale;
    END IF;

    v_picked_id := fn_hash_weighted_pick_id(
        p_seed, p_batch, p_idx, p_field, v_ids, v_weights
    );
    RETURN (SELECT value FROM hair_colors WHERE id = v_picked_id);
END;
$$ LANGUAGE plpgsql STABLE;

CREATE OR REPLACE FUNCTION fn_pick_email_domain(
    p_seed      BIGINT,
    p_batch     INT,
    p_idx       INT,
    p_field     TEXT,
    p_locale    TEXT
) RETURNS TEXT AS $$
DECLARE
    v_ids       BIGINT[];
    v_weights   INT[];
    v_picked_id BIGINT;
BEGIN
    SELECT array_agg(id ORDER BY id),
        array_agg(freq_weight ORDER BY id)
    INTO v_ids, v_weights
    FROM email_domains
    WHERE locale = p_locale OR locale IS NULL;

    IF v_ids IS NULL THEN
        RAISE EXCEPTION 'fn_pick_email_domain: no email domains for locale=%',
            p_locale;
    END IF;

    v_picked_id := fn_hash_weighted_pick_id(
        p_seed, p_batch, p_idx, p_field, v_ids, v_weights
    );
    RETURN (SELECT domain FROM email_domains WHERE id = v_picked_id);
END;
$$ LANGUAGE plpgsql STABLE;

CREATE OR REPLACE FUNCTION fn_pick_street_name(
    p_seed      BIGINT,
    p_batch     INT,
    p_idx       INT,
    p_field     TEXT,
    p_locale    TEXT
) RETURNS TEXT AS $$
DECLARE
    v_ids       BIGINT[];
    v_weights   INT[];
    v_picked_id BIGINT;
BEGIN
    SELECT array_agg(id ORDER BY id),
        array_agg(freq_weight ORDER BY id)
    INTO v_ids, v_weights
    FROM street_names
    WHERE locale = p_locale;

    IF v_ids IS NULL THEN
        RAISE EXCEPTION 'fn_pick_street_name: no street names for locale=%',
            p_locale;
    END IF;

    v_picked_id := fn_hash_weighted_pick_id(
        p_seed, p_batch, p_idx, p_field, v_ids, v_weights
    );
    RETURN (SELECT value FROM street_names WHERE id = v_picked_id);
END;
$$ LANGUAGE plpgsql STABLE;

CREATE OR REPLACE FUNCTION fn_pick_street_type(
    p_seed      BIGINT,
    p_batch     INT,
    p_idx       INT,
    p_field     TEXT,
    p_locale    TEXT
) RETURNS TEXT AS $$
DECLARE
    v_ids       BIGINT[];
    v_weights   INT[];
    v_picked_id BIGINT;
BEGIN
    SELECT array_agg(id ORDER BY id),
        array_agg(freq_weight ORDER BY id)
    INTO v_ids, v_weights
    FROM street_types
    WHERE locale = p_locale;

    IF v_ids IS NULL THEN
        RAISE EXCEPTION 'fn_pick_street_type: no street types for locale=%',
            p_locale;
    END IF;

    v_picked_id := fn_hash_weighted_pick_id(
        p_seed, p_batch, p_idx, p_field, v_ids, v_weights
    );
    RETURN (SELECT value FROM street_types WHERE id = v_picked_id);
END;
$$ LANGUAGE plpgsql STABLE;

CREATE OR REPLACE FUNCTION fn_pick_phone_format(
    p_seed      BIGINT,
    p_batch     INT,
    p_idx       INT,
    p_field     TEXT,
    p_locale    TEXT
) RETURNS TEXT AS $$
DECLARE
    v_ids       BIGINT[];
    v_weights   INT[];
    v_picked_id BIGINT;
BEGIN
    SELECT array_agg(id ORDER BY id),
        array_agg(freq_weight ORDER BY id)
    INTO v_ids, v_weights
    FROM phone_formats
    WHERE locale = p_locale;

    IF v_ids IS NULL THEN
        RAISE EXCEPTION 'fn_pick_phone_format: no phone formats for locale=%',
            p_locale;
    END IF;

    v_picked_id := fn_hash_weighted_pick_id(
        p_seed, p_batch, p_idx, p_field, v_ids, v_weights
    );
    RETURN (SELECT pattern FROM phone_formats WHERE id = v_picked_id);
END;
$$ LANGUAGE plpgsql STABLE;

COMMIT;