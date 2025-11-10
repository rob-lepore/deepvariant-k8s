# Upload files to minikube
minikube cp pipeline/nextflow.config /data/shared/nextflow.config
minikube cp pipeline/main3.nf /data/shared/main3.nf
# minikube cp pipeline/data/hs37d5.fa /data/shared/hs37d5.fa
# minikube cp pipeline/data/hs37d5.fa.fai /data/shared/hs37d5.fa.fai

# minikube cp pipeline/data/sample1.cram /data/shared/sample1.cram
# minikube cp pipeline/data/sample1.cram.crai /data/shared/sample1.cram.crai

# minikube cp pipeline/data/sample2.cram /data/shared/sample2.cram
# minikube cp pipeline/data/sample2.cram.crai /data/shared/sample2.cram.crai

minikube cp pipeline/data/sample_cram.csv /data/shared/sample_cram.csv


# Run Nextflow
kubectl delete pod nextflow-hello
kubectl apply -f pod.yaml
# kubectl logs -f nextflow-hello