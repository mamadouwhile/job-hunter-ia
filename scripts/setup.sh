#!/usr/bin/env bash
# =====================================================================
#  Job Hunter IA · installation en une commande
#  Usage : ./scripts/setup.sh
#  Relançable sans risque : met à jour identifiants et workflows.
# =====================================================================
set -euo pipefail
cd "$(dirname "$0")/.."

green() { printf '\033[32m%s\033[0m\n' "$*"; }
yellow() { printf '\033[33m%s\033[0m\n' "$*"; }

[ -f .env ] || { cp .env.example .env; yellow "📄 Fichier .env créé à partir de .env.example"; }

# Génère les secrets manquants
gen() { openssl rand -hex "${1:-24}" 2>/dev/null || head -c 64 /dev/urandom | od -An -tx1 | tr -d ' \n' | head -c 48; }
set_if_empty() {
  local key=$1 value=$2
  if grep -qE "^${key}=$" .env; then
    sed -i.bak "s|^${key}=$|${key}=${value}|" .env && rm -f .env.bak
    green "🔐 ${key} généré"
  fi
}
set_if_empty POSTGRES_PASSWORD "$(gen 16)"
set_if_empty N8N_ENCRYPTION_KEY "$(gen 32)"
set_if_empty DASHBOARD_TOKEN "$(gen 16)"

# Vérifie la configuration obligatoire
missing=()
for key in LLM_API_KEY TELEGRAM_BOT_TOKEN; do
  grep -qE "^${key}=.+" .env || missing+=("$key")
done
if [ ${#missing[@]} -gt 0 ]; then
  yellow "⚠️  À compléter dans .env : ${missing[*]} (puis relance ce script)"
  exit 1
fi
grep -qE "^FT_CLIENT_ID=.+" .env || yellow "ℹ️  FT_CLIENT_ID vide : seule la collecte RSS fonctionnera (France Travail désactivé)."
grep -qE "^TELEGRAM_CHAT_ID=.+" .env || yellow "ℹ️  TELEGRAM_CHAT_ID vide : écris à ton bot, il te donnera ton identifiant."

green "🐘 Démarrage de PostgreSQL…"
docker compose up -d --wait postgres

green "📦 Import des identifiants et des workflows dans n8n…"
docker compose stop n8n >/dev/null 2>&1 || true
docker compose run --rm --no-deps --entrypoint sh n8n /scripts/install-workflows.sh

green "🚀 Démarrage de n8n…"
if grep -qE "^NGROK_AUTHTOKEN=.+" .env; then
  docker compose --profile tunnel up -d
else
  docker compose up -d
fi

source .env
echo
green "✅ Job Hunter IA est prêt !"
echo "   • n8n        : http://localhost:5678"
echo "   • Dashboard  : http://localhost:5678/webhook/jobhunter?token=${DASHBOARD_TOKEN}"
echo "   • Telegram   : écris /start à ton bot"
case "${N8N_WEBHOOK_URL:-}" in
  https://*) ;;
  *) yellow "   ⚠️  N8N_WEBHOOK_URL n'est pas en HTTPS : Telegram ne pourra pas joindre le bot (voir README › Tunnel HTTPS).";;
esac
