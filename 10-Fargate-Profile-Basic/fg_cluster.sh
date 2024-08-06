#/bin/bash

eksctl create cluster --name=eksdemo1 \
                      --region=us-east-1 \
                      --zones=us-east-1a,us-east-1b \
                      --version="1.30" \
                      --without-nodegroup 

eksctl get cluster --region=us-east-1

eksctl utils associate-iam-oidc-provider \
    --region us-east-1 \
    --cluster eksdemo1 \
    --approve

# cd /Users/ndomi/Documents  # For Mac
cd /Users/ndomi/Documents
# pwd

eksctl create nodegroup --cluster=eksdemo1 \
                        --region=us-east-1 \
                        --name=eksdemo1-ng-private1 \
                        --node-type=t3.medium \
                        --nodes-min=2 \
                        --nodes-max=4 \
                        --node-volume-size=20 \
                        --ssh-access \
                        --ssh-public-key=mykey \
                        --managed \
                        --asg-access \
                        --external-dns-access \
                        --full-ecr-access \
                        --appmesh-access \
                        --alb-ingress-access \
                        --node-private-networking

eksctl get cluster --region=us-east-1
eksctl get nodegroup --cluster=eksdemo1 --region=us-east-1
eksctl get iamserviceaccount --cluster=eksdemo1 --region=us-east-1
kubectl get nodes

curl -o iam_policy_latest.json https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/main/docs/install/iam_policy.json

ls -lrta

# If the policy already exists, you can skip this step
policy_name="AWSLoadBalancerControllerIAMPolicy"
if [ -n $policy_name ]; then
    echo "$policy_name already exists"
else
    aws iam create-policy \
    --policy-name AWSLoadBalancerControllerIAMPolicy \
    --policy-document file://iam_policy_latest.json
fi

account_id=$(aws sts get-caller-identity --query Account --output text)
region=us-east-1

eksctl create iamserviceaccount \
  --cluster=eksdemo1 \
  --region=$region \
  --namespace=kube-system \
  --name=aws-load-balancer-controller \
  --attach-policy-arn=arn:aws:iam::$account_id:policy/AWSLoadBalancerControllerIAMPolicy \
  --override-existing-serviceaccounts \
  --approve

eksctl create iamserviceaccount \
  --name external-dns \
  --namespace default \
  --region us-east-1 \
  --cluster eksdemo1 \
  --attach-policy-arn arn:aws:iam::$account_id:policy/AllowExternalDNSUpdates \
  --approve \
  --override-existing-serviceaccounts

eksctl get iamserviceaccount --cluster=eksdemo1 --region=$region

kubectl get sa -n kube-system
kubectl get sa aws-load-balancer-controller -n kube-system
kubectl describe sa aws-load-balancer-controller -n kube-system

# Check if Helm is installed
if command -v helm &> /dev/null; then
  echo "Helm is already installed. Skipping installation step."
else
  echo "Helm is not installed. Installing Helm..."
  # Command to install Helm
  curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
fi

# Check if the EKS chart repository is already added
if helm repo list | grep -q 'https://aws.github.io/eks-charts'; then
  echo "EKS chart repository is already added. Skipping this step."
else
  echo "EKS chart repository is not added. Adding it now..."
  helm repo add eks https://aws.github.io/eks-charts
fi

helm repo update

# Get VPc ID
vpc_id=$(aws ec2 describe-vpcs --region us-east-1 --filters "Name=isDefault,Values=false" --query "Vpcs[0].VpcId" --output text)

helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=eksdemo1 \
  --set serviceAccount.create=false \
  --set serviceAccount.name=aws-load-balancer-controller \
  --set region=us-east-1 \
  --set vpcId=$vpc_id \
  --set image.repository=602401143452.dkr.ecr.us-east-1.amazonaws.com/amazon/aws-load-balancer-controller

kubectl -n kube-system get deployment 
kubectl -n kube-system get deployment aws-load-balancer-controller
kubectl -n kube-system describe deployment aws-load-balancer-controller

kubectl -n kube-system get svc 
kubectl -n kube-system get svc aws-load-balancer-webhook-service
kubectl -n kube-system describe svc aws-load-balancer-webhook-service

kubectl apply -f - <<EOF
apiVersion: networking.k8s.io/v1
kind: IngressClass
metadata:
  name: my-aws-ingress-class
  annotations:
    ingressclass.kubernetes.io/is-default-class: "true"
spec:
  controller: ingress.k8s.aws/alb
EOF

kubectl get ingressclass

############  Fargate Profile  ################
# Get Current Worker Nodes in Kubernetes cluster
kubectl get nodes -o wide

# Verify Ingress Controller Pod running
kubectl get pods -n kube-system

# Verify external-dns Pod running
kubectl get pods

# Get list of Fargate Profiles in a cluster
eksctl get fargateprofile --cluster eksdemo1

eksctl utils install-vpc-controllers --region=us-east-1 --cluster=eksdemo1

# kubectl create namespace fp-dev

# eksctl create fargateprofile --cluster eksdemo1 \
#                              --name fp-demo \
#                              --namespace fp-dev