# Kubernetes installation
## Requirements
### Docker

Install helper tools for docker. Most of this is taken from the official docker installation guide.
```bash   
sudo apt-get install \
   apt-transport-https \
   ca-certificates \
   curl \
   gnupg2 \
   software-properties-common
```

Add the keys. Maybe this way isn't as secure as it should be.	 
``` bash
curl -fsSL https://download.docker.com/linux/debian/gpg | sudo apt-key add -
```

fingerprint and add the repo
```bash
sudo apt-key fingerprint 0EBFCD88

sudo add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/debian \
   $(lsb_release -cs) \
   stable"
```

Update with the new repo and then install the required docker version. Required version depends on the system you are installing onto and the desired kubernetes version.
The madison command lists versions of the given package.
```bash
sudo apt-get update

apt-cache madison docker-ce
sudo apt-get install docker-ce=<docker_version_string>
```
`example: sudo apt-get install docker-ce=18.06.3~ce~3-0~debian`
	
	
### Creating the user (optional)
If you wish to have a special user on the mashine you can create it with the following way.

`Note: this will create a user which may use sudo without a password!`

```bash
sudo adduser --gecos "" {username}
# or, to set the password to kubuser
yes jenkins | sudo adduser --gecos "" {username}

# Add user to sudoers file. This way the new user may use sudo without entering a password. tee -a will only allow a correct string to be added so that sudo can parse the file correctly
echo '{username} ALL=(ALL) ALL' | sudo EDITOR='tee -a' visudo -f /etc/sudoers.d/{username}

# Check if sudo works:
sudo su {username}
sudo -l
cd ~
```

### Disable swap
Kubernetes only runs if swap is disabled. To disable it use the following commands. For permanent disabling the swap use both commands, then no restart is needed.

```bash
# to disable it temporarily on the running mashine
sudo swapoff -a 

# To disable it permanently use
sudo vi /etc/fstab
# comment any line which contains "swap" out with "#"
```

### Installing kubernetes and helper tools
To install kubernetes you need kubeadm, kubectl and kubelet.
Remember to install all of them with the same version on each node.
Installation depends on your system. Example for apt-get:

```bash
sudo apt-get install kubectl=<versionString> kubelet=<versionString> kubeadm=<versionString>
# Mark them as hold. This will prevent them from being updated when calling apt-get update/upgrade.
sudo apt-mark hold kubectl kubelet kubeadm
```

## Handling kubernetes

## Setup the kubernetes master node
Take from the official installation notes.

```bash
# init the kubernetes. Pod-network-cidr parameter given from the used network provider. We use flannel
sudo kubeadm init --pod-network-cidr=10.244.0.0/16

# Used by kubectl config should be shared with everyone who needs a working kubectl. Allows FULL access to the cluster.
rm -r $HOME/.kube
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# Setup some network stuff and install flannel
sudo sysctl net.bridge.bridge-nf-call-iptables=1
kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/62e44c867a2846fefb68bd5f178daf4da3095ccb/Documentation/kube-flannel.yml
```

### Create join token
The following commands can create all values needed to join an node with installed kubernetes to an master node. *Run the commands on the master node.*

```bash
# To create new join tokens 
sudo kubeadm token create
# To list current tokens
sudo kubeadm token list
# Get key hash
openssl x509 -pubkey -in /etc/kubernetes/pki/ca.crt | openssl rsa -pubin -outform der 2>/dev/null | \
   openssl dgst -sha256 -hex | sed 's/^.* //'
```
With the data from above use this on a vm/node to join to the master:
```bash
kubeadm join --token <token> <master-ip>:<master-port> --discovery-token-ca-cert-hash sha256:<hash>
```

`example:kubeadm join --token 57r4fz.f4gb7sxf3iw08vpa 131.234.28.187:6443 --discovery-token-ca-cert-hash sha256:ffc3414a8581c19306794b2953d8246daafcf2af40e03524166be09ad64853c7`

To print the final command you can use the following on the master node.
The command printed into the shell then can be used on the master node.
``` bash
echo "kubeadm join --token $(sudo kubeadm token create) {masterIP}:{masterPort} --discovery-token-ca-cert-hash sha256:$(openssl x509 -pubkey -in /etc/kubernetes/pki/ca.crt | openssl rsa -pubin -outform der 2>/dev/null | openssl dgst -sha256 -hex | sed 's/^.* //')"
```

## Using helm

### Installing helm

As the user that wants to install helm use the following.

`Note: kubectl must be set up correctly for the user. Helm must be installed on the kubernetes already. For the first installation skip the "--client-only" part.`

```bash
cd ~
curl -LO https://git.io/get_helm.sh
# Approve scrip!
nano get_helm.sh

# If script looks fine:
chmod 700 get_helm.sh
./get_helm.sh
rm get_helm.sh

helm init --client-only
```

### Install our helm charts
To install our state to the kubernetes use the following. The user that runs the commands must have a working helm installation.

```bash
cd ~
git clone https://git.cs.upb.de/SFB901-Testbed/helm-charts.git
cd helm-charts/
./install_dependencies
```
No you have to fill out all the password value files. Either by using the helper script or by doing it manually. 

To do so: copy the examples and rename them (so that they don't contain the .example at the end). Then replace every "{{password}}" text by the correct password.

After filling out all passwords (keep in mind to use the same passwords as used before if the services are already running or have encrypted data stored on the disk) you can install them. To do so go into the folders of the services you wish to install and run `./install.sh`
If you wish to use a different namespace either change it inside the install.sh script or use the global_install.sh script with the correct command line parameters.

## Helpers

### Jenkins
Jenkins helm files are located at `ci/jenkins/`
To get the admin password of an already deployed instance use the following:

```bash
kubectl get secret jenkins -n jenkins -o yaml | grep "admin-password" | awk '{print $2}' |base64 --de
code | awk 1
```
Depending on your jenkins installation the admin account may have a password but can't log in.

## Setup the dashboard
Run the following with a working kubectl installation. Probably the version must be updated somewhen.
```bash
kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v1.10.1/src/deploy/recommended/kubernetes-dashboard.yaml
```


## Troubleshooting

### CNI-Error
Their may be some kind of a cni error in case of reinstallation. The following commands should fix this

```bash
kubeadm reset
systemctl stop kubelet
systemctl stop docker
rm -rf /var/lib/cni/
umount $(grep /var/lib/kubelet /proc/mounts | cut -f2 -d" " | sort -r)
rm -rf /var/lib/kubelet/*
rm -rf /etc/cni/
ifconfig cni0 down
ifconfig flannel.1 down
ifconfig docker0 down

systemctl start docker
```
