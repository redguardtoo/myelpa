;;; flymake-haml.el --- Flymake handler for haml files
;;
;;; Author: Steve Purcell <steve@sanityinc.com>
;;; URL: https://github.com/purcell/flymake-haml
;;; Version: DEV
;;
;;; Commentary:
;;
;; Usage:
;;   (require 'flymake-haml)
;;   (add-hook 'haml-mode-hook 'flymake-haml-load)
(require 'flymake)

;;; Code:

(defvar flymake-haml-err-line-patterns '(("^Syntax error on line \\([0-9]+\\): \\(.*\\)$" nil 1 nil 2)))

(defun flymake-haml--create-temp-in-system-tempdir (file-name prefix)
  "Return a temporary file name into which flymake can save buffer contents.

This is tidier than `flymake-create-temp-inplace', and therefore
preferable when the checking doesn't depend on the file's exact
location."
  (make-temp-file (or prefix "flymake-haml") nil ".haml"))

;; Invoke utilities with '-c' to get syntax checking
(defun flymake-haml-init ()
  "Construct a command that flymake can use to check haml source."
  (list "haml" (list "-c" (flymake-init-create-temp-buffer-copy
                           'flymake-haml--create-temp-in-system-tempdir))))

;;;###autoload
(defun flymake-haml-load ()
  "Configure flymake mode to check the current buffer's haml syntax.

This function is designed to be called in `haml-mode-hook'; it
does not alter flymake's global configuration, so function
`flymake-mode' alone will not suffice."
  (interactive)
  (set (make-local-variable 'flymake-allowed-file-name-masks) '(("." flymake-haml-init)))
  (set (make-local-variable 'flymake-err-line-patterns) flymake-haml-err-line-patterns)
  (if (executable-find "haml")
      (flymake-mode t)
    (message "Not enabling flymake: haml command not found")))


(defadvice flymake-post-syntax-check (before flymake-force-check-was-interrupted)
  (setq flymake-check-was-interrupted t))
(ad-activate 'flymake-post-syntax-check)


(provide 'flymake-haml)
;;; flymake-haml.el ends here
