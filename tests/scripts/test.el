;;; test.el ---                                      -*- lexical-binding: t; -*-

;;; Commentary:

;;; Code:

(require 'cl-macs)

(message "hello world!")

(cl-assert (native-comp-available-p))
(cl-assert (native-compile '(lambda (x) (* x 2))))

(cl-assert (executable-find "emacsclient"))
(cl-assert (executable-find "emacs"))
(cl-assert (executable-find "hexl"))

(cl-assert (file-exists-p (file-name-concat doc-directory "NEWS")))
(cl-assert (file-exists-p (file-name-concat data-directory "charsets/GBK.map")))

