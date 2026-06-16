CREATE TABLE IF NOT EXISTS articles (
  id SERIAL PRIMARY KEY,
  hash TEXT UNIQUE,
  titre TEXT,
  lien TEXT,
  date TEXT,
  categories TEXT,
  auteur TEXT,
  resume TEXT,
  criticite INT,
  niveau TEXT,
  attaquants TEXT,
  victimes TEXT,
  techniques TEXT,
  outils_utilises TEXT,
  impact TEXT,
  recommandation TEXT,
  created_at TIMESTAMP DEFAULT NOW()
);
