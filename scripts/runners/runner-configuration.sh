#!/bin/bash

# List of packages to install
packages=(
    curl 
    wget 
    vim 
    git 
    jq 
    psql
    postgresql-client 
    mariadb-client 
    mysql-client-8.0
    mysql-client 
    unzip 
    tree 
)
# Update package
sudo apt update -y
sudo apt upgrade -y

# Install packages
for package in "${packages[@]}"; do
    echo "Installing $package Please wait ................."
    sleep 3
    sudo apt install -y "$package"
done
echo "Package installation completed."

## Install aws cli
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
rm -rf awscliv2.zip
rm -rf aws

## Install kubectl
curl -LO https://storage.googleapis.com/kubernetes-release/release/v1.7.0/bin/linux/amd64/kubectl
sudo chmod +x ./kubectl 
sudo mv kubectl /usr/local/bin/

## INSTALL KUBECTX AND KUBENS
sudo wget https://raw.githubusercontent.com/ahmetb/kubectx/master/kubectx 
sudo wget https://raw.githubusercontent.com/ahmetb/kubectx/master/kubens 
sudo chmod +x kubectx kubens 
sudo mv kubens kubectx /usr/local/bin

## Install Helm 3
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3
sudo  chmod 700 get_helm.sh
sudo ./get_helm.sh
sudo helm version

## Install Docker Coompose
# https://www.digitalocean.com/community/tutorials/how-to-install-and-use-docker-compose-on-ubuntu-20-04
sudo curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
docker-compose --version

## Install ArgoCD CLI
wget https://github.com/argoproj/argo-cd/releases/download/v2.8.5/argocd-linux-amd64
chmod +x argocd-linux-amd64
sudo mv argocd-linux-amd64 /usr/local/bin/argocd

## Install Docker
    # https://docs.docker.com/engine/install/ubuntu/
sudo apt-get remove docker docker-engine docker.io containerd runc -y
sudo apt-get update
sudo apt-get install \
    ca-certificates \
    curl \
    gnupg \
    lsb-release
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo \
"deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
$(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo chmod a+r /etc/apt/keyrings/docker.gpg
sudo apt-get update
sudo apt install docker-ce docker-ce-cli containerd.io -y
sudo systemctl start docker
sudo systemctl enable docker
## chmod the Docker socket. the Docker daemon does not have the necessary permissions to access the Docker socket file located at /var/run/docker.sock
sudo chown root:docker /var/run/docker.sock
sudo chmod 666 /var/run/docker.sock

# Install sonar-scanner CLI
# https://github.com/SonarSource/sonar-scanner-cli/releases
sonar_scanner_version="5.0.1.3006"                 
wget -q https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-${sonar_scanner_version}-linux.zip
unzip sonar-scanner-cli-${sonar_scanner_version}-linux.zip
sudo mv sonar-scanner-${sonar_scanner_version}-linux sonar-scanner
sudo rm -rf  /var/opt/sonar-scanner || true
sudo mv sonar-scanner /var/opt/
sudo rm -rf /usr/local/bin/sonar-scanner || true
sudo ln -s /var/opt/sonar-scanner/bin/sonar-scanner /usr/local/bin/ || true
sonar-scanner -v

## Set vim as default text editor
sudo update-alternatives --set editor /usr/bin/vim.basic
sudo update-alternatives --set vi /usr/bin/vim.basic

# Install k9s
curl -sS https://webinstall.dev/k9s | bash
cp -a ~/.local/bin/k9s /usr/local/bin/
k9s version

# vault
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
sudo apt-get update && sudo apt-get install vault


## Create Users and add them in the sudoers file and allow docker access
cat << EOF > /usr/users.txt
jenkins
ansible 
runner
EOF

username=$(cat /usr/users.txt | tr '[A-Z]' '[a-z]')
for users in $username
do
    ls /home |grep -w $users &>/dev/nul || mkdir -p /home/$users
    cat /etc/passwd |awk -F: '{print$1}' |grep -w $users &>/dev/nul ||  useradd $users
    chown -R $users:$users /home/$users
    usermod -s /bin/bash -aG docker $users
    echo -e "$users\n$users" |passwd "$users"
done

for i in $username
do 
    if grep -q "^$i" /etc/sudoers; then
        echo "User '$i' is already in sudoers."
    else
        echo "$i ALL=(ALL) NOPASSWD: /usr/bin/docker" | sudo tee -a /etc/sudoers
    fi
done