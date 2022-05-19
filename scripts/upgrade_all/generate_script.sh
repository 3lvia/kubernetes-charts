helm list -A --max 9999 -o json > releases.json

# helm repo add elvia-charts https://raw.githubusercontent.com/3lvia/kubernetes-charts/feature/reduce-requests-in-dev
# helm repo update

cat releases.json | jq -r '.[]|select(.chart|startswith("elvia-deployment"))|[.namespace,.name]|@tsv'|awk '{print "helm upgrade -n",$1,"--reuse-values",$2,"elvia-charts/elvia-deployment"}' > helm_upgrade_all.sh
