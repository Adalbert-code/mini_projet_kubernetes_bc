#!/bin/bash

#############################################
# Script d'installation Kubernetes/Minikube
# Version: 3.0 FINALE (Ubuntu + Containerd)
# Date: Janvier 2026
#
# Testé et fonctionnel avec:
# - Ubuntu 22.04 LTS
# - Containerd 2.2.1
# - Kubernetes 1.31.0
# - crictl 1.32.0
#
# Changements majeurs:
# - Utilisation de containerd au lieu de Docker+cri-dockerd
# - crictl v1.32.0 (compatible containerd 2.2.1)
# - Configuration systemd cgroups
# - Gestion automatique des permissions
#############################################

set -euo pipefail
IFS=$'\n\t'

#############################################
# CONFIGURATION
#############################################

readonly MINIKUBE_VERSION="${MINIKUBE_VERSION:-v1.34.0}"
readonly CRICTL_VERSION="${CRICTL_VERSION:-v1.32.0}"
readonly CNI_VERSION="${CNI_VERSION:-v1.5.1}"
readonly KUBERNETES_VERSION="${KUBERNETES_VERSION:-1.31.0}"
readonly ENABLE_ZSH="${ENABLE_ZSH:-false}"

readonly LOG_FILE="/var/log/k8s-install.log"
readonly TEMP_DIR="/tmp/k8s-install-$$"
readonly LOCK_FILE="/var/lock/k8s-install.lock"

# Couleurs
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m'

#############################################
# FONCTIONS UTILITAIRES
#############################################

log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $*" | tee -a "$LOG_FILE"
}

log_error() {
    echo -e "${RED}[ERREUR]${NC} $*" | tee -a "$LOG_FILE" >&2
}

log_warning() {
    echo -e "${YELLOW}[ATTENTION]${NC} $*" | tee -a "$LOG_FILE"
}

log_info() {
    echo -e "${BLUE}[INFO]${NC} $*" | tee -a "$LOG_FILE"
}

check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_error "Ce script doit être exécuté en tant que root (sudo)"
        exit 1
    fi
}

detect_ubuntu_version() {
    if [[ ! -f /etc/lsb-release ]]; then
        log_error "Ce script est conçu pour Ubuntu uniquement"
        exit 1
    fi
    
    source /etc/lsb-release
    log "OS détecté: Ubuntu ${DISTRIB_RELEASE} (${DISTRIB_CODENAME})"
}

check_lock() {
    if [[ -f "$LOCK_FILE" ]]; then
        log_error "Une installation est déjà en cours"
        exit 1
    fi
    touch "$LOCK_FILE"
}

cleanup() {
    log "Nettoyage..."
    rm -rf "$TEMP_DIR"
    rm -f "$LOCK_FILE"
}

trap cleanup EXIT

#############################################
# FONCTIONS D'INSTALLATION
#############################################

update_system() {
    log "Mise à jour du système..."
    export DEBIAN_FRONTEND=noninteractive
    
    apt-get update
    apt-get upgrade -y
    
    apt-get install -y \
        apt-transport-https \
        ca-certificates \
        curl \
        gnupg \
        lsb-release \
        software-properties-common \
        git \
        wget \
        vim \
        net-tools \
        bash-completion
    
    log "✓ Système mis à jour"
}

configure_firewall() {
    log "Configuration du pare-feu..."
    
    if systemctl is-active --quiet ufw; then
        ufw allow 6443/tcp
        ufw allow 10250/tcp
        ufw allow 10251/tcp
        ufw allow 10252/tcp
        ufw allow 2379:2380/tcp
        ufw allow 30000:32767/tcp
        log "✓ UFW configuré"
    fi
}

install_containerd() {
    log "Installation de containerd..."
    
    # Ajout du dépôt Docker (contient containerd)
    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    chmod a+r /etc/apt/keyrings/docker.gpg
    
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
      $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
      tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    apt-get update
    apt-get install -y containerd.io
    
    # Configuration containerd pour Kubernetes
    log "Configuration de containerd..."
    systemctl stop containerd
    mkdir -p /etc/containerd
    containerd config default | tee /etc/containerd/config.toml > /dev/null
    
    # Activer systemd cgroups (CRITIQUE pour Kubernetes)
    sed -i 's/SystemdCgroup = false/SystemdCgroup = true/g' /etc/containerd/config.toml
    
    # Configuration réseau
    modprobe br_netfilter
    cat > /etc/sysctl.d/k8s.conf <<EOF
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward = 1
EOF
    
    cat > /etc/modules-load.d/k8s.conf <<EOF
br_netfilter
EOF
    
    sysctl --system
    
    # Démarrage
    systemctl restart containerd
    systemctl enable containerd
    
    log "containerd installé: $(containerd --version)"
}

install_minikube() {
    log "Installation de Minikube ${MINIKUBE_VERSION}..."
    
    mkdir -p "$TEMP_DIR"
    cd "$TEMP_DIR"
    
    curl -LO "https://storage.googleapis.com/minikube/releases/${MINIKUBE_VERSION}/minikube-linux-amd64"
    install minikube-linux-amd64 /usr/local/bin/minikube
    chmod +x /usr/local/bin/minikube
    
    log "Minikube installé: $(minikube version --short)"
}

