#!/bin/bash
# Script di auto-installazione per sistemi Linux/macOS
# Auto-installation script for Linux/macOS systems

set -e  # Exit on error

# Colori per output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Funzioni di utilità
print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_info() {
    echo -e "${YELLOW}ℹ${NC} $1"
}

# Rileva sistema operativo
detect_os() {
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if command -v apt-get &> /dev/null; then
            OS="ubuntu"
        elif command -v yum &> /dev/null; then
            OS="centos"
        elif command -v pacman &> /dev/null; then
            OS="arch"
        else
            OS="linux"
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        OS="macos"
    else
        OS="unknown"
    fi
    echo "Sistema operativo rilevato: $OS"
}

# Installa strumenti di base
install_basic_tools() {
    print_info "Installazione strumenti di base..."
    
    case $OS in
        "ubuntu")
            sudo apt-get update
            sudo apt-get install -y curl wget git vim nano htop tree unzip
            ;;
        "centos")
            sudo yum update -y
            sudo yum install -y curl wget git vim nano htop tree unzip
            ;;
        "arch")
            sudo pacman -Syu --noconfirm
            sudo pacman -S --noconfirm curl wget git vim nano htop tree unzip
            ;;
        "macos")
            # Installa Homebrew se non presente
            if ! command -v brew &> /dev/null; then
                /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
            fi
            brew install curl wget git vim nano htop tree
            ;;
    esac
    
    print_success "Strumenti di base installati"
}

# Installa Python e pip
install_python() {
    print_info "Installazione Python..."
    
    case $OS in
        "ubuntu")
            sudo apt-get install -y python3 python3-pip python3-venv
            ;;
        "centos")
            sudo yum install -y python3 python3-pip
            ;;
        "arch")
            sudo pacman -S --noconfirm python python-pip
            ;;
        "macos")
            brew install python
            ;;
    esac
    
    # Aggiorna pip
    python3 -m pip install --upgrade pip
    
    print_success "Python installato"
}

# Installa Node.js
install_nodejs() {
    print_info "Installazione Node.js..."
    
    # Installa usando Node Version Manager (nvm)
    if ! command -v nvm &> /dev/null; then
        curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
        export NVM_DIR="$HOME/.nvm"
        [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    fi
    
    nvm install --lts
    nvm use --lts
    
    print_success "Node.js installato"
}

# Installa Docker
install_docker() {
    print_info "Installazione Docker..."
    
    case $OS in
        "ubuntu")
            curl -fsSL https://get.docker.com -o get-docker.sh
            sudo sh get-docker.sh
            sudo usermod -aG docker $USER
            ;;
        "centos")
            sudo yum install -y yum-utils
            sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
            sudo yum install -y docker-ce docker-ce-cli containerd.io
            sudo systemctl start docker
            sudo systemctl enable docker
            sudo usermod -aG docker $USER
            ;;
        "macos")
            brew install --cask docker
            ;;
    esac
    
    print_success "Docker installato"
}

# Configura Git
setup_git() {
    print_info "Configurazione Git..."
    
    read -p "Inserisci il tuo nome: " git_name
    read -p "Inserisci la tua email: " git_email
    
    git config --global user.name "$git_name"
    git config --global user.email "$git_email"
    git config --global init.defaultBranch main
    git config --global pull.rebase false
    
    print_success "Git configurato"
}

# Installa VS Code
install_vscode() {
    print_info "Installazione Visual Studio Code..."
    
    case $OS in
        "ubuntu")
            wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
            sudo install -o root -g root -m 644 packages.microsoft.gpg /etc/apt/trusted.gpg.d/
            sudo sh -c 'echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/trusted.gpg.d/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list'
            sudo apt-get update
            sudo apt-get install -y code
            ;;
        "centos")
            sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
            sudo sh -c 'echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/vscode.repo'
            sudo yum install -y code
            ;;
        "macos")
            brew install --cask visual-studio-code
            ;;
    esac
    
    print_success "VS Code installato"
}

# Crea alias utili
create_aliases() {
    print_info "Creazione alias utili..."
    
    # Backup del file bashrc/zshrc esistente
    if [[ "$SHELL" == *"zsh"* ]]; then
        SHELL_RC="$HOME/.zshrc"
    else
        SHELL_RC="$HOME/.bashrc"
    fi
    
    cp "$SHELL_RC" "$SHELL_RC.backup" 2>/dev/null || true
    
    # Aggiunge alias
    cat >> "$SHELL_RC" << 'EOF'

# Alias personalizzati aggiunti dall'auto-installer
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias ..='cd ..'
alias ...='cd ../..'
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'
alias h='history'
alias j='jobs -l'
alias path='echo -e ${PATH//:/\\n}'
alias now='date +"%T"'
alias nowtime=now
alias nowdate='date +"%d-%m-%Y"'

# Git aliases
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git log --oneline'
alias gd='git diff'

# Python aliases
alias py='python3'
alias pip='python3 -m pip'
alias venv='python3 -m venv'

# Docker aliases
alias d='docker'
alias dc='docker-compose'
alias dps='docker ps'
alias di='docker images'

EOF
    
    print_success "Alias creati in $SHELL_RC"
}

# Funzione principale
main() {
    echo "======================================="
    echo "    AUTO INSTALLER SCRIPT"
    echo "======================================="
    
    detect_os
    
    echo ""
    echo "Seleziona cosa installare:"
    echo "1) Strumenti di base (curl, wget, git, vim, etc.)"
    echo "2) Python e pip"
    echo "3) Node.js (via nvm)"
    echo "4) Docker"
    echo "5) Visual Studio Code"
    echo "6) Configura Git"
    echo "7) Crea alias utili"
    echo "8) Tutto"
    echo "0) Esci"
    
    read -p "Scelta [0-8]: " choice
    
    case $choice in
        1)
            install_basic_tools
            ;;
        2)
            install_python
            ;;
        3)
            install_nodejs
            ;;
        4)
            install_docker
            ;;
        5)
            install_vscode
            ;;
        6)
            setup_git
            ;;
        7)
            create_aliases
            ;;
        8)
            install_basic_tools
            install_python
            install_nodejs
            install_docker
            install_vscode
            setup_git
            create_aliases
            ;;
        0)
            echo "Uscita..."
            exit 0
            ;;
        *)
            print_error "Scelta non valida!"
            exit 1
            ;;
    esac
    
    echo ""
    print_success "Installazione completata!"
    print_info "Riavvia il terminale per applicare tutte le modifiche."
}

# Esegue lo script
main "$@"
