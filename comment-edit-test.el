;;; comment-edit-test.el --- Test comment-edit -*- lexical-binding: t; -*-

;; Copyright (C) 2019 Gong Qijian <gongqijian@gmail.com>

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Code:

(require 'ert)
;; (setq ert-batch-backtrace-right-margin nil)

(require 'comment-edit)
;; (comment-edit-toggle-debug t)

(when noninteractive
  (transient-mark-mode))

;;; Function test

(ert-deftest comment-edit-test-comment-starter-regexp-el ()
  (mapc
   (lambda (it)
     (should
      (equal (cdr it)
             (replace-regexp-in-string
              (comment-edit--comment-starter-regexp 'emacs-lisp-mode) "" (car it)))))
   '((";foo"     . "foo")
     ("; foo"    . "foo")
     (";  foo"   . " foo")
     
     (";;foo"    . "foo")
     (";; foo"   . "foo")
     (";;  foo"  . " foo")
     
     (";;;foo"   . "foo")
     (";;; foo"  . "foo")
     (";;;  foo" . " foo"))))

(ert-deftest comment-edit-test-comment-starter-regexp-py ()
  (mapc
   (lambda (it)
     (should
      (equal (cdr it)
             (replace-regexp-in-string
              (comment-edit--comment-starter-regexp 'python-mode) "" (car it)))))
   '(("#foo"     . "foo")
     ("# foo"    . "foo")
     ("#  foo"   . " foo")
     
     ("##foo"    . "foo")
     ("## foo"   . "foo")
     ("##  foo"  . " foo")
     
     ("###foo"   . "foo")
     ("### foo"  . "foo")
     ("###  foo" . " foo"))))

(ert-deftest comment-edit-test-comment-starter-regexp-c1 ()
  (mapc
   (lambda (it)
     (should
      (equal (cdr it)
             (replace-regexp-in-string
              (comment-edit--comment-starter-regexp 'c-mode) "" (car it)))))
   '(("*foo"     . "foo")
     ("* foo"    . "foo")
     ("*  foo"   . " foo")

     ("**foo"    . "foo")
     ("** foo"   . "foo")
     ("**  foo"  . " foo")

     ("***foo"   . "foo")
     ("*** foo"  . "foo")
     ("***  foo" . " foo"))))

(ert-deftest comment-edit-test-comment-starter-regexp-c2 ()
  (mapc
   (lambda (it)
     (should
      (equal (cdr it)
             (replace-regexp-in-string
              (comment-edit--comment-starter-regexp 'c-mode) "" (car it)))))
   '(("/foo"     . "/foo")
     ("/ foo"    . "/ foo")
     ("/  foo"   . "/  foo")

     ("//foo"    . "foo")
     ("// foo"   . "foo")
     ("//  foo"  . " foo")

     ("///foo"   . "foo")
     ("/// foo"  . "foo")
     ("///  foo" . " foo"))))

(ert-deftest comment-edit-test-string-region ()
  (let* ((content-string (format "%S" "string `symbol'\n#ffffff\n(function \"arg\")"))
         (expected-string (substring content-string 1 (1- (length content-string)))))
    (should (string= expected-string
                     (comment-edit-test--with-buffer-el
                      content-string
                      (apply #'buffer-substring-no-properties (comment-edit--string-region 20)))))
    (should (string= expected-string
                     (comment-edit-test--with-buffer-el
                      (concat "(" content-string ")")
                      (apply #'buffer-substring-no-properties (comment-edit--string-region 20)))))
    (should (string= expected-string
                     (comment-edit-test--with-buffer-el
                      (concat "(foo " content-string ")")
                      (apply #'buffer-substring-no-properties (comment-edit--string-region 20)))))
    (should (string= expected-string
                     (comment-edit-test--with-buffer-el
                      (concat "(defun foo () " content-string ")")
                      (apply #'buffer-substring-no-properties (comment-edit--string-region 20)))))
    (should (string= expected-string
                     (comment-edit-test--with-buffer-el
                      (concat "(defun foo () " content-string ")\n(foo)")
                      (apply #'buffer-substring-no-properties (comment-edit--string-region 20)))))))

;;; Interaction test

(ert-deftest comment-edit-test-el-in-el ()
  (let ((code-with-comment
         (comment-edit-test--indent-el
          "(defun sum (&rest nums)
             (funcall '+ nums))
           ;; ```elisp
           ;; (sum '(1 2 3)) ;; <|>
           ;; ;; => 6
           ;;```"))
        (code-in-editing
         (comment-edit-test--indent-el
          "(sum '(1 2 3)) ;; <|>
           ;; => 6")))
    (comment-edit-test--execute-block-edit 'emacs-lisp-mode ""           code-with-comment code-in-editing)
    (comment-edit-test--execute-block-edit 'emacs-lisp-mode "C-c '"      code-with-comment code-with-comment)
    (comment-edit-test--execute-block-edit 'emacs-lisp-mode "aaa C-c '"  code-with-comment (comment-edit-test--append-to-code-block
                                                                                           'emacs-lisp-mode code-with-comment "aaa"))))

(ert-deftest comment-edit-test-py-in-py ()
  (let ((code-with-comment
         (comment-edit-test--indent-py
          "def sum(*nums):
               sum = 0
               for n in nums:
                   sum = sum + n
               return sum
           # ```python
           # sum(1, 2, 3) # <|>
           # # => 6
           # ```"))
        (code-in-comment
         (comment-edit-test--indent-py
          "sum(1, 2, 3) # <|>
           # => 6")))
    (comment-edit-test--execute-block-edit 'python-mode ""          code-with-comment code-in-comment)
    (comment-edit-test--execute-block-edit 'python-mode "C-c '"     code-with-comment code-with-comment)
    (comment-edit-test--execute-block-edit 'python-mode "aaa C-c '" code-with-comment (comment-edit-test--append-to-code-block
                                                                                       'python-mode code-with-comment "aaa"))))

(ert-deftest comment-edit-test-rb-in-rb ()
  (let ((code-with-comment
         (comment-edit-test--indent-rb
          "def sum(*nums):
             nums.inject(0) {|sum,x| sum + x }
           # ```ruby
           # sum 1, 2, 3 # <|>
           # # => 6
           # ```"))
        (code-in-comment
         (comment-edit-test--indent-sh
          "sum 1, 2, 3 # <|>
           # => 6")))
    (comment-edit-test--execute-block-edit 'ruby-mode ""          code-with-comment code-in-comment)
    (comment-edit-test--execute-block-edit 'ruby-mode "C-c '"     code-with-comment code-with-comment)
    (comment-edit-test--execute-block-edit 'ruby-mode "aaa C-c '" code-with-comment (comment-edit-test--append-to-code-block
                                                                                       'ruby-mode code-with-comment "aaa"))))

(ert-deftest comment-edit-test-sh-in-c1 ()
  (let ((code-with-comment
         (comment-edit-test--indent-c
          "int main()
           {
             printf(\"Hellow, world!\");
             return 0;
           }
           /*
            * ```sh
            * # build <|>
            * make -k
            * ```
            */"))
        (code-in-comment
         (comment-edit-test--indent-sh
          "# build <|>
           make -k")))
    (comment-edit-test--execute-block-edit 'c-mode ""           code-with-comment code-in-comment)
    (comment-edit-test--execute-block-edit 'c-mode "C-c '"      code-with-comment code-with-comment)
    (comment-edit-test--execute-block-edit 'c-mode "aaa C-c '"  code-with-comment (comment-edit-test--append-to-code-block
                                                                                  'c-mode code-with-comment "aaa"))))

(ert-deftest comment-edit-test-sh-in-c2 ()
  (let ((code-with-comment
         (comment-edit-test--indent-c
          "int main()
           {
             printf(\"Hellow, world!\");
             return 0;
           }
           //
           // ```sh
           // # build <|>
           // make -k
           // ```
           //"))
        (code-in-comment
         (comment-edit-test--indent-sh
          "# build <|>
           make -k")))
    (comment-edit-test--execute-block-edit 'c-mode ""           code-with-comment code-in-comment)
    (comment-edit-test--execute-block-edit 'c-mode "C-c '"      code-with-comment code-with-comment)
    (comment-edit-test--execute-block-edit 'c-mode "aaa C-c '"  code-with-comment (comment-edit-test--append-to-code-block
                                                                                  'c-mode code-with-comment "aaa"))))

(ert-deftest comment-edit-test-code-in-doc-1 ()
  (let ((init-data "(defun hello (name)
  \"Greet a person.

Usage:

    ```elisp
    (hello \\\"foo\\\") ;; <|>
    ```\"
  (message \"hello, %s\" name))")
        (code-in-doc "(hello \"foo\") ;; <|>"))
    (comment-edit-test--execute-block-edit 'emacs-lisp-mode ""       init-data code-in-doc)
    (comment-edit-test--execute-block-edit 'emacs-lisp-mode "C-c '"  init-data init-data)
    (comment-edit-test--execute-block-edit 'emacs-lisp-mode "M-> aaa C-c '"  init-data (comment-edit-test--append-to-code-block
                                                                                           'emacs-lisp-mode init-data "aaa"))))

(ert-deftest comment-edit-test-code-in-doc-2 ()
  (let ((init-data "(defun hello (name)
  \"Greet a person.

Usage:

    ,---elisp
    | (hello \\\"foo\\\") ;; <|>
    `---\"
  (message \"hello, %s\" name))")
        (code-in-doc "(hello \"foo\") ;; <|>"))
    (comment-edit-test--execute-block-edit 'emacs-lisp-mode ""       init-data code-in-doc)
    (comment-edit-test--execute-block-edit 'emacs-lisp-mode "C-c '"  init-data init-data)
    (comment-edit-test--execute-block-edit 'emacs-lisp-mode "M-> aaa C-c '"  init-data (comment-edit-test--append-to-code-block
                                                                                           'emacs-lisp-mode init-data "aaa"))))

(ert-deftest comment-edit-test-code-in-doc-3 ()
  (let ((init-data "(defun hello (name)
  \"Greet a person.

Usage:<|>

    ```elisp
    (hello \\\"foo\\\")
    ```\"
  (message \"hello, %s\" name))")
        (code-in-doc "Greet a person.

Usage:<|>

    ```elisp
    (hello \"foo\")
    ```"))
    (comment-edit-test--execute-block-edit 'emacs-lisp-mode ""       init-data code-in-doc)
    (comment-edit-test--execute-block-edit 'emacs-lisp-mode "C-c '"  init-data init-data)
    (comment-edit-test--execute-block-edit 'emacs-lisp-mode "M-> aaa C-c '"  init-data (comment-edit-test--append-to-code-block
                                                                                       'emacs-lisp-mode init-data "aaa"))))

(provide 'comment-edit-test)

;;; comment-edit-test.el ends here
