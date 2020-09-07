;; .emacs
(setq inhibit-startup-message t)
(require 'package)
(setq package-enable-at-startup nil)
(add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/"))
(package-initialize)
(unless package-archive-contents (package-refresh-contents))
(unless (package-installed-p 'use-package) (package-install 'use-package))
(require 'use-package)

(if (display-graphic-p)
    (progn
      (use-package solarized-theme
	:ensure t
	:load-path "themes"
	:init
	:config
	(load-theme 'solarized-light t))
      (defun fira-code-mode--make-alist (list)
	"Generate prettify-symbols alist from LIST."
	(let ((idx -1))
	  (mapcar
	   (lambda (s)
	     (setq idx (1+ idx))
	     (let* ((code (+ #Xe100 idx))
		    (width (string-width s))
		    (prefix ())
		    (suffix '(?\s (Br . Br)))
		    (n 1))
	       (while (< n width)
		 (setq prefix (append prefix '(?\s (Br . Bl))))
		 (setq n (1+ n)))
	       (cons s (append prefix suffix (list (decode-char 'ucs code))))))
	   list)))

      (defconst fira-code-mode--ligatures
	'("www" "**" "***" "**/" "*>" "*/" "\\\\" "\\\\\\"
	  "{-" "[]" "::" ":::" ":=" "!!" "!=" "!==" "-}"
	  "--" "---" "-->" "->" "->>" "-<" "-<<" "-~"
	  "#{" "#[" "##" "###" "####" "#(" "#?" "#_" "#_("
	  ".-" ".=" ".." "..<" "..." "?=" "??" ";;" "/*"
	  "/**" "/=" "/==" "/>" "//" "///" "&&" "||" "||="
	  "|=" "|>" "^=" "$>" "++" "+++" "+>" "=:=" "=="
	  "===" "==>" "=>" "=>>" "<=" "=<<" "=/=" ">-" ">="
	  ">=>" ">>" ">>-" ">>=" ">>>" "<*" "<*>" "<|" "<|>"
	  "<$" "<$>" "<!--" "<-" "<--" "<->" "<+" "<+>" "<="
	  "<==" "<=>" "<=<" "<>" "<<" "<<-" "<<=" "<<<" "<~"
	  "<~~" "</" "</>" "~@" "~-" "~=" "~>" "~~" "~~>" "%%"
	  "×" ":" "+" "+" "*"))

      (defvar fira-code-mode--old-prettify-alist)

      (defun fira-code-mode--enable ()
	"Enable Fira Code ligatures in current buffer."
	(fira-code-mode--setup)
	(setq-local fira-code-mode--old-prettify-alist prettify-symbols-alist)
	(setq-local prettify-symbols-alist
		    (append (fira-code-mode--make-alist fira-code-mode--ligatures)
			    fira-code-mode--old-prettify-alist))
	(prettify-symbols-mode t))

      (defun fira-code-mode--disable ()
	"Disable Fira Code ligatures in current buffer."
	(setq-local prettify-symbols-alist fira-code-mode--old-prettify-alist)
	(prettify-symbols-mode -1))

      (define-minor-mode fira-code-mode
	"Fira Code ligatures minor mode"
	:lighter "  "
	(setq-local prettify-symbols-unprettify-at-point 'right-edge)
	(if fira-code-mode
	    (fira-code-mode--enable)
	  (fira-code-mode--disable)))

      (defun fira-code-mode--setup ()
	"Setup Fira Code Symbols"
	(set-fontset-font t '(#Xe100 . #Xe16f) "Fira Code Symbol"))

      (provide 'fira-code-mode)

      (define-globalized-minor-mode my-global-rainbow-mode fira-code-mode
	(lambda () (fira-code-mode 1)))

      (my-global-rainbow-mode 1)

      (set-frame-font "Fira Code 12" nil t)

      ) ;; no display
  (load-theme 'wombat t))

;;; uncomment this line to disable loading of "default.el" at startup
;; (setq inhibit-default-init t)

;; turn on font-lock mode
(when (fboundp 'global-font-lock-mode)
  (global-font-lock-mode t))

;; enable visual feedback on selections
;;(setq transient-mark-mode t)

;; default to better frame titles
(setq frame-title-format
      (concat  "%b - emacs@" (system-name)))

;; default to unified diffs
(setq diff-switches "-u")

;; always end a file with a newline
;;(setq require-final-newline 'query)

(defun scroll-up-10-lines ()
  (interactive)
  (scroll-up 2))

(defun scroll-down-10-lines ()
  (interactive)
  (scroll-down 2))

(global-set-key (kbd "<mouse-4>") 'scroll-down-10-lines) ;
(global-set-key (kbd "<mouse-5>") 'scroll-up-10-lines) ;