install_kubernetes_tools() {
    log "Installation des outils Kubernetes ${KUBERNETES_VERSION}..."
    
    local k8s_repo_version
    k8s_repo_version=$(echo "$KUBERNETES_VERSION" | cut -d'.' -f1-2)
    
    # Ajout clé GPG et dépôt
    curl -fsSL https://pkgs.k8s.io/core:/stable:/v${k8s_repo_version}/deb/Release.key | \
        gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
    
    echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v${k8s_repo_version}/deb/ /" | \
        tee /etc/apt/sources.list.d/kubernetes.list
    
    apt-get update
    apt-get install -y \
        kubelet="${KUBERNETES_VERSION}-1.1" \
        kubeadm="${KUBERNETES_VERSION}-1.1" \
        kubectl="${KUBERNETES_VERSION}-1.1"
    
    apt-mark hold kubelet kubeadm kubectl
    systemctl enable kubelet
    
    log "kubectl installé: $(kubectl version --client --short 2>/dev/null | head -1)"
}

install_dependencies() {
    log "Installation des dépendances..."
    
    apt-get install -y conntrack socat
    
    # crictl v1.32.0 (compatible containerd 2.2.1)
    log "Installation de crictl ${CRICTL_VERSION}..."
    cd "$TEMP_DIR"
    curl -LO "https://github.com/kubernetes-sigs/cri-tools/releases/download/${CRICTL_VERSION}/crictl-${CRICTL_VERSION}-linux-amd64.tar.gz"
    tar -zxf "crictl-${CRICTL_VERSION}-linux-amd64.tar.gz"
    install crictl /usr/local/bin/
    
    # Configuration crictl
    tee /etc/crictl.yaml > /dev/null <<EOF
runtime-endpoint: unix:///run/containerd/containerd.sock
image-endpoint: unix:///run/containerd/containerd.sock
timeout: 10
debug: false
EOF
    
    # CNI Plugins
    log "Installation des plugins CNI ${CNI_VERSION}..."
    curl -LO "https://github.com/containernetworking/plugins/releases/download/${CNI_VERSION}/cni-plugins-linux-amd64-${CNI_VERSION}.tgz"
    mkdir -p /opt/cni/bin
    tar -C /opt/cni/bin -xzf "cni-plugins-linux-amd64-${CNI_VERSION}.tgz"
    
    log "✓ crictl version: $(crictl --version)"
}

start_minikube() {
    log "Démarrage de Minikube..."
    
    # Correctif de permissions
    sysctl fs.protected_regular=0
    
    # Démarrage avec containerd
    minikube start \
        --driver=none \
        --kubernetes-version="v${KUBERNETES_VERSION}" \
        --container-runtime=containerd \
        --force || {
            log_error "Échec du démarrage de Minikube"
            return 1
        }
    
    # Configuration des permissions pour l'utilisateur non-root
    local run_user="${SUDO_USER:-$(logname 2>/dev/null || echo 'vagrant')}"
    
    if [[ -n "$run_user" ]] && [[ "$run_user" != "root" ]]; then
        local user_home
        user_home=$(eval echo "~$run_user")
        
        log "Configuration des permissions pour $run_user..."
        
        # Copier .kube et .minikube
        cp -r /root/.kube "$user_home/" 2>/dev/null || true
        cp -r /root/.minikube "$user_home/" 2>/dev/null || true
        
        # Corriger les propriétaires
        chown -R "$run_user:$run_user" "$user_home/.kube" 2>/dev/null || true
        chown -R "$run_user:$run_user" "$user_home/.minikube" 2>/dev/null || true
        
        # Corriger les chemins dans kubeconfig
        if [[ -f "$user_home/.kube/config" ]]; then
            sed -i "s|/root|$user_home|g" "$user_home/.kube/config"
            chmod 600 "$user_home/.kube/config"
        fi
        
        log "✓ Permissions configurées pour $run_user"
    fi
    
    log "✓ Minikube démarré"
}

configure_shell() {
    log "Configuration du shell..."
    
    local run_user="${SUDO_USER:-$(logname 2>/dev/null || echo 'vagrant')}"
    
    if ! id "$run_user" &>/dev/null; then
        log_warning "Utilisateur $run_user non trouvé"
        return 0
    fi
    
    local user_home
    user_home=$(eval echo "~$run_user")
    
    # Configuration bash
    if [[ -f "$user_home/.bashrc" ]]; then
        if ! grep -q "kubectl completion bash" "$user_home/.bashrc"; then
            cat >> "$user_home/.bashrc" <<'EOF'

# Kubernetes aliases and completion
source <(kubectl completion bash)
alias k=kubectl
complete -F __start_kubectl k
alias kgp='kubectl get pods'
alias kgs='kubectl get svc'
alias kgn='kubectl get nodes'
alias kga='kubectl get all -A'
alias kd='kubectl describe'
alias kl='kubectl logs'
alias ke='kubectl exec -it'
EOF
            chown "$run_user:$run_user" "$user_home/.bashrc"
        fi
    fi
    
    # ZSH optionnel
    if [[ "$ENABLE_ZSH" == "true" ]]; then
        install_zsh "$run_user" "$user_home"
    fi
}

