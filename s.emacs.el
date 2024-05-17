;; .emacs
(setq inhibit-startup-message t)
(scroll-bar-mode -1)
(show-paren-mode)
(tool-bar-mode -1)
(set-frame-font "Fira Code 12" nil t)

(setenv "PATH" (concat (getenv "PATH") ":" (getenv "HOME") "/.local/bin"))
(setq exec-path (append exec-path '((concat (getenv "HOME") "/.local/bin"))))

(xterm-mouse-mode)
(global-set-key (kbd "<mouse-4>") (lambda () (interactive) (scroll-down 2)))
(global-set-key (kbd "<mouse-5>") (lambda () (interactive) (scroll-up 2)))

(require 'package)
(add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/"))

(defun ensure-package (pkg)
  (unless (package-installed-p pkg)
    (unless package-archive-contents (package-refresh-contents))
    (package-install pkg)))

(require 'url)
(defun ensure-url (url)
  (let* ((source (url-generic-parse-url url))
	 (target (concat user-emacs-directory (url-host source) (url-filename source))))
    (unless (file-exists-p target)
      (make-directory (file-name-directory target) :parents)
      (url-copy-file source target))
    (add-to-list 'load-path (file-name-directory target))))

(let ((hs (locate-file "hunspell" exec-path exec-suffixes 1)))
  (when hs (setq ispell-program-name hs)))

(setq-default
 eglot-workspace-configuration
 '(
   :texlab (
	    :auxDirectory "."
	    :bibtexFormatter "texlab"
	    :build (
		    :args ["-X" "compile" "%f" "--synctex" "--keep-logs" "--keep-intermediates"]
		    :executable "tectonic"
		    :forwardSearchAfter t
		    :onSave t)

	    :chktex (
		     :onEdit t
		     :onOpenAndSave t)

	    :diagnosticsDelay 300
	    :formatterLineLength 80
	    :forwardSearch
	    (
	     :executable "evince-synctex" ;broken in flatpak due to python `import dbus` failing
	     :args ["-f" "%l" "%p" "\"code-g%f:%l\""])
	    :latexFormatter "latexindent"
	    :latexindent (
			  :modifyLineBreaks :json-false))))

(add-hook
 'latex-mode-hook
 (lambda ()
   (when t ;(locate-file "pdflatex" exec-path exec-suffixes 1)
     (ensure-package 'auctex)
     (ensure-package 'eglot))))

(add-hook
 'LaTeX-mode-hook
 (lambda ()
   (require 'preview)
   (dolist
       (i '((LaTeX-electric-left-right-brace t)
	    (LaTeX-math-list ((?/ "over" "Misc Symbol" 2215)))
	    (preview-scale-function 0.7)
	    (TeX-auto-save t)
	    (TeX-command-extra-options "-shell-escape")
	    (TeX-electric-sub-and-superscript t)
	    (TeX-parse-self t)
	    (TeX-view-program-selection ((output-pdf "xdg-open")))))
     (customize-set-variable (car i) (cadr i)))
   (set-face-foreground 'preview-reference-face "black")
   (LaTeX-math-mode)
   (prettify-symbols-mode)
   (eglot-ensure)))

(if (display-graphic-p)
    (add-hook
     'emacs-startup-hook
     (lambda ()
       (ensure-package 'color-theme-sanityinc-solarized)
       (load-theme 'sanityinc-solarized-light t)
       (ensure-url
	"https://raw.githubusercontent.com/mickeynp/ligature.el/master/ligature.el")
       (require 'ligature)
       (ligature-set-ligatures t '("www"))
       (ligature-set-ligatures
	'prog-mode
	'("www" "**" "***" "**/" "*>" "*/" "\\\\" "\\\\\\" "{-" "::"
	  ":::" ":=" "!!" "!=" "!==" "-}" "----" "-->" "->" "->>"
	  "-<" "-<<" "-~" "#{" "#[" "##" "###" "####" "#(" "#?" "#_"
	  "#_(" ".-" ".=" ".." "..<" "..." "?=" "??" ";;" "/*" "/**"
	  "/=" "/==" "/>" "//" "///" "&&" "||" "||=" "|=" "|>" "^=" "$>"
	  "++" "+++" "+>" "=:=" "==" "===" "==>" "=>" "=>>" "<="
	  "=<<" "=/=" ">-" ">=" ">=>" ">>" ">>-" ">>=" ">>>" "<*"
	  "<*>" "<|" "<|>" "<$" "<$>" "<!--" "<-" "<--" "<->" "<+"
	  "<+>" "<=" "<==" "<=>" "<=<" "<>" "<<" "<<-" "<<=" "<<<"
	  "<~" "<~~" "</" "</>" "~@" "~-" "~>" "~~" "~~>" "%%"))
       (global-ligature-mode)))
  (load-theme 'wombat t))
