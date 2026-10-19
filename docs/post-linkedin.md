# Brouillon de post LinkedIn

> Conseil : poste avec la capture du dashboard + celle du bot (ou une courte vidéo de 30 s), et mets le lien GitHub en premier commentaire.

---

Chercher un emploi, c'est un job à plein temps. Alors j'ai construit un assistant IA qui le fait avec moi. 🎯

Je vous présente **Job Hunter IA**, 100 % construit avec n8n, PostgreSQL et l'IA 👇

🔎 Il collecte les offres toutes les 4 h (API France Travail + flux RSS)
🤖 Il compare chaque offre à mon CV et lui donne un score de 0 à 100, avec les points forts, les écarts et les compétences qui me manquent
🔔 Il ne m'alerte sur Telegram que pour les vraies pépites
✍️ En un clic : une lettre de motivation sur mesure, sans rien inventer
🎤 En un clic : une préparation d'entretien (pitch, questions probables, pièges)
⏰ Il me rappelle de relancer à J+7 et rédige l'email
📊 Chaque lundi : un rapport et 3 actions concrètes de la part d'un coach IA
📈 Et un dashboard pour suivre tout mon pipeline

Sous le capot :
⚙️ 8 workflows n8n, plus de 100 nœuds
🗄️ PostgreSQL : recherche plein texte, triggers, vues analytiques
🧠 Prompts structurés en JSON, validés avant d'être enregistrés
🛡️ Gestion des erreurs, retries, verrous pour éviter les doubles traitements
🐳 Installation en une commande avec Docker

Ce que j'ai le plus appris : l'IA n'est qu'une brique. La valeur vient de l'orchestration, de la fiabilité et de l'expérience utilisateur autour.

Le projet est open source 👉 lien en commentaire

Quelle fonctionnalité ajouteriez-vous ? 👇

#n8n #automatisation #IA #recherchedemploi #PostgreSQL #nocode #opensource
