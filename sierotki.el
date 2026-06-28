;;; sierotki.el --- Insert non-breakable space after short words on the fly -*- lexical-binding: t; -*-
;;
;; Copyright (C) 1999-2026 Michał Jankowski, Jakub Narębski, et al.
;;
;; Filename:   sierotki.el
;; Description: Insert non-breakable space after short words on the fly
;; Keywords:    TeX, wp, convenience
;;
;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;;; Commentary:
;;
;; This package automatically inserts a non-breakable space (tilde `~`)
;; after specified short words (like prepositions) in TeX modes. This
;; prevents them from being left as orphans at the end of a line.
;;
;; It provides two features:
;; 1. Batch replacement in existing text via `tex-hard-spaces`.
;; 2. On-the-fly replacement via `tex-magic-space-mode`.
;;
;; Setup in init.el:
;;   (require 'sierotki)
;;   (turn-on-tex-magic-space-in-tex-modes)
;;
;; Optionally also:
;; (with-eval-after-load 'sierotki
;;   (setq tex-magic-space-regexp
;;         (concat
;;          "\\<"
;;          (regexp-opt '("0" "1" "2" "3" "4" "5" "6" "7" "8" "9"
;;                        "10" "11" "12" "13" "14" "15" "16" "17" "18" "19"
;;                        "20" "21" "22" "23" "24" "25" "26" "27" "28" "29"
;;                        "30" "31" "32" "33" "34" "35" "36" "37" "38" "39"
;;                        "40" "41" "42" "43" "44" "45" "46" "47" "48" "49"
;;                        "50" "51" "52" "53" "54" "55" "56" "57" "58" "59"
;;                        "60" "61" "62" "63" "64" "65" "66" "67" "68" "69"
;;                        "70" "71" "72" "73" "74" "75" "76" "77" "78" "79"
;;                        "80" "81" "82" "83" "84" "85" "86" "87" "88" "89"
;;                        "90" "91" "92" "93" "94" "95" "96" "97" "98" "99"
;;                        "II" "III" "IV" "V" "VI" "VII" "VIII" "IX" "X"
;;                        "XI" "XII" "XIII" "XIV" "XV"
;;                        "XVI" "XVII" "XVIII" "XIX" "XX"
;;                        "a" "e" "i" "o" "u" "w" "z"
;;                        "A" "E" "I" "O" "U" "W" "Z"
;;                        "Aż" "aż" "Bo" "bo" "Co" "co" "Do" "do"
;;                        "Iż" "iż" "Ku" "ku" "Na" "na" "Ni" "ni"
;;                        "Od" "od" "Po" "po" "Ta" "ta" "Tą" "tą"
;;                        "Te" "te" "Tę" "tę" "To" "to" "We" "we"
;;                        "Za" "za" "Ze" "ze" "Że" "że")
;;                      t))))

