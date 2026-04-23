BEGIN;

CREATE TYPE user_row AS (
	locale text,
	seed int8,
	batch_idx int4,
	idx_in_batch int4,
	gender text,
	full_name text,
	address text,
	phone text,
	email text,
	height_cm numeric,
	weight_kg numeric,
	eye_color text,
	hair_color text,
	lat float8,
	lon float8
);

CREATE OR REPLACE FUNCTION fn_generate_user(
    p_seed BIGINT,
    p_batch INT,
    p_idx INT,
    p_locale TEXT
) RETURNS user_row AS $$
DECLARE
    v_result user_row;
    v_height_mean DOUBLE PRECISION;
    v_height_stddev DOUBLE PRECISION;
    v_weight_mean DOUBLE PRECISION;
    v_weight_stddev DOUBLE PRECISION;
    v_raw_height DOUBLE PRECISION;
    v_raw_weight DOUBLE PRECISION;
    v_lat DOUBLE PRECISION;
    v_lon DOUBLE PRECISION;
BEGIN
    v_result.locale := p_locale;
    v_result.seed := p_seed;
    v_result.batch_idx := p_batch;
    v_result.idx_in_batch := p_idx;

    v_result.gender := CASE
        WHEN fn_hash_uniform(p_seed, p_batch, p_idx, 'user:gender') < 0.5
        THEN 'm' ELSE 'f'
    END;

    v_result.full_name := fn_generate_full_name(p_seed, p_batch, p_idx, p_locale, v_result.gender);
    v_result.email := fn_generate_email(p_seed, p_batch, p_idx, p_locale, v_result.gender);
    v_result.address := fn_generate_address(p_seed, p_batch, p_idx, p_locale);
    v_result.phone := fn_generate_phone(p_seed, p_batch, p_idx, p_locale);

    IF v_result.gender = 'm' THEN
        v_height_mean := 178; v_height_stddev := 7;
        v_weight_mean := 82;  v_weight_stddev := 12;
    ELSE
        v_height_mean := 165; v_height_stddev := 6;
        v_weight_mean := 68;  v_weight_stddev := 11;
    END IF;

    v_raw_height := fn_hash_normal(p_seed, p_batch, p_idx, 'user:height', v_height_mean, v_height_stddev);
    v_raw_weight := fn_hash_normal(p_seed, p_batch, p_idx, 'user:weight', v_weight_mean, v_weight_stddev);
    v_result.height_cm := ROUND(GREATEST(140, LEAST(210, v_raw_height))::NUMERIC, 1);
    v_result.weight_kg := ROUND(GREATEST(40,  LEAST(150, v_raw_weight))::NUMERIC, 1);

    v_result.eye_color := fn_pick_eye_color (p_seed, p_batch, p_idx, 'user:eye',  p_locale);
    v_result.hair_color := fn_pick_hair_color(p_seed, p_batch, p_idx, 'user:hair', p_locale);

    SELECT * FROM fn_generate_geolocation(p_seed, p_batch, p_idx) INTO v_lat, v_lon;
    v_result.lat := ROUND(v_lat::NUMERIC, 4);
    v_result.lon := ROUND(v_lon::NUMERIC, 4);

    RETURN v_result;
END;
$$ LANGUAGE plpgsql STABLE;

CREATE OR REPLACE FUNCTION fn_generate_batch(
    p_seed BIGINT,
    p_batch INT,
    p_locale TEXT,
    p_batch_size INT
) RETURNS SETOF user_row AS $$
    SELECT fn_generate_user(p_seed, p_batch, i, p_locale)
    FROM generate_series(0, p_batch_size - 1) g(i);
$$ LANGUAGE sql STABLE;

COMMIT;