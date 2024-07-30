#!/bin/zsh

brew install stow
brew install --cask warp

brew install ripgrep
stow nvim

stow zsh

defaults write com.apple.dock autohide-delay -float 0; killall Dock
# restore default:
# defaults delete com.apple.dock autohide-delay; killall Dock


brew install --cask raycast
brew install --cask docker
brew install --cask postman

brew install --cask arc
brew install --cask firefox
brew install --cask google-chrome

brew install --cask flux
brew install --cask telegram

brew install --cask meld-studio