install_zsh() {
    local user="$1"
    local user_home="$2"
    
    log "Installation de ZSH pour $user..."
    
    apt-get install -y zsh git
    chsh -s /bin/zsh "$user" || log_warning "Échec changement shell"
    
    if [[ ! -d "$user_home/.oh-my-zsh" ]]; then
        su - "$user" -c 'sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended' || true
    fi
    
    su - "$user" -c "git clone --quiet https://github.com/zsh-users/zsh-syntax-highlighting.git \${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting 2>/dev/null" || true
    
    if [[ -f "$user_home/.zshrc" ]]; then
        sed -i 's/^plugins=/#&/' "$user_home/.zshrc"
        echo 'plugins=(git docker kubectl minikube colored-man-pages zsh-syntax-highlighting)' >> "$user_home/.zshrc"
        sed -i "s/^ZSH_THEME=.*/ZSH_THEME='agnoster'/g" "$user_home/.zshrc"
        chown "$user:$user" "$user_home/.zshrc"
    fi
    
    log "✓ ZSH configuré"
}

validate_installation() {
    log "Validation de l'installation..."
    
    local errors=0
    
    if ! systemctl is-active --quiet containerd; then
        log_error "✗ containerd n'est pas actif"
        ((errors++))
    else
        log "✓ containerd actif"
    fi
    
    if ! crictl info &>/dev/null; then
        log_error "✗ crictl ne fonctionne pas"
        ((errors++))
    else
        log "✓ crictl fonctionnel"
    fi
    
    sleep 5
    
    if kubectl get nodes &>/dev/null; then
        log "✓ Cluster Kubernetes opérationnel"
        kubectl get nodes 2>/dev/null || true
    else
        log_error "✗ Cluster non accessible"
        ((errors++))
    fi
    
    return $errors
}

print_summary() {
    cat <<EOF

╔═══════════════════════════════════════════════════════════════╗
║          Installation Kubernetes Terminée avec Succès         ║
╚═══════════════════════════════════════════════════════════════╝

✅ Composants installés:

   📦 Containerd:    $(containerd --version | cut -d' ' -f3)
   ☸️  Kubernetes:    v${KUBERNETES_VERSION}
   🎡 Minikube:      ${MINIKUBE_VERSION}
   🔧 kubectl:       $(kubectl version --client --short 2>/dev/null | grep -oP 'v\d+\.\d+\.\d+' || echo "installé")
   🛠️  crictl:        ${CRICTL_VERSION}

📚 Commandes utiles:

   kubectl get nodes             # Voir les nœuds
   kubectl get pods -A           # Voir tous les pods
   kubectl cluster-info          # Info du cluster
   minikube status               # Statut Minikube
   
   Alias configurés: k, kgp, kgs, kgn, kga, kd, kl, ke

📝 Logs: $LOG_FILE

🎓 Prochaines étapes:

   1. Déployer une application:
      kubectl create deployment nginx --image=nginx
      
   2. Voir les pods:
      kubectl get pods
      
   3. Accéder au dashboard:
      minikube dashboard

EOF

    if [[ "$ENABLE_ZSH" == "true" ]]; then
        echo "🎨 ZSH installé (reconnectez-vous pour l'activer)"
    fi
}

#############################################
# MAIN
#############################################

main() {
    mkdir -p "$(dirname "$LOG_FILE")"
    exec > >(tee -a "$LOG_FILE")
    exec 2>&1
    
    log "═══════════════════════════════════════════════════════"
    log "  Installation Kubernetes/Minikube pour Ubuntu"
    log "  Version: 3.0 FINALE (Containerd)"
    log "═══════════════════════════════════════════════════════"
    log ""
    log "Configuration:"
    log "  • Kubernetes: v${KUBERNETES_VERSION}"
    log "  • Minikube: ${MINIKUBE_VERSION}"
    log "  • Container Runtime: containerd"
    log "  • crictl: ${CRICTL_VERSION}"
    log ""
    
    check_root
    check_lock
    detect_ubuntu_version
    
    mkdir -p "$TEMP_DIR"
    
    update_system
    configure_firewall
    install_containerd
    install_minikube
    install_kubernetes_tools
    install_dependencies
    start_minikube
    configure_shell
    
    log ""
    log "═══════════════════════════════════════════════════════"
    log "  Validation de l'installation"
    log "═══════════════════════════════════════════════════════"
    
    if validate_installation; then
        print_summary
        log "✅ Installation terminée avec succès!"
        exit 0
    else
        log_error "❌ Installation échouée - vérifiez les logs: $LOG_FILE"
        exit 1
    fi
}

main "$@"
