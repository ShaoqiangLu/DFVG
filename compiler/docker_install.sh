echo "### Update apt-get"
sudo apt-get update
sudo apt-get install -y\
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg-agent \
    software-properties-common

echo "### Add Docker's official GPG key"
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

echo "### Verify fingerprint"
sudo apt-key fingerprint 0EBFCD88

echo "### Set up the stable repository for x86_64/amd64"
sudo add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"

echo "### Install Docker engine"
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io

echo "## Verify install"
sudo docker run hello-world
