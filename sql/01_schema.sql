BEGIN;

DROP TYPE IF EXISTS user_row CASCADE;
DROP TABLE IF EXISTS locales CASCADE;
DROP TABLE IF EXISTS names CASCADE;
DROP TABLE IF EXISTS titles CASCADE;
DROP TABLE IF EXISTS cities CASCADE;
DROP TABLE IF EXISTS street_names CASCADE;
DROP TABLE IF EXISTS street_types CASCADE;
DROP TABLE IF EXISTS email_domains CASCADE;
DROP TABLE IF EXISTS eye_colors CASCADE;
DROP TABLE IF EXISTS hair_colors CASCADE;
DROP TABLE IF EXISTS phone_formats CASCADE;
DROP TABLE IF EXISTS picker_cache CASCADE;

CREATE TABLE locales (
    code TEXT PRIMARY KEY,
    name TEXT NOT NULL
);

CREATE TABLE names (
    id BIGSERIAL PRIMARY KEY,
    locale TEXT NOT NULL REFERENCES locales(code),
    name_type TEXT NOT NULL CHECK (name_type IN ('first','middle','last')),
    gender TEXT NOT NULL CHECK (gender IN ('m','f','u')),
    value TEXT NOT NULL,
    freq_weight INT NOT NULL DEFAULT 1
);
CREATE INDEX idx_names_lookup ON names (locale, name_type, gender);

CREATE TABLE titles (
    id BIGSERIAL PRIMARY KEY,
    locale TEXT NOT NULL REFERENCES locales(code),
    value TEXT NOT NULL,
    gender TEXT NOT NULL CHECK (gender IN ('m','f','u')),
    freq_weight INT NOT NULL DEFAULT 1
);
CREATE INDEX idx_titles_locale ON titles (locale, gender);

CREATE TABLE cities (
    id BIGSERIAL PRIMARY KEY,
    locale TEXT NOT NULL REFERENCES locales(code),
    city TEXT NOT NULL,
    region TEXT NOT NULL,
    postal_code TEXT NOT NULL,
    freq_weight INT NOT NULL DEFAULT 1
);
CREATE INDEX idx_cities_locale ON cities (locale);

CREATE TABLE street_names (
    id BIGSERIAL PRIMARY KEY,
    locale TEXT NOT NULL REFERENCES locales(code),
    value TEXT NOT NULL,
    freq_weight INT NOT NULL DEFAULT 1
);
CREATE INDEX idx_street_names_locale ON street_names (locale);

CREATE TABLE street_types (
    id BIGSERIAL PRIMARY KEY,
    locale TEXT NOT NULL REFERENCES locales(code),
    value TEXT NOT NULL,
    freq_weight INT NOT NULL DEFAULT 1,
    format TEXT NOT NULL CHECK (format IN ('suffix_space','suffix_nospace'))
);
CREATE INDEX idx_street_types_locale ON street_types (locale);

CREATE TABLE email_domains (
    id BIGSERIAL PRIMARY KEY,
    locale TEXT REFERENCES locales(code),
    domain TEXT NOT NULL,
    freq_weight INT NOT NULL DEFAULT 1
);
CREATE INDEX idx_email_domains_locale ON email_domains (locale);

CREATE TABLE eye_colors (
    id BIGSERIAL PRIMARY KEY,
    locale TEXT NOT NULL REFERENCES locales(code),
    value TEXT NOT NULL,
    freq_weight INT NOT NULL DEFAULT 1
);
CREATE INDEX idx_eye_colors_locale ON eye_colors (locale);

CREATE TABLE hair_colors (
    id BIGSERIAL PRIMARY KEY,
    locale TEXT NOT NULL REFERENCES locales(code),
    value TEXT NOT NULL,
    freq_weight INT NOT NULL DEFAULT 1
);
CREATE INDEX idx_hair_colors_locale ON hair_colors (locale);

CREATE TABLE phone_formats (
    id BIGSERIAL PRIMARY KEY,
    locale TEXT NOT NULL REFERENCES locales(code),
    pattern TEXT NOT NULL,
    freq_weight INT NOT NULL DEFAULT 1
);
CREATE INDEX idx_phone_formats_locale ON phone_formats (locale);

COMMIT;