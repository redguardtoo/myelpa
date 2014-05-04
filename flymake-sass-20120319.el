;;; flymake-sass.el --- Flymake handler for sass files
;;
;;; Author: Steve Purcell <steve@sanityinc.com>
;;; URL: https://github.com/purcell/flymake-sass
;;; Version: DEV
;;
;;; Commentary:
;;
;; Usage:
;;   (require 'flymake-sass)
;;   (add-hook 'sass-mode-hook 'flymake-sass-load)
(require 'flymake)

;;; Code:

(defconst flymake-sass-err-line-patterns
  '(("^Syntax error on line \\([0-9]+\\): \\(.*\\)$" nil 1 nil 2)
    ("^WARNING on line \\([0-9]+\\) of .*?:\r?\n\\(.*\\)$" nil 1 nil 2)
    ("^Syntax error: \\(.*\\)\r?\n        on line \\([0-9]+\\) of .*?$" nil 2 nil 1) ;; Older sass versions
    ))

(defun flymake-sass--create-temp-in-system-tempdir (file-name prefix)
  "Return a temporary file name into which flymake can save buffer contents.

This is tidier than `flymake-create-temp-inplace', and therefore
preferable when the checking doesn't depend on the file's exact
location."
  (make-temp-file (or prefix "flymake-sass") nil ".sass"))

;; Invoke utilities with '-c' to get syntax checking
(defun flymake-sass-init ()
  "Construct a command that flymake can use to check sass source."
  (list "sass" (list "-c" (flymake-init-create-temp-buffer-copy
                           'flymake-sass--create-temp-in-system-tempdir))))

;; SASS error output is multiline, and in irregular formats, so we have to hack
;; flymake-split-output. The hack is activated in `flymake-sass-load', and is
;; buffer-local

(defun flymake-sass-just-find-all-matches (str &optional ignored)
  "A judicious override for `flymake-split-output'.

Enabled by the advice below, this override just returns all
output lines matching any of the error line patterns.

Argument STR a multi-line string containing output from 'sass -c'."
  (let ((result nil))
    (dolist (pattern flymake-sass-err-line-patterns)
      (let ((regex (car pattern))
            (pos 0))
        (while (string-match regex str pos)
          (push (match-string 0 str) result)
          (setq pos (match-end 0)))))
    result))

(defvar flymake-sass--split-multiline nil
  "Whether flymake's output splitting is to be hacked; do not set this directly.")
;; Force flymake to find multiline matches
;; See http://www.emacswiki.org/emacs/flymake-extension.el

(defadvice flymake-split-output
  (around flymake-sass-split-output-multiline (output) activate protect)
  "Override `flymake-split-output' to support mult-line error messages."
  (if flymake-sass--split-multiline
    (setq ad-return-value (list (flymake-sass-just-find-all-matches output) nil))
    ad-do-it))

;;;###autoload
(defun flymake-sass-load ()
  "Configure flymake mode to check the current buffer's sass syntax.

This function is designed to be called in `sass-mode-hook'; it
does not alter flymake's global configuration, so function
`flymake-mode' alone will not suffice."
  (interactive)
  (set (make-local-variable 'flymake-allowed-file-name-masks) '(("." flymake-sass-init)))
  (set (make-local-variable 'flymake-err-line-patterns) flymake-sass-err-line-patterns)
  (set (make-local-variable 'flymake-sass--split-multiline) t)
  (if (executable-find "sass")
      (flymake-mode t)
    (message "Not enabling flymake: sass command not found")))


(defadvice flymake-post-syntax-check (before flymake-force-check-was-interrupted)
  (setq flymake-check-was-interrupted t))
(ad-activate 'flymake-post-syntax-check)


(provide 'flymake-sass)
;;; flymake-sass.el ends here