;; To prevent line breaks after single-letter words or after
;; `tex-magic-space-regexp` during filling (`fill-paragraph` or
;; `auto-fill-mode`), add one of the following lines to your init.el
;; after (require 'sierotki):
;;
;;    (setq fill-nobreak-predicate 'fill-single-letter-word-nobreak-p)
;; or
;;    (setq fill-nobreak-predicate 'fill-tex-magic-space-nobreak-p)

;;; Code:

(require 'cl-lib)

(defgroup sierotki nil
  "Support for non-breakable spaces after short words."
  :tag "TeX Magic Space"
  :group 'tex)

;;; ======================================================================
;;; Hard spaces (Batch processing)

(defun tex-hard-spaces ()
  "Replace whitespace characters after short words with `~'.
Replaces whitespace characters following conjunctions by the TeX
non-breakable space in the whole buffer, interactively.

Uses `tex-magic-space-regexp' for word detection."
  (interactive)
  (let ((regexp (concat tex-magic-space-regexp "\\s-+"))
        (case-fold-search nil))
    (query-replace-regexp regexp "\\1~")))

;;; ======================================================================
;;; On-the-fly insertion (Magic Space)

(defun sierotki--texinverbp ()
  "Determine if point is inside a LaTeX \\verb command.
Returns nil or the position where \\verb argument begins."
  (let ((point (point))
        beg end delim)
    (save-excursion
      (and (setq beg (and (re-search-backward "\\\\verb\\*?\\([^a-zA-Z*\\n]\\)"
                                              (line-beginning-position) t)
                          (match-end 0)))
           (setq delim (regexp-quote (match-string 1)))
           (goto-char beg)
           (setq end (and (skip-chars-forward (concat "^" delim)
                                              (line-end-position))
                          (point)))
           (or (eolp)
               (looking-at (concat "[" delim "]")))
           (cond ((>= point end) nil)
                 ((eolp) beg)
                 (t (cons beg end)))))))

(defcustom tex-magic-space-do-checking nil
  "Non-nil if `tex-magic-space' should run checks from `tex-magic-space-tests'."
  :type 'boolean
  :group 'sierotki)

(defcustom tex-magic-space-tests
  '(sierotki--texinverbp
    texmathp)
  "List of test functions for `tex-magic-space'.
If any of these functions return non-nil, the magic space insertion
is inhibited. Tests are run only if `tex-magic-space-do-checking' is t."
  :type '(repeat function)
  :group 'sierotki)

(defcustom tex-magic-space-regexp "\\<\\([aiouwzAIOUWZ]\\)"
  "Regular expression detecting short words for `tex-magic-space'.

To add more words, it is recommended to use `regexp-opt'.
Example:
(setq tex-magic-space-regexp
      (concat \"\\\\<\"
              (regexp-opt '(\"A\" \"a\" \"I\" \"i\" \"O\" \"o\"
                            \"U\" \"u\" \"W\" \"w\" \"Z\" \"z\"
                            \"Do\" \"do\" \"Ku\" \"ku\" \"Na\" \"na\"
                            \"We\" \"we\" \"Za\" \"za\" \"Ze\" \"ze\") t)))"
  :type 'regexp
  :group 'sierotki)

(defun tex-magic-space-p ()
  "Return non-nil if a non-breakable space should be inserted."
  (save-match-data
    (let ((case-fold-search nil))
      (looking-back tex-magic-space-regexp (line-beginning-position)))))

(defun tex-magic-space (&optional prefix)
  "Insert non-breakable space after a short word.
Interactively, PREFIX is the prefix arg. Uses `tex-magic-space-regexp'
for word detection. If testing is enabled, respects `tex-magic-space-tests'."
  (interactive "p")
  (unless (and tex-magic-space-do-checking
               (cl-some (lambda (f) (and (fboundp f) (funcall f)))
                        tex-magic-space-tests))
    (when (tex-magic-space-p)
      (setq last-command-event ?~)))
  (self-insert-command (or prefix 1)))

(defun debug-tex-magic-space (&optional prefix)
  "Version of `tex-magic-space' that skips all tests."
  (interactive "p")
  (let ((tex-magic-space-do-checking nil))
    (tex-magic-space prefix)))

;;; ======================================================================
;;; Fill predicates

(defun fill-single-letter-word-nobreak-p ()
  "Don't break a line after a single letter word.
Used in `fill-nobreak-predicate'."
  (save-excursion
    (skip-chars-backward " \t")
    (unless (bolp)
      (backward-char 1)
      (and (memq (preceding-char) '(?\t ?\s))
           (eq (char-syntax (following-char)) ?w)))))

(defun fill-tex-magic-space-nobreak-p ()
  "Don't break a line where `tex-magic-space' would insert a tilde.
Used in `fill-nobreak-predicate'."
  (save-excursion
    (skip-chars-backward " \t")
    (unless (bolp)
      (tex-magic-space-p))))

;;; ======================================================================
;;; Minor Mode Definition

(defun tex-magic-space-toggle-checking (&optional arg)
  "Toggle whether `tex-magic-space' runs `tex-magic-space-tests'.
With prefix argument ARG, turn on checking if positive, otherwise off."
  (interactive "P")
  (setq tex-magic-space-do-checking
        (if (null arg)
            (not tex-magic-space-do-checking)
          (> (prefix-numeric-value arg) 0)))
  (if tex-magic-space-mode
      (force-mode-line-update)
    (message "Tests for tex-magic-space are now %s."
             (if tex-magic-space-do-checking "active" "inactive"))))

;;;###autoload
(define-minor-mode tex-magic-space-mode
  "Toggle TeX Magic Space mode.

In this mode, typing a space inserts a tilde (TeX non-breakable space)
after short words defined by `tex-magic-space-regexp', unless inhibited
by conditions in `tex-magic-space-tests'.

You can toggle checks using `\\[tex-magic-space-toggle-checking]'."
  :init-value nil
  :lighter (" ~" (tex-magic-space-do-checking ":Chk"))
  :keymap `(([?\s] . tex-magic-space)
            ([(control c) (control space)] . tex-magic-space-toggle-checking))
  :group 'sierotki)

;;;###autoload
(defun turn-on-tex-magic-space-mode ()
  "Turn on TeX Magic Space mode."
  (tex-magic-space-mode 1))

;;; ======================================================================
;;; Initialization

(define-key mode-specific-map " " #'tex-magic-space-mode)

(defvar tex-magic-space-mode-hooks-list
  '(TeX-mode-hook
    LaTeX-mode-hook
    tex-mode-hook
    latex-mode-hook
    plain-tex-mode-hook
    reftex-mode-hook
    bibtex-mode-hook)
  "List of hooks to automatically enable `tex-magic-space-mode'.")

;;;###autoload
(defun turn-on-tex-magic-space-in-tex-modes ()
  "Turn on TeX Magic Space mode automatically in known TeX modes."
  (dolist (hook tex-magic-space-mode-hooks-list)
    (add-hook hook #'turn-on-tex-magic-space-mode)))

(provide 'sierotki)

;; Local Variables:
;; coding: utf-8
;; End:
;;; sierotki.el ends here
