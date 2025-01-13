# helm unit tests

Uses https://github.com/helm-unittest/helm-unittest to do simple unit tests of the helm chart. 

# Run locally
```sh
helm plugin install https://github.com/helm-unittest/helm-unittest.git
helm unittest elvia-deployment
```

# Development
Current tests are snapshot tests. They validate the rendered yaml with snapshots located under the __snapshot__ folder. It fails if the content changed. If the content is meant to change, update the snapshots with `helm unittest -u elvia-deployment`. 

You can also create regular unit tests, see https://github.com/helm-unittest/helm-unittest for details. 
