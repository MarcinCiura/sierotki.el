# sierotki.el

## Overview

`sierotki.el` automatically inserts a TeX non-breakable space (tilde
`~`) after specified short words (like prepositions) in (La)TeX modes.
This prevents them from being left as orphans at the end of a line,
adhering to Polish and Czech typography rules.

## Features

* **On-the-fly insertion:** Automatically inserts `~` instead of
    a space when typing after a defined short word.
* **Batch processing:** Replaces spaces with `~` after short words in
    existing text.
* **Paragraph filling support:** Prevents line breaks after short
    words during `fill-paragraph` (`M-q`) or in `auto-fill-mode`.

## Setup

To enable the package automatically in all standard TeX modes, add the
following to your `init.el`:

```elisp
(require 'sierotki)
(turn-on-tex-magic-space-in-tex-modes)

```

## Usage

When `tex-magic-space-mode` is active:

* **`SPC`**: Inserts a tilde (`~`) if following a short word,
    otherwise inserts a standard space.
* **`C-q SPC`**: Forces a standard literal space where a tilde would
    normally be inserted.
* **`M-x tex-hard-spaces`**: Batch replaces spaces after short words
    in the current buffer.
* **`C-c SPC`**: Toggles `tex-magic-space-mode` on or off.
* **`C-c C-SPC`**: Toggles context checking (`tex-magic-space-tests`).

**Modeline indicators:**

* ` ~`: TeX Magic Space mode is active.
* ` ~:Chk`: Context tests (like checking for math/verbatim modes) are
  enabled.

## Configuration

### Customizing Words

By default, the package handles single-letter words. You can override
`tex-magic-space-regexp` using `regexp-opt` to support longer words,
Roman numerals, or numbers.

Add this to your `init.el` to safely define your own dictionary while
preventing double tildes:

```elisp
(with-eval-after-load 'sierotki
  (setq tex-magic-space-regexp
        (concat \\<"
                (regexp-opt '("a" "e" "i" "o" "u" "w" "z"
                              "A" "E" "I" "O" "U" "W" "Z"
                              "do" "ku" "na" "od" "we" "za" "ze"
                              "II" "III" "IV")
                            t)
                )))

```

### Preventing Orphans During Filling

To avoid breaking lines after short words when using Emacs filling
commands, set `fill-nobreak-predicate` in your `init.el`:

```elisp
;; Prevents breaks after single-letter words
(setq fill-nobreak-predicate 'fill-single-letter-word-nobreak-p)

;; OR: Prevents breaks after any word matched by `tex-magic-space-regexp`
(setq fill-nobreak-predicate 'fill-tex-magic-space-nobreak-p)


See also: http://www.emacswiki.org/cgi-bin/wiki/NonbreakableSpace
