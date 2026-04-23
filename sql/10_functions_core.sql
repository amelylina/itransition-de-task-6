BEGIN;
CREATE OR REPLACE FUNCTION fn_hash_uniform(
    p_seed  BIGINT,
    p_batch INT,
    p_idx   INT,
    p_field TEXT
) RETURNS DOUBLE PRECISION AS $$
DECLARE
    v_hash TEXT;
    v_int  NUMERIC;
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

COMMIT;