# Emacs integration

`okra lint` can be used as a [flycheck] syntax checker. When this is set up,
`okra lint` errors are displayed when flycheck runs in the markdown buffer.

## Installation

`okra` installation copies the Emacs lisp code for the flycheck checker to the
opam switch's share directory. You can add that directory to your Emacs
load-path and `require` the checker.

```emacs-lisp
(add-to-list 'load-path "/home/<user>/.opam/<switch>/share/emacs/site-lisp")
(require 'flycheck-okra)
```

If you have a local clone of this repository, you can add the `emacs/`
directory in it, to your `load-path`.

## Setup

By default, the `okra` checker would get enabled in all markdown buffers. To
enable it only for the weeklies, set the `flycheck-okra-admin-repo` variable to
point at the Tarides `admin` (weeklies) repository

```emacs-lisp
(setq flycheck-okra-admin-repo "/home/<user>/code/tarides/admin")
```

### Optional 

If your `okra` executable is in your Emacs `exec-path`, the checker will be
able to automatically run the `okra` command. You could use [opam-switch-mode]
or [emacs-direnv] to add the appropriate switch to the `exec-path`, for
instance. Alternatively, you can also set the `flycheck-okra-executable`
variable to point to your `okra` binary.

```emacs-lisp
(setq flycheck-okra-executable "/home/<user>/.opam/<switch>/bin/okra")
```

## Usage

Ensure `flycheck-mode` is enabled in your weeklies' markdown buffers. You can either enable it globally, if you use it for your code buffers too, or enable it for your markdown buffers alone. 

```emacs-lisp
(add-hook 'markdown-mode-hook 'flycheck-mode)
;; (global-flycheck-mode 1)
```

The checker will automatically run on your weekly buffer as you edit the buffer. 

[flycheck]: https://www.flycheck.org/en/latest/index.html
[opam-switch-mode]: https://github.com/ProofGeneral/opam-switch-mode
[emacs-direnv]: https://github.com/wbolster/emacs-direnv
