BEGIN;

TRUNCATE TABLE
    titles, street_types, email_domains, eye_colors,
    hair_colors, phone_formats
RESTART IDENTITY;

INSERT INTO titles (locale, value, gender, freq_weight) VALUES
    ('en_US', 'Mr.',   'm', 50),
    ('en_US', 'Mrs.',  'f', 30),
    ('en_US', 'Ms.',   'f', 20),
    ('en_US', 'Miss',  'f', 5),
    ('en_US', 'Dr.',   'u', 3),
    ('en_US', 'Prof.', 'u', 1),
    ('de_DE', 'Herr',  'm', 50),
    ('de_DE', 'Frau',  'f', 50),
    ('de_DE', 'Dr.',   'u', 5),
    ('de_DE', 'Prof.', 'u', 1);

INSERT INTO street_types (locale, value, freq_weight, format) VALUES
    ('en_US', 'Street',   50, 'suffix_space'),
    ('en_US', 'Avenue',   20, 'suffix_space'),
    ('en_US', 'Boulevard', 5, 'suffix_space'),
    ('en_US', 'Road',     15, 'suffix_space'),
    ('en_US', 'Lane',     10, 'suffix_space'),
    ('en_US', 'Drive',    10, 'suffix_space'),
    ('en_US', 'Court',     5, 'suffix_space'),
    ('en_US', 'Way',       5, 'suffix_space'),
    ('de_DE', 'straße',   60, 'suffix_nospace'),
    ('de_DE', 'weg',      15, 'suffix_nospace'),
    ('de_DE', 'allee',    10, 'suffix_nospace'),
    ('de_DE', 'platz',     8, 'suffix_nospace'),
    ('de_DE', 'gasse',     5, 'suffix_nospace'),
    ('de_DE', 'ring',      3, 'suffix_nospace');

INSERT INTO email_domains (locale, domain, freq_weight) VALUES
    (NULL, 'gmail.com',   50),
    (NULL, 'yahoo.com',   15),
    (NULL, 'outlook.com', 15),
    (NULL, 'hotmail.com', 10),
    (NULL, 'icloud.com',  10),
    (NULL, 'proton.me',    3),
    ('en_US', 'aol.com',       5),
    ('en_US', 'comcast.net',   3),
    ('en_US', 'verizon.net',   2),
    ('de_DE', 'gmx.de',       20),
    ('de_DE', 'web.de',       15),
    ('de_DE', 't-online.de',  10),
    ('de_DE', 'freenet.de',    5),
    ('de_DE', 'gmx.net',       5);

INSERT INTO eye_colors (locale, value, freq_weight) VALUES
    ('en_US', 'brown', 45),
    ('en_US', 'blue',  27),
    ('en_US', 'hazel', 18),
    ('en_US', 'green',  9),
    ('en_US', 'gray',   1),
    ('de_DE', 'blue',  40),
    ('de_DE', 'brown', 30),
    ('de_DE', 'green', 15),
    ('de_DE', 'hazel', 10),
    ('de_DE', 'gray',   5);

INSERT INTO hair_colors (locale, value, freq_weight) VALUES
    ('en_US', 'brown', 40),
    ('en_US', 'black', 30),
    ('en_US', 'blonde', 20),
    ('en_US', 'red',    5),
    ('en_US', 'gray',   5),
    ('de_DE', 'brown', 35),
    ('de_DE', 'blonde', 30),
    ('de_DE', 'black', 15),
    ('de_DE', 'gray',  15),
    ('de_DE', 'red',    5);

INSERT INTO phone_formats (locale, pattern, freq_weight) VALUES
    ('en_US', '(###) ###-####',  40),
    ('en_US', '###-###-####',    30),
    ('en_US', '### ### ####',    10),
    ('en_US', '+1 ### ### ####', 10),
    ('en_US', '###.###.####',    10),
    ('de_DE', '+49 ### #######',  30),
    ('de_DE', '0### #######',     40),
    ('de_DE', '0### ### ####',    15),
    ('de_DE', '+49 (###) #######', 15);

COMMIT;