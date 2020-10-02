# kubernetes-charts
Default charts for kubernetes resources used by Elvia

# development

After making changes to the charts, run
```
helm package elvia-deployment
helm package <name-of-chart>
helm repo index .
git commit
git push
```