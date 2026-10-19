#!/bin/sh
# Exécuté DANS le conteneur n8n : importe identifiants + workflows puis publie ceux qui doivent tourner.
set -e
TMP=$(mktemp -d)
node /scripts/build-credentials.js > "$TMP/credentials.json"
n8n import:credentials --input="$TMP/credentials.json"
rm -rf "$TMP"

n8n import:workflow --separate --input=/workflows

# Publie les 8 workflows (n8n exige aussi la publication du workflow d'erreurs et des sous-workflows)
for id in JH01Collecte0001 JH02AnalyseIA001 JH03BotTelegram1 JH04Lettre000001 JH05Relances0001 JH06RapportHebdo JH07Dashboard001 JH08Erreurs00001; do
  n8n publish:workflow --id="$id"
done
echo "✅ Workflows importés et publiés"
