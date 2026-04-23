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
        AND gender = p_gender;

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
    p_locale TEXT
) RETURNS BIGINT AS $$
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
        RAISE EXCEPTION 'fn_pick_city_id: no cities for locale=%', p_locale;
    END IF;

    v_picked_id := fn_hash_weighted_pick_id(p_seed, p_batch, p_idx, p_field, v_ids, v_weights);
    RETURN (SELECT city, region, postal_code FROM cities WHERE id=v_picked_id);
END;
$$ LANGUAGE plpgsql STABLE;

COMMIT;