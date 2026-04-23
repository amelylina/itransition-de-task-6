BEGIN;

CREATE OR REPLACE FUNCTION fn_hash_uniform(
    p_seed BIGINT,
    p_batch INT,
    p_idx INT,
    p_field TEXT
) RETURNS DOUBLE PRECISION AS $$
DECLARE
    v_hash TEXT;
    v_int NUMERIC;
BEGIN
    v_hash := md5(p_seed::TEXT || ':' || p_batch::TEXT || ':' ||
                p_idx::TEXT  || ':' || p_field);
    v_int := ('x' || substring(v_hash, 1, 16))::BIT(64)::BIGINT::NUMERIC;
    IF v_int < 0 THEN
        v_int := v_int + (2::NUMERIC ^ 64);
    END IF;
    RETURN (v_int / (2::NUMERIC ^ 64))::DOUBLE PRECISION;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

CREATE OR REPLACE FUNCTION fn_hash_int(
    p_seed BIGINT,
    p_batch INT,
    p_idx INT,
    p_field TEXT,
    p_lo BIGINT,
    p_hi BIGINT
) RETURNS BIGINT AS $$
DECLARE
    v_u DOUBLE PRECISION;
BEGIN
    IF p_lo > p_hi THEN
        RAISE EXCEPTION 'fn_hash_int: p_lo (%) must be <= p_hi (%)', p_lo, p_hi;
    END IF;
    v_u := fn_hash_uniform(p_seed, p_batch, p_idx, p_field);
    RETURN p_lo + FLOOR(v_u * (p_hi - p_lo + 1))::BIGINT;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Box Muller algorithm, dont need second value
CREATE OR REPLACE FUNCTION fn_hash_normal(
    p_seed BIGINT,
    p_batch INT,
    p_idx INT,
    p_field TEXT,
    p_mean DOUBLE PRECISION,
    p_stddev DOUBLE PRECISION
) RETURNS DOUBLE PRECISION AS $$
DECLARE
    v_u1 DOUBLE PRECISION;
    v_u2 DOUBLE PRECISION;
    v_z  DOUBLE PRECISION;
    v_epsilon CONSTANT DOUBLE PRECISION := 1e-15;
BEGIN
    IF p_stddev <= 0 THEN
        RAISE EXCEPTION 'fn_hash_normal: p_stddev (%) must be > 0', p_stddev;
    END IF;
    v_u1 := fn_hash_uniform(p_seed, p_batch, p_idx, p_field || ':u1');
    v_u2 := fn_hash_uniform(p_seed, p_batch, p_idx, p_field || ':u2');
    IF v_u1 < v_epsilon THEN
        v_u1 := v_epsilon;
    END IF;
    v_z := SQRT(-2.0 * LN(v_u1)) * COS(2.0 * PI() * v_u2);
    RETURN p_mean + p_stddev * v_z;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Lambert cylindrical sphere projection algo
CREATE OR REPLACE FUNCTION fn_hash_sphere_point(
    p_seed BIGINT,
    p_batch INT,
    p_idx INT,
    OUT lat DOUBLE PRECISION,
    OUT lon DOUBLE PRECISION
) AS $$
DECLARE
    v_u DOUBLE PRECISION;
    v_v DOUBLE PRECISION;
BEGIN
    v_u := fn_hash_uniform(p_seed, p_batch, p_idx, 'geo:lon');
    v_v := fn_hash_uniform(p_seed, p_batch, p_idx, 'geo:lat');

    lon := 360.0 * v_u - 180.0;
    lat := DEGREES(ASIN(2.0 * v_v - 1.0));
END;
$$ LANGUAGE plpgsql IMMUTABLE;

CREATE OR REPLACE FUNCTION fn_hash_weighted_pick_id(
    p_seed BIGINT,
    p_batch INT,
    p_idx INT,
    p_field TEXT,
    p_ids BIGINT[],
    p_weights INT[]
) RETURNS BIGINT AS $$
DECLARE
    v_total BIGINT := 0;
    v_target DOUBLE PRECISION;
    v_running BIGINT := 0;
    v_u DOUBLE PRECISION;
    v_len INT;
    i INT;
BEGIN
    v_len := COALESCE(array_length(p_ids, 1), 0);
    IF v_len = 0 THEN
        RAISE EXCEPTION 'fn_hash_weighted_pick_id: empty candidate list';
    END IF;
    IF v_len <> COALESCE(array_length(p_weights, 1), 0) THEN
        RAISE EXCEPTION 'fn_hash_weighted_pick_id: ids/weights length mismatch';
    END IF;

    FOR i IN 1 .. v_len LOOP
        IF p_weights[i] <= 0 THEN
            RAISE EXCEPTION 'fn_hash_weighted_pick_id: non-positive weight at position %', i;
        END IF;
        v_total := v_total + p_weights[i];
    END LOOP;

    v_u := fn_hash_uniform(p_seed, p_batch, p_idx, p_field);
    v_target := v_u * v_total;

    FOR i IN 1 .. v_len LOOP
        v_running := v_running + p_weights[i];
        IF v_running > v_target THEN
            RETURN p_ids[i];
        END IF;
    END LOOP;

    RETURN p_ids[v_len];
END;
$$ LANGUAGE plpgsql IMMUTABLE;

COMMIT;