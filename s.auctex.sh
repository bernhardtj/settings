# .local/bin/auctex-update
#!/bin/bash
tmp=$(mktemp -d)
cat <<'EOF' >"$tmp/.emacs"
(setq inhibit-startup-message t)
(show-paren-mode 1)
(when (fboundp 'global-font-lock-mode) (global-font-lock-mode t))
(setq require-final-newline 'query)
(set-frame-font "Fira Code 12" nil t)
(setq ispell-program-name "hunspell")
(setq ispell-local-dictionary "en_US")
(setq ispell-local-dictionary-alist '(("en_US" "[[:alpha:]]" "[^[:alpha:]]" "[']" nil ("-d" "en_US") nil utf-8)))
(require 'package)
(setq package-enable-at-startup nil)
(add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/"))
(package-initialize)
(unless package-archive-contents (package-refresh-contents))
(unless (package-installed-p 'use-package) (package-install 'use-package))
(require 'use-package)
(use-package solarized-theme
  :ensure t
  :load-path "themes"
  :init
  :config
  (load-theme 'solarized-light t))
(use-package reformatter :ensure t)
(reformatter-define LaTeX-format :program "texpretty-silent")
(use-package auctex
  :ensure t
  :defer t
  :config
  (setq latex-run-command "latex")
  (setq preview-gs-command "/usr/bin/gs")
  (define-key LaTeX-mode-map (kbd "C-M-L") 'LaTeX-format-buffer)
  (setq LaTeX-indent-level 4)
  (setq LaTeX-item-indent -4)
  (setq LaTeX-left-right-indent-level 4)
  (setq TeX-electric-sub-and-superscript t)
  (setq TeX-parse-self t)
  (setq TeX-auto-save t)
  (add-hook 'LaTeX-mode-hook 'LaTeX-math-mode)
  (require 'tex-mik)
  (load "preview.el" nil t t))
EOF

cat <<EOF >"$tmp/auctex.desktop"
[Desktop Entry]
Name=AUCTeX
GenericName=TeX Editor
Comment=Edit TeX
MimeType=text/x-tex
Exec=$HOME/.local/bin/auctex %f
Icon=emacs
Type=Application
Terminal=false
Categories=Utility;TextEditor;X-Red-Hat-Base;
StartupWMClass=Emacs
X-Desktop-File-Install-Version=0.24
EOF

cat <<'EOF' >"$tmp/doit"
f=; test -n "$1" && f="/var/host/$1"
mkdir -p $HOME/.cache/auctex/emacs $HOME/.cache/auctex/miktex
podman run --rm -it \
-v /tmp/.X11-unix:/tmp/.X11-unix -e DISPLAY --security-opt=label=disable \
-v $HOME/.cache/auctex/miktex:/root/.miktex \
-v $HOME/.cache/auctex/emacs:/root/.emacs.d \
-v $HOME/.local/share/fonts:/root/.local/share/fonts \
-v /usr/share/fonts:/usr/share/fonts \
-v /:/var/host auctex /usr/bin/emacs $f
EOF

podman rmi auctex || true
rm -rf "$HOME/.cache/auctex"
install -Dm755 "$tmp/doit" "$HOME/.local/bin/auctex"
install -Dm664 "$tmp/auctex.desktop" "$HOME/.local/share/applications/auctex.desktop"

podman build -f - -v "$tmp":/mnt --squash-all -t auctex <<EOF
FROM fedora:32
RUN echo 'LANG="en_US.UTF-8"' > /etc/locale.conf
RUN mkdir -p /var/host && mkdir -p /root/.local/share/fonts
RUN rpm --import "https://keyserver.ubuntu.com/pks/lookup?op=get&search=0xD6BC243565B2087BC3F897C9277A7293F59E4889"
RUN curl -L -o /etc/yum.repos.d/miktex.repo https://miktex.org/download/fedora/32/miktex.repo
RUN cp /mnt/.emacs /root/.emacs
RUN dnf install -y adapta-gtk-theme ghostscript miktex emacs evince which python3-pygments make gcc && dnf clean all
RUN miktexsetup --verbose --shared=yes finish
RUN initexmf --verbose --admin --set-config-value [MPM]AutoInstall=1
RUN initexmf --verbose --admin --default-paper-size=letter
RUN curl ftp://ftp.math.utah.edu/pub/misc/texpretty-0.02.tar.gz | tar xzC .
RUN cd texpretty-0.02 && ./configure && make && make -i check && make install-exe
RUN printf '#!/bin/sh\ntexpretty | tail -n+6' > /usr/local/bin/texpretty-silent && chmod 777 /usr/local/bin/texpretty-silent
RUN rm -rf texpretty*
EOF
