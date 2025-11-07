# Upload files to minikube
minikube cp pipeline/nextflow.config /data/shared/nextflow.config
minikube cp pipeline/main.nf /data/shared/main.nf
# minikube cp pipeline/data/a.txt /data/shared/data/a.txt
# minikube cp pipeline/data/b.txt /data/shared/data/b.txt
# minikube cp pipeline/data/c.txt /data/shared/data/c.txt


# Run Nextflow
kubectl delete pod nextflow-hello
kubectl apply -f pod.yaml
# kubectl logs -f nextflow-hello