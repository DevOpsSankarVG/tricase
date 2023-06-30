<h1 >Introduction</h1>

This document is to provide the technical details about the set-up and configuration of the Kubernetes cluster, there will be an application will run in the cluster and the traffic to the application route with 70 30 % weight by using an ingress load balancer and an ingress controller, for logging and monitoring setup will be done with Prometheus and graffana.

The incoming traffic distribution will be routed with different load balancing algorithms which include destination hashing ,round-robin for the Kubernetes , the traffic percentage weight to 70 and 30 will be established with ingress controller solutions like istio, metallb or nginx. The installation details and the code are provided in the GIT repository which will be attached to the submission portal.  
<h3>-Pre-Requisite </h3>
<h4>The infrastructure will be hosting in  AWS Cloud</h4>

- 3, X86 architecture server(T2.medium server).

- Minimum 2 CPU and 4 GB RAM for each server.
  
- Centos 7.9 AMI image.
  
- Traffic exposed to internet.
- Install wget git mlocate in the server
  
<h2>Additional Information-:</h2>
Kubernetes is a container orchestration platform which is used to automate deployment, scaling, and management of containerized application.  The key features of Kubernetes which includes container orchestration, auto scaling , service discovery and load balancing , self-healing , rolling updates and rollbacks , storage orchestration configuration management etc.

-We can set up the Kubernetes cluster in different ways The Kubernetes cluster is installed with kubeadm using the yum repository .we will start with installation the OS in the server ,install the centos image in the server ,Centos OS is an open source OS and for X86 /64 architecture  docker engine repository  is supported , for running and communicating with the application services necessary network setting need to be conducted ,  open the ports (in the master TCP node port 6443, 2379 ,2380, 10250 ,10251 10252, 10255 and in worker node TCP port 6783, 10250 ,10255 ,30000 to 32767 need to opened ) . The architecture of this Kubernetes cluster consists of one master nodes and two worker nodes. 

We will assume that the server provisioning is completed, and user is able to access the server. 

Automation is done for the provisioning of the infrastructure, and the code is provided in the git repository , the name of the file is  main.tf , variable and the secrets are not added in the file .

<h2>Kubernetes setup in master and worker node -:</h2>

<h3>Check the swap is disabled and commented in fstab</h3>
-swapoff -a

- Uninstall the docker, older versions of Docker went by the names of docker or docker-engine. Uninstall any such older versions before attempting to install a new version, along with associated dependencies.

-Yum remove docker*

<h3>docker-ce repository set up for centos</h3> 

-yum install -y yum-utils

-yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo

<h3>We are using containerd as the CRI</h3>

-yum install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

-systemctl start docker

-systemctl enable docker

-systemctl start containerd

-systemctl enable containerd

<h3>Comment the option  “disabled plugins “ CRI in the containerd configuration file so that the CRI  pluging is enabled , if its in disabled state there will be error reports while initializing the pods</h3>
-vi  /etc/containerd/config.toml
-#disabled_plugins = ["cri"]

<h3> to mitigate the error execution phase prefight  .while building the master server with kubeadm update the kernel values </h3> 
-cat << EOF | sudo tee /etc/sysctl.d/k8c.conf
-net.bridge.bridge-nf-call-iptables = 1
-net.ipv4.ip_forward                = 1
-net.bridge.bridge-nf-call-ip6tables = 1
-EOF

-cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
-overlay
-br_netfilter
-EOF
<h3>to make the update in the kernel</h3> 
-sysctl --system

<h3>configure the yum repository to install the kubelet kubeadm kubectl</h3>
-cat <<EOF | sudo tee /etc/yum.repos.d/kubernetes.repo
-[kubernetes]
-name=Kubernetes
-baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-\$basearch
-enabled=1
-gpgcheck=1
-gpgkey=https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
-exclude=kubelet kubeadm kubectl
-EOF

<h3>Disbale the SELinux </h3>

