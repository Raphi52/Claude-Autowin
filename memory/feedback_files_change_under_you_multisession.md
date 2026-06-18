---
name: feedback_files_change_under_you_multisession
description: "Repo multi-sessions — un fichier lu peut changer/grossir sous toi (writer concurrent) ; grep le dossier cible TOI-MÊME avant de créer, ne crois pas le « zéro match » d'un Explore"
metadata:
  type: feedback
---

Sur un repo où **plusieurs sessions tournent en parallèle**, un fichier que tu as lu peut **changer/grossir
sous toi** entre deux outils, et un Explore peut rapporter « zéro match » alors qu'une autre session a DÉJÀ
construit le code → tu crées des doublons → collisions de compilation + schéma parallèle incompatible.

**Pourquoi** : anti-pattern « relayer un rapport sans vérifier l'artefact réel » + « vérifier ce qui EXISTE
avant de créer » (le doublon). Un Explore peut être STALE/faux ; un repo multi-sessions n'est pas un
instantané figé.

**How to apply** : AVANT de créer un fichier/type pour un work-item qu'une session antérieure OU concurrente
a pu toucher → **grep TOI-MÊME le dossier cible** (noms/types exacts), ne te fie pas au « 0 match » d'un
sous-agent ; **re-lis juste avant d'écrire** (l'état d'il y a 5 min peut être périmé). Si des fichiers
changent sous toi → writer concurrent : STOP, ne combats pas, supprime tes doublons, surface à l'user. Le fix
structurel du chevauchement = [[project_stopgate_session_scoping]].
