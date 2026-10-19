// Génère les identifiants n8n à partir des variables d'environnement.
// Exécuté DANS le conteneur n8n par setup.sh : les secrets ne sont jamais écrits sur ta machine.
const e = process.env;

const credentials = [
  {
    id: 'jhPostgresCred01',
    name: 'Job Hunter · PostgreSQL',
    type: 'postgres',
    data: {
      host: e.JH_DB_HOST || 'postgres',
      port: Number(e.JH_DB_PORT || 5432),
      database: e.POSTGRES_DB,
      user: e.POSTGRES_USER,
      password: e.POSTGRES_PASSWORD,
      ssl: 'disable',
    },
  },
  {
    id: 'jhLlmApiCred0001',
    name: 'Job Hunter · API IA (LLM)',
    type: 'httpHeaderAuth',
    data: { name: 'Authorization', value: `Bearer ${e.LLM_API_KEY || ''}` },
  },
  {
    id: 'jhTelegramCred01',
    name: 'Job Hunter · Bot Telegram',
    type: 'telegramApi',
    data: { accessToken: e.TELEGRAM_BOT_TOKEN || '', baseUrl: e.TELEGRAM_API_URL || 'https://api.telegram.org' },
  },
  {
    id: 'jhFranceTravail1',
    name: 'Job Hunter · France Travail',
    type: 'oAuth2Api',
    data: {
      grantType: 'clientCredentials',
      accessTokenUrl: e.FT_TOKEN_URL || 'https://entreprise.francetravail.fr/connexion/oauth2/access_token?realm=%2Fpartenaire',
      clientId: e.FT_CLIENT_ID || '',
      clientSecret: e.FT_CLIENT_SECRET || '',
      scope: 'api_offresdemploiv2 o2dsoffre',
      authentication: 'body',
    },
  },
];

process.stdout.write(JSON.stringify(credentials, null, 2));
