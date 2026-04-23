INSERT INTO locales (code, name) VALUES
    ('en_US', 'English (United States)'),
    ('de_DE', 'German (Germany)')
ON CONFLICT (code) DO NOTHING;