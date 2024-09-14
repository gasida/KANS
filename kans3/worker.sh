#!/usr/bin/env bash

echo ">>>> k8s WorkerNode config Start <<<<"

echo "[TASK 1] K8S Controlplane Join - API Server 192.168.10.10" 
kubeadm join --token 123456.1234567890123456 --discovery-token-unsafe-skip-ca-verification 192.168.10.10:6443 >/dev/null 2>&1

echo ">>>> k8s WorkerNode Config End <<<<"