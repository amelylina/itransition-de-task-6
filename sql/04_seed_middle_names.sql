INSERT INTO names (locale, name_type, gender, value, freq_weight)
SELECT
    locale,
    'middle' AS name_type,
    gender,
    value,
    GREATEST(freq_weight / 10, 1) AS freq_weight
FROM names
WHERE name_type = 'first';