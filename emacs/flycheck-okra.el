;;; flycheck-okra.el --- Flycheck support for Okra linting -*- lexical-binding: t; -*-
;;
;; Version: 0.1
;; Homepage: https://github.com/tarides/okra
;; Package-Requires: ((emacs "24.3"))
;;
;; This file is not part of GNU Emacs.
;;
;;; Commentary:
;;
;;  Flycheck support for Okra linting
;;
;;; Code:

(require 'flycheck)

(flycheck-def-executable-var okra "okra")

(defcustom flycheck-okra-admin-repo nil
  "Directory path where okra checker should be active."
  :type 'directory
  :group 'markdown)

(flycheck-define-checker okra
  "A markdown syntax checker using the okra tool."
  :command ("okra" "lint" "--engineer"
            (eval
             (when flycheck-okra-admin-repo
               (format "--work-item-db=%s"
                       (expand-file-name "data/db.csv"
                                         flycheck-okra-admin-repo))))
            (eval
             (when flycheck-okra-admin-repo
               (format "--objective-db=%s"
                       (expand-file-name "data/team-objectives.csv"
                                         flycheck-okra-admin-repo))))
            source)
  :error-patterns
  ((error line-start "File \"" (file-name) "\", line " line ":\nError: " (message)))
  :modes (markdown-mode gfm-mode)
  :predicate (lambda ()
               (or (not flycheck-okra-admin-repo)
                   (string-prefix-p
                    (expand-file-name "weekly" flycheck-okra-admin-repo)
                    (file-name-directory (buffer-file-name))))))

(add-to-list 'flycheck-checkers 'okra)

(provide 'flycheck-okra)
;;; flycheck-okra.el ends here