If the Selinux ix in enabled state there will be network issues while deploying the Kubernetes. To mitigate these issue we need to disable the Selinux all nodes .Once the configuration file updated with below command need to reboot the nodes so that the selinux settings will apply to the nodes
 
-sudo sed -i 's/^SELINUX=enforcing$/SELINUX=disabled/' /etc/selinux/config

<h3>By using yum install the kubelet ,kubeadm and  kubectl packages ,and enable the kubelet ay adding the service </h3>
-sudo yum install -y kubelet kubeadm kubectl --disableexcludes=kubernetes
-systemctl enable kubelet

<h3>initialize the master node control plane  by running the “kubeadm init “ command followed by the required options, below is the command,</h3>

-kubeadm init --apiserver-advertise-address=(Private IP of master node) --pod-network-cidr=192.168.0.0/16 --cri-socket unix:///var/run/cri-dockerd.sock

copy the last lines of the output to start using the cluster ,  We can run the command as regular user or as a root user output .Once the cluster is started deploy a pod network to the cluster, here we are using calico as network addons Then you can join any number of worker nodes by running the “kube join “command followed with options. 

-Your Kubernetes control-plane has initialized successfully!
-To start using your cluster, you need to run the following as a regular user: 
 - mkdir -p $HOME/.kube
 - sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
 - sudo chown $(id -u):$(id -g) $HOME/.kube/config
<h3>Alternatively, if you are the root user, you can run:</h3>
 - export KUBECONFIG=/etc/kubernetes/admin.conf

<h3>You should now deploy a pod network to the cluster.</h3>
-Run "kubectl apply -f [podnetwork].yaml" with one of the options listed at:
-  https://kubernetes.io/docs/concepts/cluster-administration/addons/

<h>3Then you can join any number of worker nodes by running the following on each as root:</h3>

-kubeadm join 172.xxx.xxx:6443 --token 9jhr8c.mjr94aqpmxjcv4pv \
        --discovery-token-ca-cert-hash sha256:f5782e15572367d5b0693ad1ab0f13c9b36f2f8027494b0d2052f273363d

#Installing the pod network to the cluster by using “calico”, this add is suitable for the interconnecting with the pods and if we are planning for the cluster with less than 50 nodes below are the steps to setup the calico.
-curl https://raw.githubusercontent.com/projectcalico/calico/v3.26.0/manifests/calico.yaml -O
-kubectl apply -f calico.yaml 

- check the master and the worker node and pod  status 
-Kubectl get pods -A
-Kubectl get nodes

- The two containers are deployed with a deployment file and the replica was provided as two pods and the label is provided as nginx .as per the requirement the image used to deploy the container is nginx:1.24.0. The code is provided in the GIT HUB.  have used the load balancer to distribute the traffic node port, a service is initiated with the type Loadbalancer to map the container port and the node port.
the files are -:
deploy-nginx.yaml
kubectl apply -f deploy-nginx.yaml
Kubectl apply -f loadbalancer.yaml

#now expose the port of the container to the node port by executing below command 
kubectl expose deployment nginx --name=nginxsvc --target-port=80 --type=NodePort --port=80

#The container index.html will have separate content, once the container are deployed in the worker node we will be changing the content of the index.html of each file, this will be done by copying the index.html file from the master node to the respective container by executing the command 
#kubectl cp <localNode/file> podName:destinationDir -c <Containername>
kubectl cp index.html nginx-77b4fdf86c-p2l98:/usr/share/nginx/html/ -c nginx

[root@KubeMaster tmp]# curl http://3.9.191.238:32221/
<!DOCTYPE html>
<html>
<head>
<title>Container 1</title>
</head>
<body>

<h1>I'm version 1!</h1>


</body>
</html>
[root@KubeMaster tmp]#



The application is accessible in the link http://3.9.191.238:32221/ , further I need to work out to the traffic distribute the traffic by using the istio.


