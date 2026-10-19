-- =====================================================================
--  Job Hunter IA · schéma PostgreSQL
--  Exécuté automatiquement au premier démarrage du conteneur Postgres.
-- =====================================================================

-- ---------------------------------------------------------------------
-- Profil du candidat (une seule ligne, id = 1)
-- ---------------------------------------------------------------------
CREATE TABLE profile (
  id                 int PRIMARY KEY DEFAULT 1 CHECK (id = 1),
  full_name          text,
  headline           text,
  cv_text            text,
  target_roles       text[] NOT NULL DEFAULT '{}',
  skills             text[] NOT NULL DEFAULT '{}',
  locations          text[] NOT NULL DEFAULT '{}',
  contract_types     text[] NOT NULL DEFAULT '{}',
  languages          text[] NOT NULL DEFAULT '{}',
  remote_preference  text NOT NULL DEFAULT 'indifférent',
  salary_min         int,
  years_experience   int,
  preferences        text,
  alert_threshold    int NOT NULL DEFAULT 75 CHECK (alert_threshold BETWEEN 0 AND 100),
  updated_at         timestamptz NOT NULL DEFAULT now()
);

-- ---------------------------------------------------------------------
-- Sources : recherches France Travail + flux RSS d'offres
-- ---------------------------------------------------------------------
CREATE TABLE searches (
  id             serial PRIMARY KEY,
  label          text NOT NULL,
  keywords       text NOT NULL,
  department     text,            -- ex. 75, 69, 33 (vide = toute la France)
  contract_type  text,            -- CDI, CDD, MIS, SAI, LIB... (vide = tous)
  active         boolean NOT NULL DEFAULT true,
  last_run_at    timestamptz,
  last_count     int,
  created_at     timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE feeds (
  id               serial PRIMARY KEY,
  name             text NOT NULL,
  url              text NOT NULL UNIQUE,
  active           boolean NOT NULL DEFAULT true,
  last_fetched_at  timestamptz,
  last_count       int,
  error_count      int NOT NULL DEFAULT 0,
  last_error       text,
  created_at       timestamptz NOT NULL DEFAULT now()
);

-- ---------------------------------------------------------------------
-- Offres d'emploi + analyse IA
-- ---------------------------------------------------------------------
CREATE TABLE jobs (
  id                  serial PRIMARY KEY,
  source              text NOT NULL,           -- france_travail | rss | manuel
  external_id         text NOT NULL,
  url                 text,
  title               text NOT NULL,
  company             text,
  location            text,
  contract_type       text,
  salary              text,
  description         text,
  published_at        timestamptz,
  collected_at        timestamptz NOT NULL DEFAULT now(),
  search_id           int REFERENCES searches(id) ON DELETE SET NULL,
  feed_id             int REFERENCES feeds(id) ON DELETE SET NULL,

  -- Analyse IA
  score               int CHECK (score BETWEEN 0 AND 100),
  verdict             text,
  summary             text,
  strengths           text[] NOT NULL DEFAULT '{}',
  gaps                text[] NOT NULL DEFAULT '{}',
  missing_skills      text[] NOT NULL DEFAULT '{}',
  key_skills          text[] NOT NULL DEFAULT '{}',
  red_flags           text[] NOT NULL DEFAULT '{}',
  seniority           text,
  remote              text,
  estimated_salary    text,
  scored_at           timestamptz,
  scoring_started_at  timestamptz,
  score_attempts      int NOT NULL DEFAULT 0,
  score_error         text,

  -- Suivi
  status              text NOT NULL DEFAULT 'new'
                      CHECK (status IN ('new','shortlisted','applied','interview','offer','rejected','ignored','ghosted')),
  alerted_at          timestamptz,
  status_changed_at   timestamptz NOT NULL DEFAULT now(),

  search_vector       tsvector GENERATED ALWAYS AS (
    setweight(to_tsvector('french', coalesce(title, '')), 'A') ||
    setweight(to_tsvector('french', coalesce(company, '')), 'B') ||
    setweight(to_tsvector('french', coalesce(description, '')), 'C')
  ) STORED,

  UNIQUE (source, external_id)
);

CREATE INDEX jobs_to_score_idx ON jobs (collected_at DESC) WHERE scored_at IS NULL;
CREATE INDEX jobs_status_idx   ON jobs (status, score DESC);
CREATE INDEX jobs_search_idx   ON jobs USING gin (search_vector);

-- ---------------------------------------------------------------------
-- Candidatures, documents générés, historique
-- ---------------------------------------------------------------------
CREATE TABLE applications (
  id                serial PRIMARY KEY,
  job_id            int NOT NULL UNIQUE REFERENCES jobs(id) ON DELETE CASCADE,
  applied_at        timestamptz NOT NULL DEFAULT now(),
  next_followup_at  timestamptz,
  followup_count    int NOT NULL DEFAULT 0,
  last_followup_at  timestamptz,
  notes             text
);

CREATE TABLE documents (
  id          serial PRIMARY KEY,
  job_id      int REFERENCES jobs(id) ON DELETE CASCADE,
  kind        text NOT NULL CHECK (kind IN ('cover_letter','followup','interview_prep','weekly_report')),
  content     text NOT NULL,
  created_at  timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE status_history (
  id           serial PRIMARY KEY,
  job_id       int NOT NULL REFERENCES jobs(id) ON DELETE CASCADE,
  from_status  text,
  to_status    text NOT NULL,
  changed_at   timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE workflow_errors (
  id             serial PRIMARY KEY,
  workflow_name  text,
  node_name      text,
  message        text,
  execution_url  text,
  created_at     timestamptz NOT NULL DEFAULT now()
);

-- Historise chaque changement de statut (sert au funnel et au rapport hebdo)
CREATE FUNCTION log_status_change() RETURNS trigger AS $$
BEGIN
  IF NEW.status IS DISTINCT FROM OLD.status THEN
    NEW.status_changed_at := now();
    INSERT INTO status_history (job_id, from_status, to_status) VALUES (NEW.id, OLD.status, NEW.status);
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER jobs_status_change
  BEFORE UPDATE OF status ON jobs
  FOR EACH ROW EXECUTE FUNCTION log_status_change();

-- ---------------------------------------------------------------------
-- Vues d'analyse
-- ---------------------------------------------------------------------
CREATE VIEW v_pipeline AS
SELECT status, count(*)::int AS total, round(avg(score))::int AS avg_score
FROM jobs GROUP BY status;

-- Compétences les plus demandées dans les offres pertinentes que tu n'as pas encore
CREATE VIEW v_missing_skills AS
SELECT lower(skill) AS skill, count(*)::int AS occurrences
FROM jobs, unnest(missing_skills) AS skill
WHERE score >= 50 AND collected_at > now() - interval '30 days'
GROUP BY lower(skill)
ORDER BY occurrences DESC;
