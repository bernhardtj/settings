recipe_bin() {
    echo auctex
}
recipe_install() {
    set -e
    tmp=$(mktemp -d)

    cat <<'EOF' >"$tmp/.emacs"
(package-initialize)
(setq inhibit-startup-message t)
(show-paren-mode 1)
(when (fboundp 'global-font-lock-mode) (global-font-lock-mode t))
(setq require-final-newline 'query)
(set-frame-font "Fira Code 12" nil t)
(setq ispell-program-name "hunspell")
(setq ispell-local-dictionary "en_US")
(setq ispell-local-dictionary-alist '(("en_US" "[[:alpha:]]" "[^[:alpha:]]" "[']" nil ("-d" "en_US") nil utf-8)))
(load-theme 'solarized-light t)
(add-to-list 'load-path "/root/.emacs.d/site-lisp")
(require 'tex-site)
(load "preview.el" nil t t)
(setq TeX-electric-sub-and-superscript t)
(setq LaTeX-electric-left-right-brace t)
(setq TeX-parse-self t)
(setq TeX-auto-save t)
(setq-default TeX-engine 'luatex)
(setq-default TeX-command-extra-options "-shell-escape")
(add-hook 'LaTeX-mode-hook 'LaTeX-math-mode)
EOF

    cat <<'EOF' >"$tmp/starter.tex"
\documentclass[12pt]{article}
\usepackage[left=1in, right=1in, top=1in, bottom=1in]{geometry}
\usepackage{amsmath, amssymb, bm, cancel, float, fancyhdr, tikz, graphicx}
\usepackage[charter]{mathdesign}
\pagestyle{fancy}\renewcommand{\headrulewidth}{0pt}\fancyhf{}
\rhead{\bf TITLE}\lhead{\bf NAME}\cfoot{\thepage}

\def\checkmark{\hspace{1ex}\tikz\fill[scale=0.4](0,.35) -- (.25,0) -- (1,.7) -- (.25,.15) -- cycle;}
\DeclareMathOperator*{\argmin}{argmin}
\DeclareMathOperator*{\argmax}{argmax}
\let\transpose\intercal

% \usepackage{pgfplotstable}\pgfplotsset{compat=1.17}

% \usepackage{minted}
% \newcommand\loc[3]{\inputminted[linenos, firstline=#1, lastline=#2]{python}{#3}\noindent}
% \def\textpy{\mintinline{python}}
% \def\minterrorsoff{\renewcommand\fcolorbox[4][]{#4}}

\begin{document}

% \begin{thebibliography}{1}
% \bibitem{bib1} Some entry
% \end{thebibliography}
\end{document}
EOF

    cat <<'EOF' >"$tmp/doit"
#!/bin/bash
case $1 in
--viewer-proc)
    func() { cd "$1" && shift && xdg-open "$@" >/dev/null 2>/dev/null; }
    while read -r line; do func $line; done
    ;;
--new-window)
    bash "${BASH_SOURCE[0]}"
    ;;
--new-document)
    bash "${BASH_SOURCE[0]}" --eval '(LaTeX-mode)' --insert "$HOME/.cache/auctex/default.tex"
    ;;
*)
    mkdir -p "$HOME/.cache/auctex/work"
    ln -sf "$HOME/.local/share/auctex/default.tex" "$HOME/.cache/auctex/default.tex"
    printf '' >"$HOME/.cache/auctex/viewer"
    tail -f "$HOME/.cache/auctex/viewer" | bash "${BASH_SOURCE[0]}" --viewer-proc &
    viewerPid=$!
    trap '[[ "$viewerPid" ]] && kill "$viewerPid"' EXIT
    podman run --rm -it \
        -v /tmp/.X11-unix:/tmp/.X11-unix -e DISPLAY --security-opt=label=disable \
        -v "$HOME/.cache/auctex:/miktex" \
        -v "$HOME/.local/share/fonts:/root/.local/share/fonts" \
        -v /var/home:/var/home -w "$(pwd)" auctex /usr/bin/emacs "$@"
    ;;
esac
EOF

    mkdir -p "$tmp"/hicolor/{scalable,symbolic}/apps
    curl '-#Lo' "$tmp"/hicolor/scalable/apps/auctex.svg https://gitlab.gnome.org/GNOME/gnome-latex/-/raw/master/data/icons/org.gnome.gnome-latex.svg
    curl '-#Lo' "$tmp"/hicolor/symbolic/apps/auctex-symbolic.svg https://gitlab.gnome.org/GNOME/gnome-latex/-/raw/master/data/icons/org.gnome.gnome-latex-symbolic.svg
    curl '-#L' https://gitlab.gnome.org/GNOME/gnome-latex/-/raw/master/data/org.gnome.gnome-latex.desktop.in | sed "s/GNOME LaTeX/AUCTeX/g;s/Icon=.*latex/Icon=auctex/g;s,gnome-latex,$HOME/.local/bin/auctex,g" | tr -d '_' >"$tmp"/auctex.desktop
    curl '-#Lo' "$tmp/auctex.tar.gz" ftp.gnu.org/pub/gnu/auctex/auctex-12.2.tar.gz

    podman rmi auctex || true
    rm -rf "$HOME/.cache/auctex"

    podman build -f - -v "$tmp":/mnt --squash-all -t auctex <<'EOF'
FROM miktex/miktex
RUN apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys D6BC243565B2087BC3F897C9277A7293F59E4889
RUN apt update && apt upgrade -y --no-install-recommends emacs25-lucid hunspell python-pygments elpa-solarized-theme && apt autoremove -y && apt clean
RUN miktexsetup --verbose --shared=yes finish && initexmf --verbose --admin --set-config-value [MPM]AutoInstall=1 && initexmf --verbose --admin --default-paper-size=letter && mpm --verbose --admin --update-db && mpm --verbose --admin --upgrade --package-level=essential && initexmf --verbose --admin --update-fndb
RUN tar -xzf /mnt/auctex.tar.gz && cd auctex* && ./configure --prefix=/root/.emacs.d/auctex --with-lispdir=/root/.emacs.d/site-lisp --with-texmf-dir=/usr/share/miktex-texmf/miktex && make && make install && cd .. && rm -rf auctex* && rm -rf /miktex/.miktex
RUN install /mnt/.emacs /root/.emacs && mkdir -p /var/home
RUN echo 'echo $(pwd) "$@" >> /miktex/viewer' > /usr/bin/evince && chmod +x /usr/bin/evince
EOF

    cd "$tmp"
    install -Dvm755 doit "$HOME/.local/bin/auctex"
    install -Dvm664 auctex.desktop "$HOME/.local/share/applications/auctex.desktop"
    install -Dvm644 starter.tex "$HOME/.local/share/auctex/default.tex"
    find hicolor -type f -exec install -Dvm644 {} "$HOME/.local/share/icons"/{} \;

}
