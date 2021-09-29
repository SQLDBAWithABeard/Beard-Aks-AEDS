kubectl delete -f .\Scripts\localk8s-indirect\powershellfailedlogin.yaml
kubectl delete -f .\Scripts\localk8s-indirect\powershellrunascript.yaml

kubectl apply -f .\Scripts\localk8s-indirect\powershellfailedlogin.yaml
kubectl apply -f .\Scripts\localk8s-indirect\powershellrunascript.yaml



