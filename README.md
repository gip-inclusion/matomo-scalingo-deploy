# Matomo-scalingo-deploy

Fork du [buildpack betagouv](https://github.com/betagouv/matomo-buildpack).

## Premier lancement

- creer une app scalingo
- la lier à ce repo
- remplir les variables Scalingo :
  - obligatoires au premier deploy : `MATOMO_INIT_USER_*`, `MATOMO_INIT_SITE_*`, `SMTP_HOST`, `SMTP_USER`, `SMTP_PASS`, `MATOMO_VERSION`
  - plugins premium : `MATOMO_LICENSE_KEY`
  - recommandées : `MATOMO_SALT`, `MATOMO_MEMORY_LIMIT` (ex. `512M`), `PHP_VERSION` (ex. `~8.4`)
- déployer

Note : Au tout premier déploiement, Scalingo lance `bin/first-deploy-init.sh` (déclaré dans `scalingo.json`).
Cela déclanche la création des tables, du superutilisateur et du site initial.

## Configuration

Seuls certains secrets et la version de MAtomo sont configurés dans Scalingo.
Le reste est versionné en dur ici car peu de mises à jour.

- version Matomo : `scalingo.json`, variable `MATOMO_VERSION` obligatoire
- versions des plugins : tableaux en tête de `bin/fetch-purchased-plugins.sh`
- réglages & plugins actifs : `scripts/config.ini.php.tmpl`

La mise à jour auto depuis l'admin Matomo et l'installation de plugins depuis l'UI sont désactivées dans la config.

## OIDC

Avant de déployer :

- vérifier le slug d'application "matomo" dans Authentik (cf. `endSessionUrl`)
- ajouter `REBELOIDC_CLIENT_ID` et `REBELOIDC_CLIENT_SECRET` sur Scalingo
- enregistrer l'URL de callback côté Authentik :

```
https://<url-de-matomo>/index.php?module=RebelOIDC&action=callback&provider=oidc
```

- mettre `.*` dans les Redirect URIs du provider dans Authentik (le point devant est important, voir la [FAQ du plugin](https://plugins.matomo.org/RebelOIDC))

## Mise à jour

1. Modifier les versions dans le repo (`scalingo.json`, `fetch-purchased-plugins.sh`, tmpl si besoin), committer.
2. Couper le tracking le temps de la migration : `MATOMO_MAINTENANCE=true`, et monter la mémoire si besoin (`MATOMO_MEMORY_LIMIT=512`).
3. Pousser sur `main`: Scalingo déploie, le postdeploy lance `configure-environment.sh` et `core:update --yes`.
4. En one-off, relancer `bin/configure-environment.sh` puis `php console core:update --yes -vvv` pour vérifier.
5. Remettre `MATOMO_MAINTENANCE=false`.

## Licence

AGPL-3.0
