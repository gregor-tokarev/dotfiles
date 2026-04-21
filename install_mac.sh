#!/bin/zsh
set -e

DOTFILES="$HOME/dotfiles"

# ─── Brew Taps ──────────────────────────────────────────────────────────────

brew tap anomalyco/tap
brew tap antoniorodr/memo
brew tap charmbracelet/tap
brew tap markmarkoh/lt
brew tap tw93/tap
brew tap koekeishiya/formulae
brew tap derailed/k9s
brew tap bufbuild/buf

# ─── Brew Formulas ───────────────────────────────────────────────────────────

brew install stow ripgrep fzf bat eza zoxide tmux
brew install lazygit lazydocker k9s kubectx kubernetes-cli gh
brew install yazi btop htop neovim yq fd skhd
brew install git-filter-repo nmap mkcert pnpm tokei watch node
brew install television superfile codecrafters grpcurl cmake buf
brew install lt memo crush mole

# ─── Brew Casks ──────────────────────────────────────────────────────────────

brew install --cask ghostty
brew install --cask karabiner-elements
brew install --cask zed
brew install --cask obsidian
brew install --cask linear
brew install --cask docker
brew install --cask postman
brew install --cask arc
brew install --cask firefox
brew install --cask google-chrome
brew install --cask flux
brew install --cask telegram
brew install --cask raycast
brew install --cask font-fira-code-nerd-font

# ─── Oh My Zsh + Plugins ─────────────────────────────────────────────────────

if [ ! -d "$HOME/.oh-my-zsh" ]; then
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
fi

git clone https://github.com/zsh-users/zsh-autosuggestions "$HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions" 2>/dev/null || true
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting" 2>/dev/null || true
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$HOME/.oh-my-zsh/custom/themes/powerlevel10k" 2>/dev/null || true

# ─── fzf Keybindings ─────────────────────────────────────────────────────────

"$(brew --prefix)/opt/fzf/install" --key-bindings --completion --no-update-rc

# ─── Node (nvm) ──────────────────────────────────────────────────────────────

if [ ! -d "$HOME/.nvm" ]; then
  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
fi

# ─── Rust / Cargo ────────────────────────────────────────────────────────────

if [ ! -d "$HOME/.cargo" ]; then
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
fi

# ─── gh Extensions ───────────────────────────────────────────────────────────

gh extension install dlvhdr/gh-dash 2>/dev/null || true

# ─── CLI Tools (non-brew) ───────────────────────────────────────────────────

# Claude Code
if ! command -v claude &>/dev/null; then
  npm install -g @anthropic-ai/claude-code
fi

# OpenCode
brew install anomalyco/tap/opencode

# Codex
if ! command -v codex &>/dev/null; then
  npm install -g @openai/codex
fi

# ─── GNU Stow ─────────────────────────────────────────────────────────────────

cd "$DOTFILES"
stow nvim
stow zsh
stow claude
stow ghostty
stow npm
stow opencode
stow warp
stow yabai
stow zed
stow karabiner
stow gh-dash
cd "$HOME"

# ─── macOS Defaults ──────────────────────────────────────────────────────────

defaults write com.apple.dock autohide-delay -float 0; killall Dock
# restore default:
# defaults delete com.apple.dock autohide-delay; killall Dock

echo ""
echo "Done! Restart your terminal or run: source ~/.zshrc"