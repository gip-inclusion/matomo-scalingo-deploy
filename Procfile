web: bin/start-matomo.sh
postdeploy: bin/configure-environment.sh && php console core:clear-caches && php console core:update --yes
