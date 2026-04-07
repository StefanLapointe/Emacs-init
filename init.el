;;; init.el --- Stefan's Emacs init file

;; This init file is aimed to facilitate software development and to
;; enhance the appearance of Emacs while avoiding unnecessary
;; deviations from built-in functionality.

;;; Emacs behaviour

;; Necessary for ewal live reload script in i3 config
(setq server-name (format "server-%d" (emacs-pid)))
(server-start)

;; No more backup files
(setq make-backup-files nil)

;; No more tabs
(setq indent-tabs-mode nil)

;;; MELPA

;; (require 'package)
(add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/") t)
;; (package-initialize)

;;; Completion

;;;; Minibuffer completion

(use-package vertico
  :ensure t
  :init
  (vertico-mode))

(use-package marginalia
  :ensure t
  :init
  (marginalia-mode))

;; I don't fully understand this configuration but it was suggested in the manual.
(use-package orderless
  :ensure t
  :custom
  (completion-styles '(orderless basic))
  (completion-category-overrides '((file (styles partial-completion))))
  (completion-pcm-leading-wildcard t))

;;;; In-buffer completion

;; TODO: Add corfu stuff

;;; Software development

(use-package treesit-auto
  :ensure t
  :config
  (treesit-auto-add-to-auto-mode-alist 'all)
  (global-treesit-auto-mode))

(use-package project
  :config
  ;; It is important to set this variable even though it interferes
  ;; with the behaviour of project.el commands because otherwise Eglot
  ;; will assign language servers to multiple projects instead of just
  ;; one when it is used on a monorepo, which could lead to unwanted
  ;; interference between separate codebases, or even cause language
  ;; servers to be unable to find their corresponding project roots.
  (setq project-vc-extra-root-markers '("settings.gradle.kts"
					 "package.json"
					 "pyproject.toml")))

(use-package eglot
  :after project
  :init
  (defun my/angular-p ()
    (locate-dominating-file default-directory "angular.json"))
  (defun my/probe-locations ()
    (expand-file-name "@angular/language-server" (string-trim (shell-command-to-string "npm root -g"))))
  (define-derived-mode my/ng-typescript-mode
    typescript-ts-mode "Angular/TypeScript"
    "Major mode for editing Angular TypeScript")
  ;; TODO: Replace html-ts-mode with web-mode
  (define-derived-mode my/ng-html-mode
    html-ts-mode "Angular/HTML"
    "Major mode for editing Angular HTML")
  :config
  ;; Angular-specific configuration with custom modes
  (add-to-list 'eglot-server-programs
               '((typescript-mode typescript-ts-mode) . ("typescript-language-server" "--stdio")))
  (add-to-list 'eglot-server-programs
               `(((my/ng-typescript-mode :language-id "typescript") (my/ng-html-mode :language-id "html"))
		 . ("rass"
		    "--"
		    "ngserver"
		    ;; TODO: Stop evaluating at config time
		    "--tsProbeLocations" ,(my/probe-locations)
		    "--ngProbeLocations" ,(my/probe-locations)
		    "--stdio"
		    "--"
		    "typescript-language-server"
		    "--stdio")))
  ;; Python language server multiplexing with rassumfrassum
  (add-to-list 'eglot-server-programs
               '((python-mode python-ts-mode) . ("rass" "python")))
  :hook
  (typescript-ts-mode . eglot-ensure)
  ;; TODO: Fix the hook system
  ;; It is important that this hook is added after the eglot-ensure hook so that this one runs first.
  ;; Actually I'm not sure... Maybe it runs twice anyway and maybe eglot-ensure is idempotent anyway.
  (typescript-ts-mode . (lambda ()
                          (if (and (my/angular-p)
                                   (not (derived-mode-p 'my/ng-typescript-mode)))
                              (my/ng-typescript-mode))))
  (my/ng-typescript-mode . eglot-ensure)
  (html-ts-mode . (lambda ()
                          (if (and (my/angular-p)
                                   (not (derived-mode-p 'my/ng-html-mode)))
                              (my/ng-html-mode))))
  (my/ng-html-mode . eglot-ensure)
  (python-ts-mode . eglot-ensure))

(use-package eglot-java
  :ensure t
  :hook (java-ts-mode . eglot-java-mode))

;;; Org mode

;; These keybindings were suggested in the Org manual.
(global-set-key (kbd "C-c l") #'org-store-link)
(global-set-key (kbd "C-c a") #'org-agenda)
(global-set-key (kbd "C-c c") #'org-capture)

;;; Appearance

(menu-bar-mode -1)
(tool-bar-mode -1)
(scroll-bar-mode -1)

(use-package ewal
  :ensure t
  :init (setq ewal-use-built-in-always-p nil
              ewal-use-built-in-on-failure-p t
              ewal-built-in-palette "sexy-material"))

(use-package ewal-doom-themes
  :ensure t
  :demand
  :config
  (load-theme 'ewal-doom-vibrant t))

;; Make the background transparent.
(set-frame-parameter nil 'alpha-background 80)
(add-to-list 'default-frame-alist '(alpha-background . 80))

;;; Convenience

(use-package eat
  :ensure t)

(use-package magit
  :ensure t)

;;; Custom file

(setq custom-file (expand-file-name "custom.el" user-emacs-directory))
(load custom-file)

;;; init.el ends here
