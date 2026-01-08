(setq custom-file "~/.emacs.custom.el")
(setq package-enable-at-startup nil)

;; Optimize garbage collection during startup
(setq gc-cons-threshold (* 50 1000 1000))

(package-initialize)

(add-to-list 'load-path "~/.emacs.local/")

(load "~/.emacs.rc/rc.el")

(load "~/.emacs.rc/misc-rc.el")
(load "~/.emacs.rc/org-mode-rc.el")
(load "~/.emacs.rc/autocommit-rc.el")

;; Install use-package if not already installed
(unless (package-installed-p 'use-package)
  (package-refresh-contents)
  (package-install 'use-package))

(require 'use-package)
(setq use-package-always-defer t) ; Defer all packages by default

;;; Appearance
(defun rc/get-default-font ()
  (cond
   ((eq system-type 'windows-nt) "Consolas-13")
   ((eq system-type 'gnu/linux) "Iosevka-20")))

(add-to-list 'default-frame-alist `(font . ,(rc/get-default-font)))

(tool-bar-mode 0)
(menu-bar-mode 0)
(scroll-bar-mode 0)
(column-number-mode 1)
(show-paren-mode 1)

(rc/require-theme 'gruber-darker)
;; (rc/require-theme 'zenburn)
;; (load-theme 'adwaita t)

(eval-after-load 'zenburn
  (set-face-attribute 'line-number nil :inherit 'default))

;;; ido
(ido-mode 1)
(ido-everywhere 1)

(use-package ido-completing-read+
  :demand t
  :config
  (ido-ubiquitous-mode 1))

(use-package smex
  :bind (("M-x" . smex)
         ("C-c C-c M-x" . execute-extended-command)))

;;; c-mode
(setq-default c-basic-offset 4
              c-default-style '((java-mode . "java")
                                (awk-mode . "awk")
                                (other . "bsd")))

(add-hook 'c-mode-hook (lambda ()
                         (interactive)
                         (c-toggle-comment-style -1)))

;;; Paredit
(use-package paredit
  :hook ((emacs-lisp-mode . paredit-mode)
         (clojure-mode . paredit-mode)
         (lisp-mode . paredit-mode)
         (common-lisp-mode . paredit-mode)
         (scheme-mode . paredit-mode)
         (racket-mode . paredit-mode)))

;;; Emacs lisp
(add-hook 'emacs-lisp-mode-hook
          '(lambda ()
             (local-set-key (kbd "C-c C-j")
                            (quote eval-print-last-sexp))))
(add-to-list 'auto-mode-alist '("Cask" . emacs-lisp-mode))

;;; uxntal-mode
(use-package uxntal-mode)

;;; Haskell mode
(use-package haskell-mode
  :config
  (setq haskell-process-type 'cabal-new-repl)
  (setq haskell-process-log t)
  :hook ((haskell-mode . haskell-indent-mode)
         (haskell-mode . interactive-haskell-mode)
         (haskell-mode . haskell-doc-mode)))

(autoload 'basm-mode "basm-mode" nil t)

(autoload 'fasm-mode "fasm-mode" nil t)
(add-to-list 'auto-mode-alist '("\\.asm\\'" . fasm-mode))

(autoload 'porth-mode "porth-mode" nil t)

(autoload 'noq-mode "noq-mode" nil t)

(autoload 'jai-mode "jai-mode" nil t)

(autoload 'simpc-mode "simpc-mode" nil t)
(add-to-list 'auto-mode-alist '("\\.[hc]\\(pp\\)?\\'" . simpc-mode))
(add-to-list 'auto-mode-alist '("\\.[b]\\'" . simpc-mode))

(autoload 'umka-mode "umka-mode" nil t)

(autoload 'c3-mode "c3-mode" nil t)

;;; Whitespace mode
(defun rc/set-up-whitespace-handling ()
  (interactive)
  (whitespace-mode 1)
  (add-to-list 'write-file-functions 'delete-trailing-whitespace))

(add-hook 'tuareg-mode-hook 'rc/set-up-whitespace-handling)
(add-hook 'c++-mode-hook 'rc/set-up-whitespace-handling)
(add-hook 'c-mode-hook 'rc/set-up-whitespace-handling)
(add-hook 'simpc-mode-hook 'rc/set-up-whitespace-handling)
(add-hook 'emacs-lisp-mode 'rc/set-up-whitespace-handling)
(add-hook 'java-mode-hook 'rc/set-up-whitespace-handling)
(add-hook 'lua-mode-hook 'rc/set-up-whitespace-handling)
(add-hook 'rust-mode-hook 'rc/set-up-whitespace-handling)
(add-hook 'scala-mode-hook 'rc/set-up-whitespace-handling)
(add-hook 'markdown-mode-hook 'rc/set-up-whitespace-handling)
(add-hook 'haskell-mode-hook 'rc/set-up-whitespace-handling)
(add-hook 'python-mode-hook 'rc/set-up-whitespace-handling)
(add-hook 'erlang-mode-hook 'rc/set-up-whitespace-handling)
(add-hook 'asm-mode-hook 'rc/set-up-whitespace-handling)
(add-hook 'fasm-mode-hook 'rc/set-up-whitespace-handling)
(add-hook 'go-mode-hook 'rc/set-up-whitespace-handling)
(add-hook 'nim-mode-hook 'rc/set-up-whitespace-handling)
(add-hook 'yaml-mode-hook 'rc/set-up-whitespace-handling)
(add-hook 'porth-mode-hook 'rc/set-up-whitespace-handling)

;;; display-line-numbers-mode
(when (version<= "26.0.50" emacs-version)
  (global-display-line-numbers-mode))

;;; magit
(use-package magit
  :bind (("C-c m s" . magit-status)
         ("C-c m l" . magit-log))
  :config
  (setq magit-auto-revert-mode nil))

;;; multiple cursors
(use-package multiple-cursors
  :bind (("C-S-c C-S-c" . mc/edit-lines)
         ("C->" . mc/mark-next-like-this)
         ("C-<" . mc/mark-previous-like-this)
         ("C-c C-<" . mc/mark-all-like-this)
         ("C-\"" . mc/skip-to-next-like-this)
         ("C-:" . mc/skip-to-previous-like-this)))

;;; dired
(require 'dired-x)
(setq dired-omit-files
      (concat dired-omit-files "\\|^\\..+$"))
(setq-default dired-dwim-target t)
(setq dired-listing-switches "-alh")
(setq dired-mouse-drag-files t)

;;; helm
(use-package helm
  :bind (("C-c h t" . helm-cmd-t)
         ("C-c h f" . helm-find)
         ("C-c h a" . helm-org-agenda-files-headings)
         ("C-c h r" . helm-recentf))
  :config
  (setq helm-ff-transformer-show-only-basename nil))

(use-package helm-git-grep
  :bind ("C-c h g g" . helm-git-grep))

(use-package helm-ls-git
  :bind ("C-c h g l" . helm-ls-git-ls))

;;; yasnippet
(use-package yasnippet
  :defer 2
  :config
  (setq yas/triggers-in-field nil)
  (setq yas-snippet-dirs '("~/.emacs.snippets/"))
  (yas-global-mode 1))

;;; word-wrap
(defun rc/enable-word-wrap ()
  (interactive)
  (toggle-word-wrap 1))

(add-hook 'markdown-mode-hook 'rc/enable-word-wrap)

;;; nxml
(add-to-list 'auto-mode-alist '("\\.html\\'" . nxml-mode))
(add-to-list 'auto-mode-alist '("\\.xsd\\'" . nxml-mode))
(add-to-list 'auto-mode-alist '("\\.ant\\'" . nxml-mode))

;;; tramp
;;; http://stackoverflow.com/questions/13794433/how-to-disable-autosave-for-tramp-buffers-in-emacs
(setq tramp-auto-save-directory "/tmp")

;;; powershell
(use-package powershell
  :mode (("\\.ps1\\'" . powershell-mode)
         ("\\.psm1\\'" . powershell-mode)))

;;; eldoc mode
(defun rc/turn-on-eldoc-mode ()
  (interactive)
  (eldoc-mode 1))

(add-hook 'emacs-lisp-mode-hook 'rc/turn-on-eldoc-mode)

;;; Company
(use-package company
  :defer 1
  :config
  (global-company-mode)
  :hook (tuareg-mode . (lambda () (company-mode 0))))

;;; Typescript
(use-package typescript-mode
  :mode "\\.mts\\'")

;;; Tide
(use-package tide
  :hook (typescript-mode . (lambda ()
                             (tide-setup)
                             (flycheck-mode 1))))

;;; Proof general
(use-package proof-general
  :hook (coq-mode . (lambda ()
                      (local-set-key (kbd "C-c C-q C-n")
                                     'proof-assert-until-point-interactive))))

;;; LaTeX mode
(add-hook 'tex-mode-hook
          (lambda ()
            (interactive)
            (add-to-list 'tex-verbatim-environments "code")))

(setq font-latex-fontify-sectioning 'color)

;;; Move Text
(use-package move-text
  :bind (("M-p" . move-text-up)
         ("M-n" . move-text-down)))

;;; Ebisp
(add-to-list 'auto-mode-alist '("\\.ebi\\'" . lisp-mode))

;;; Packages that don't require configuration (lazy loaded)
(use-package scala-mode)
(use-package d-mode)
(use-package yaml-mode)
(use-package glsl-mode)
(use-package tuareg)
(use-package lua-mode)
(use-package less-css-mode)
(use-package graphviz-dot-mode)
(use-package clojure-mode)
(use-package cmake-mode)
(use-package rust-mode)
(use-package csharp-mode)
(use-package nim-mode)
(use-package jinja2-mode)
(use-package markdown-mode)
(use-package purescript-mode)
(use-package nix-mode)
(use-package dockerfile-mode)
(use-package toml-mode)
(use-package nginx-mode)
(use-package kotlin-mode)
(use-package go-mode)
(use-package php-mode)
(use-package racket-mode)
(use-package qml-mode)
(use-package ag)
(use-package elpy)
(use-package rfc-mode)
(use-package sml-mode)

(load "~/.emacs.shadow/shadow-rc.el" t)

(defun astyle-buffer (&optional justify)
  (interactive)
  (let ((saved-line-number (line-number-at-pos)))
    (shell-command-on-region
     (point-min)
     (point-max)
     "astyle --style=kr"
     nil
     t)
    (goto-line saved-line-number)))

(add-hook 'simpc-mode-hook
          (lambda ()
            (interactive)
            (setq-local fill-paragraph-function 'astyle-buffer)))

(require 'compile)

;; pascalik.pas(24,44) Error: Can't evaluate constant expression

compilation-error-regexp-alist-alist

(add-to-list 'compilation-error-regexp-alist
             '("\\([a-zA-Z0-9\\.]+\\)(\\([0-9]+\\)\\(,\\([0-9]+\\)\\)?) \\(Warning:\\)?"
               1 2 (4) (5)))

(load-file custom-file)

;; Reset GC threshold after startup
(add-hook 'emacs-startup-hook
          (lambda ()
            (setq gc-cons-threshold (* 2 1000 1000))))
