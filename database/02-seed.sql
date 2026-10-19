-- =====================================================================
--  Données de départ : modifie-les ou pilote tout depuis le bot Telegram
-- =====================================================================

-- Profil minimal : envoie ton CV en PDF au bot pour le remplir automatiquement
INSERT INTO profile (id, full_name, headline, target_roles, skills, locations, contract_types, languages, remote_preference, preferences)
VALUES (
  1,
  'Ton nom',
  'Développeur·se junior passionné·e par l''automatisation',
  ARRAY['Développeur web', 'Développeur automatisation', 'Data analyst'],
  ARRAY['JavaScript', 'Python', 'SQL', 'n8n', 'API REST', 'Git'],
  ARRAY['Paris', 'Île-de-France', 'Télétravail'],
  ARRAY['CDI', 'Alternance'],
  ARRAY['Français', 'Anglais'],
  'hybride',
  'Je cherche une équipe bienveillante, avec du mentorat et des projets concrets.'
);

-- Recherches France Travail (département vide = toute la France)
INSERT INTO searches (label, keywords, department, contract_type) VALUES
  ('Dev web Paris',          'développeur javascript', '75', 'CDI'),
  ('Automatisation / no-code', 'automatisation n8n',   NULL, NULL),
  ('Data analyst IDF',       'data analyst',           '92', NULL);

-- Flux RSS d'offres (international / remote)
INSERT INTO feeds (name, url) VALUES
  ('We Work Remotely · Programmation', 'https://weworkremotely.com/categories/remote-programming-jobs.rss'),
  ('Remotive · Développement',         'https://remotive.com/remote-jobs/feed/software-dev');
