t -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

check_command() {
	    if command -v $1 &> /dev/null; then
		            echo -e "${GREEN}✓${NC} $1 is already installed"
			            return 0
				        else
						        echo -e "${YELLOW}⚠${NC} $1 is not installed"
							        return 1
								    fi
							    }

						    echo "🚀 Checking and installing DevOps tools..."

						    if ! check_command docker; then
							        echo "📦 Installing Docker..."
								    sudo apt update
								        sudo apt install -y docker.io
									    sudo systemctl start docker
									        sudo systemctl enable docker
										    sudo usermod -aG docker $USER
						    fi

						    if ! check_command kubectl; then
							        echo "☸️  Installing kubectl..."
								    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
								        chmod +x kubectl
									    sudo mv kubectl /usr/local/bin/
						    fi

						    if ! check_command kind; then
							        echo "🎯 Installing Kind..."
								    curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.20.0/kind-linux-amd64
								        chmod +x kind
									    sudo mv kind /usr/local/bin/
						    fi

						    if ! check_command helm; then
							        echo "⎈  Installing Helm..."
								    curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
						    fi

						    if ! check_command terraform; then
							        echo "🏗️  Installing Terraform..."
								    TERRAFORM_VERSION="1.6.6"
								        wget https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip
									    sudo apt install -y unzip
									        unzip terraform_${TERRAFORM_VERSION}_linux_amd64.zip
										    sudo mv terraform /usr/local/bin/
										        rm terraform_${TERRAFORM_VERSION}_linux_amd64.zip
						    fi

						    echo ""
						    echo "✅ All tools installed!"
					    docker --version
					    kubectl version --client
					    kind version
					    helm version
					    terraform version
