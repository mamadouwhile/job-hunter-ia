-- =====================================================================
--  Données de démonstration (optionnel) : remplit le dashboard pour une démo / des captures
--  docker compose exec -T postgres psql -U jobhunter -d jobhunter < database/demo-data.sql
--  ⚠️ Toutes les entreprises sont fictives.
-- =====================================================================
WITH titles(t, company, loc, contract) AS (VALUES
  ('Développeur·se Full-Stack JavaScript', 'Nébula Tech', 'Paris 11e', 'CDI'),
  ('Développeur·se React junior', 'Pixel & Co', 'Lyon', 'CDI'),
  ('Ingénieur·e automatisation (n8n / Make)', 'FlowFactory', 'Télétravail', 'CDI'),
  ('Développeur·se Node.js / API', 'Orbital Data', 'Nantes', 'CDI'),
  ('Data Analyst SQL / Python', 'Insight Lab', 'Bordeaux', 'CDD'),
  ('Développeur·se Front-end Vue.js', 'Studio Lumen', 'Paris 2e', 'CDI'),
  ('Alternance · Développeur·se web', 'Campus Digital', 'Lille', 'Alternance'),
  ('Intégrateur·rice no-code', 'Agence Brique', 'Rennes', 'Freelance'),
  ('Développeur·se Python Django', 'GreenGrid', 'Grenoble', 'CDI'),
  ('Développeur·se TypeScript / NestJS', 'Kairos Santé', 'Paris 15e', 'CDI'),
  ('Ops Automation Specialist', 'Remote First Inc.', 'Remote', 'CDI'),
  ('Développeur·se Java Senior', 'BankCore', 'La Défense', 'CDI'),
  ('Développeur·se mobile React Native', 'Appetit', 'Marseille', 'CDI'),
  ('Product Engineer IA', 'Synapse AI', 'Paris 9e', 'CDI'),
  ('Développeur·se PHP Symfony', 'Logistik', 'Toulouse', 'CDI'),
  ('Data Engineer junior', 'Cumulus', 'Lyon', 'CDI'),
  ('Développeur·se WordPress', 'Agence Pivot', 'Nice', 'CDD'),
  ('Lead Dev Kubernetes / Go', 'CloudForge', 'Paris 8e', 'CDI'),
  ('Développeur·se low-code / API', 'Mutuelle Horizon', 'Niort', 'CDI'),
  ('Développeur·se JavaScript (stage de fin d''études)', 'EdTech Nova', 'Paris 13e', 'Stage')
), numbered AS (
  SELECT row_number() OVER () AS n, * FROM titles
)
INSERT INTO jobs (source, external_id, url, title, company, location, contract_type, description, collected_at,
                  score, verdict, summary, strengths, gaps, missing_skills, key_skills, seniority, remote, estimated_salary, scored_at, status, alerted_at)
SELECT 'demo', 'demo-' || n, 'https://example.com/offre/' || n, t, company, loc, contract,
       'Offre de démonstration pour ' || t || '.',
       now() - (n * interval '16 hours'),
       s.score,
       CASE WHEN s.score >= 85 THEN 'excellent' WHEN s.score >= 70 THEN 'bon' WHEN s.score >= 50 THEN 'moyen' ELSE 'faible' END,
       'Poste de ' || lower(t) || ' dans une équipe à taille humaine.',
       ARRAY['Stack JavaScript maîtrisée', 'Expérience en automatisation'],
       ARRAY['Expérience en production limitée'],
       string_to_array((ARRAY['Docker,TypeScript', 'Docker,AWS', 'TypeScript,Tests', 'Kubernetes,Docker', 'GraphQL,TypeScript'])[1 + n % 5], ','),
       ARRAY['JavaScript','Node.js','SQL'],
       CASE WHEN t ILIKE '%senior%' OR t ILIKE '%lead%' THEN 'senior' ELSE 'junior' END,
       (ARRAY['hybride','full remote','sur site'])[1 + n % 3],
       '35-45 k€ brut/an',
       now() - (n * interval '16 hours') + interval '5 minutes',
       'new', CASE WHEN s.score >= 75 THEN now() - (n * interval '16 hours') + interval '6 minutes' END
FROM numbered
CROSS JOIN LATERAL (SELECT (ARRAY[92,88,95,84,67,79,90,73,61,86,81,28,58,89,47,76,35,22,71,83])[n] AS score) s;

-- Parcours de candidature réaliste
UPDATE jobs SET status = 'applied'   WHERE source = 'demo' AND external_id IN ('demo-1','demo-2','demo-4','demo-6','demo-10','demo-16');
UPDATE jobs SET status = 'interview' WHERE source = 'demo' AND external_id IN ('demo-3','demo-14');
UPDATE jobs SET status = 'offer'     WHERE source = 'demo' AND external_id = 'demo-11';
UPDATE jobs SET status = 'rejected'  WHERE source = 'demo' AND external_id IN ('demo-7','demo-20');
UPDATE jobs SET status = 'ghosted'   WHERE source = 'demo' AND external_id = 'demo-8';
UPDATE jobs SET status = 'ignored'   WHERE source = 'demo' AND external_id IN ('demo-12','demo-18');
UPDATE jobs SET status = 'shortlisted' WHERE source = 'demo' AND external_id IN ('demo-13','demo-19');

INSERT INTO applications (job_id, applied_at, next_followup_at, followup_count)
SELECT id, collected_at + interval '1 day', collected_at + interval '8 days',
       CASE WHEN status = 'ghosted' THEN 2 WHEN status = 'applied' AND collected_at < now() - interval '7 days' THEN 1 ELSE 0 END
FROM jobs WHERE source = 'demo' AND status IN ('applied','interview','offer','rejected','ghosted')
ON CONFLICT (job_id) DO NOTHING;

-- Historique daté (le trigger enregistre les changements « maintenant » : on les étale dans le temps)
UPDATE status_history sh SET changed_at = a.applied_at + CASE WHEN sh.to_status = 'applied' THEN interval '0' ELSE interval '3 days' END
FROM applications a WHERE a.job_id = sh.job_id;
INSERT INTO status_history (job_id, from_status, to_status, changed_at)
SELECT j.id, 'new', 'applied', a.applied_at FROM jobs j JOIN applications a ON a.job_id = j.id
WHERE j.source = 'demo' AND j.status <> 'applied';

INSERT INTO documents (job_id, kind, content)
SELECT id, 'cover_letter', 'Lettre de démonstration' FROM jobs WHERE source = 'demo' AND status <> 'new' AND status <> 'ignored';
