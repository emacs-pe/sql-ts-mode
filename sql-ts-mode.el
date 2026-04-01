;;; sql-ts-mode.el --- Major mode for editing SQL files  -*- lexical-binding: t -*-

;; Copyright (C) 2024 Mario Rodas <marsam@users.noreply.github.com>

;; Author: Mario Rodas <marsam@users.noreply.github.com>
;; URL: https://github.com/emacs-pe/sql-ts-mode
;; Keywords: sql languages tree-sitter
;; Version: 0.1
;; Package-Requires: ((emacs "30.1"))

;; This file is NOT part of GNU Emacs.

;;; License:

;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; This package provides `sql-ts-mode' which is a major mode for SQL
;; files that uses Tree Sitter to parse the language.

;; This package is compatible with and tested against the grammar for
;; SQL found at <https://github.com/DerekStride/tree-sitter-sql>.

;; -------------------------------------------------------------------
;; Israel is committing genocide of the Palestinian people.
;;
;; The population in Gaza is facing starvation, displacement and
;; annihilation amid relentless bombardment and suffocating
;; restrictions on life-saving humanitarian aid.
;;
;; As of March 2025, Israel has killed over 50,000 Palestinians in the
;; Gaza Strip – including 15,600 children – targeting homes,
;; hospitals, schools, and refugee camps.  However, the true death
;; toll in Gaza may be at least around 41% higher than official
;; records suggest.
;;
;; The website <https://databasesforpalestine.org/> records extensive
;; digital evidence of Israel's genocidal acts against Palestinians.
;; Save it to your bookmarks and let more people know about it.
;;
;; Silence is complicity.
;; Protest and boycott the genocidal apartheid state of Israel.
;;
;;
;;                  From the river to the sea, Palestine will be free.
;; -------------------------------------------------------------------

;;; Code:
(require 'treesit)
(require 'sql)

(if (fboundp 'treesit-declare-unavailable-functions) ; Emacs 31.1
    (treesit-declare-unavailable-functions)
  (declare-function treesit-language-available-p "treesit.c")
  (declare-function treesit-node-child "treesit.c")
  (declare-function treesit-node-child-by-field-name "treesit.c")
  (declare-function treesit-node-end "treesit.c")
  (declare-function treesit-node-match-p "treesit.c")
  (declare-function treesit-node-next-sibling "treesit.c")
  (declare-function treesit-node-start "treesit.c")
  (declare-function treesit-node-type "treesit.c")
  (declare-function treesit-parser-create "treesit.c")
  (declare-function treesit-search-subtree "treesit.c"))

(add-to-list
 'treesit-language-source-alist
 '(sql "https://github.com/DerekStride/tree-sitter-sql"
       :commit "7b51ecda191d36b92f5a90a8d1bc3faef1c7b8b8") ; v0.3.11
 t)

(defgroup sql-ts nil
  "Major mode for editing SQL files."
  :prefix "sql-ts-"
  :group 'languages
  :group 'SQL)

(defcustom sql-ts-indent-offset 4
  "Number of spaces for each indentation step in `sql-ts-mode'."
  :type 'natnum
  :safe 'natnump)

(defvar sql-ts--builtins
  '((keyword_int) (keyword_null) (keyword_boolean) (keyword_binary)
    (keyword_varbinary) (keyword_image) (keyword_bit) (keyword_inet)
    (keyword_character) (keyword_smallserial) (keyword_serial)
    (keyword_bigserial) (keyword_smallint) (keyword_mediumint)
    (keyword_bigint) (keyword_tinyint) (keyword_decimal)
    (keyword_float) (keyword_double) (keyword_numeric)
    (keyword_real) (double) (keyword_money) (keyword_smallmoney)
    (keyword_char) (keyword_nchar) (keyword_varchar)
    (keyword_nvarchar) (keyword_varying) (keyword_text)
    (keyword_string) (keyword_uuid) (keyword_json) (keyword_jsonb)
    (keyword_xml) (keyword_bytea) (keyword_enum) (keyword_date)
    (keyword_datetime) (keyword_time) (keyword_datetime2)
    (keyword_datetimeoffset) (keyword_smalldatetime)
    (keyword_timestamp) (keyword_timestamptz) (keyword_geometry)
    (keyword_geography) (keyword_box2d) (keyword_box3d)
    (keyword_interval))
  "SQL built-in types for tree-sitter font-locking.")

(defvar sql-ts--attributes
  '((keyword_asc) (keyword_desc) (keyword_terminated)
    (keyword_escaped) (keyword_unsigned) (keyword_nulls)
    (keyword_last) (keyword_delimited) (keyword_replication)
    (keyword_auto_increment) (keyword_default) (keyword_collate)
    (keyword_concurrently) (keyword_engine) (keyword_always)
    (keyword_generated) (keyword_preceding) (keyword_following)
    (keyword_first) (keyword_current_timestamp) (keyword_immutable)
    (keyword_atomic) (keyword_parallel) (keyword_leakproof)
    (keyword_safe) (keyword_cost) (keyword_strict))
  "SQL attribute keywords for tree-sitter font-locking.")

(defvar sql-ts--operators
  '("+" "-" "*" "/" "%" "^" ":=" "=" "<" "<=" "!=" ">=" ">" "<>"
    (op_other) (op_unary_other)
    ;; Based on https://github.com/DerekStride/tree-sitter-sql/blob/v0.3.11/queries/highlights.scm#L404-L415
    (keyword_in) (keyword_and) (keyword_or) (keyword_not) (keyword_by)
    (keyword_on) (keyword_do) (keyword_union) (keyword_except)
    (keyword_intersect))
  "SQL operator nodes for tree-sitter font-locking.")

(defsubst sql-ts--keyword-node-p (node)
  "Check whether a NODE is a keyword."
  (string-prefix-p "keyword_" (treesit-node-type node)))

(defvar sql-ts--font-lock-settings
  (treesit-font-lock-rules
   :default-language 'sql

   :feature 'comment
   '([(comment) (marginalia)] @font-lock-comment-face)

   :feature 'punctuation
   `((["(" ")"] @font-lock-bracket-face)
     ([";" "," "."] @font-lock-delimiter-face)
     ([,@sql-ts--operators] @font-lock-operator-face))

   :feature 'builtin
   `([,@sql-ts--builtins] @font-lock-builtin-face)

   :feature 'number
   '(((literal) @font-lock-number-face
      (:match "\\`[-+]?[[:digit:]]*\\.?[[:digit:]]+\\(?:[eE][-+]?[[:digit:]]+\\)?\\'" @font-lock-number-face)))

   :feature 'constant
   '([(keyword_true) (keyword_false)] @font-lock-constant-face)

   :feature 'attribute
   `([,@sql-ts--attributes] @font-lock-preprocessor-face)

   :feature 'string
   '((literal) @font-lock-string-face)

   :feature 'function
   '((invocation
      (object_reference name: (identifier) @font-lock-function-call-face))
     (cast name: (keyword_cast) @font-lock-function-call-face)
     [(keyword_gist) (keyword_btree) (keyword_hash) (keyword_spgist)
      (keyword_gin) (keyword_brin) (keyword_array)]
     @font-lock-function-call-face)

   :feature 'type
   '((object_reference name: (identifier) @font-lock-type-face)
     (object_reference schema: (identifier) @font-lock-type-face)
     (cte (identifier) @font-lock-type-face))

   :feature 'property
   '((field name: (identifier) @font-lock-property-use-face)
     (column (identifier) @font-lock-property-use-face)
     (column_definition name: (identifier) @font-lock-property-name-face))

   :feature 'variable
   '((parameter) @font-lock-variable-name-face
     (relation alias: (identifier) @font-lock-variable-name-face)
     (term alias: (identifier) @font-lock-variable-name-face))

   :feature 'error
   :override t
   '((ERROR) @font-lock-warning-face)

   ;; Any keyword_ that did not match the rules above.
   :feature 'keyword
   '(((_) @font-lock-keyword-face
      (:pred sql-ts--keyword-node-p @font-lock-keyword-face))))
  "Tree-sitter font-lock settings for `sql-ts-mode'.")

(defconst sql-ts--indent-body-types
  (regexp-opt '("block" "case" "column_definitions" "constraint" "cte" "from"
                "function_arguments" "group_by" "index_fields" "invocation"
                "join" "list" "order_by" "subquery" "term" "when_clause"
                "where")
              t)
  "Node types whose body indents one step.")

(defvar sql-ts--indent-rules
  `((sql
     ((parent-is "program") column-0 0)
     ((node-is "comment") prev-adaptive-prefix 0)
     ((or (node-is ")")
          (node-is "keyword_end"))
      parent-bol 0)
     ((or (parent-is "window_specification")
          (node-is "assignment")
          (node-is "select_expression")
          (node-is "when_clause")
          (and (parent-is "insert") (node-is "list")))
      parent-bol sql-ts-indent-offset)
     ((node-is "from") prev-sibling 0)
     ((or (node-is "where")
          (node-is "group_by")
          (node-is "order_by")
          (node-is "keyword_having")
          (node-is "join")
          (parent-is "set_operation")
          (parent-is "insert")
          (parent-is "statement")
          (parent-is "transaction")
          (parent-is "update"))
      parent-bol 0)
     ((or (parent-is "select_expression") (parent-is "index_fields"))
      first-sibling 0)
     ((parent-is "constraints") column-0 sql-ts-indent-offset)
     ((n-p-gp nil "binary_expression" ,sql-ts--indent-body-types)
      grand-parent sql-ts-indent-offset)
     ((n-p-gp nil "binary_expression" "binary_expression")
      great-grand-parent sql-ts-indent-offset)
     ,@(when (assq 'prev-line-is treesit-simple-indent-presets) ; `prev-line-is' is available in Emacs 31+
         '(((and (node-is "keyword_then") (prev-line-is "keyword_when"))
            prev-line sql-ts-indent-offset)))
     ((parent-is ,sql-ts--indent-body-types)
      parent-bol sql-ts-indent-offset)))
  "Tree-sitter indent rules for `sql-ts-mode'.")

(defun sql-ts--defun-name (node)
  "Return the defun name of NODE."
  (when-let* (((treesit-node-match-p node 'defun t))
              (kind (treesit-node-child node 0 t)))
    (let ((object
           (or (treesit-node-child-by-field-name kind "column")
               (treesit-node-child-by-field-name kind "name")
               (treesit-node-child-by-field-name node "name")
               (treesit-search-subtree
                node
                (lambda (n)
                  (and (or (treesit-node-match-p n (rx bos "object_reference" eos))
                           (string-equal (treesit-node-field-name n) "alias"))
                       (not (treesit-parent-until n (rx bos (or "select_expression" "subquery" "invocation") eos)))))))))
      (concat (string-replace "_" " " (string-remove-prefix "keyword_" (treesit-node-type kind)))
              (and object (concat " " (treesit-node-text object t)))))))

(defconst sql-ts--statement-regexp (rx bos "statement" eos)
  "Regexp matching the type of a SQL statement node.")

(defun sql-ts--statement-at-or-after (pos)
  "Return the SQL statement at POS, or the next one, or nil."
  (when-let* ((node (or (treesit-thing-at pos 'defun) (treesit-thing-next pos 'defun))))
    (treesit-node-top-level node 'defun t)))

(defun sql-ts--statement-bounds (node)
  "Return the (START . END) of the SQL statement NODE, semicolon included."
  (let ((next (treesit-node-next-sibling node)))
    (cons (treesit-node-start node) (treesit-node-end (if (and next (string-equal (treesit-node-type next) ";")) next node)))))

(defun sql-ts--statement-region ()
  "Return the (START . END) of the statement to send from point."
  (if-let* ((node (sql-ts--statement-at-or-after (point))))
      (sql-ts--statement-bounds node)
    (user-error "No SQL statement at or after point")))

(defun sql-ts-send-statement ()
  "Send the SQL statement at point to the SQLi buffer."
  (interactive nil sql-ts-mode)
  (pcase-let ((`(,start . ,end) (sql-ts--statement-region)))
    (sql-send-region start end)))

(defun sql-ts-send-statement-and-next ()
  "Send the SQL statement at point, then move to the next one."
  (interactive nil sql-ts-mode)
  (pcase-let ((`(,start . ,end) (sql-ts--statement-region)))
    (sql-send-region start end)
    (goto-char end)
    (when-let* ((next (sql-ts--statement-at-or-after end)))
      (goto-char (treesit-node-start next)))))

(defvar-keymap sql-ts-mode-map
  :doc "Keymap for `sql-ts-mode'."
  :parent (make-composed-keymap sql-mode-map prog-mode-map)
  "C-c C-c" #'sql-ts-send-statement
  "C-c C-n" #'sql-ts-send-statement-and-next)

;;;###autoload
(define-derived-mode sql-ts-mode prog-mode "SQL"
  "Major mode for editing SQL, powered by tree-sitter.

\\{sql-ts-mode-map}"
  :abbrev-table sql-mode-abbrev-table

  ;; Taken from `sql-mode'.
  (let ((sql-product (if (assq sql-product sql-product-alist)
                         sql-product
                       'ansi)))
    (set-syntax-table (sql-product-syntax-table)))
  (setq-local comment-start "--")
  (setq-local syntax-propertize-function
              (eval '(syntax-propertize-rules
                      ((if (member sql-product '(mysql mariadb)) "\\\\'" "''")
                       (0 (if (save-excursion
                                (nth 3 (syntax-ppss (match-beginning 0))))
                              (string-to-syntax ".")
                            (forward-char -1)
                            nil)))
                      ("\\(/-\\)" (1 "."))
                      ("\\(-\\*\\)"
                       (1 (if (save-excursion
                                (not (ppss-comment-depth
                                      (syntax-ppss (match-beginning 1)))))
                              (string-to-syntax ".")
                            (forward-char -1)
                            nil))))
                    t))
  (setq-local abbrev-all-caps 1)
  (setq-local escaped-string-quote "'")
  (setq-local sql-contains-names t)
  (make-local-variable 'sql-buffer)

  (when (and (or (not (fboundp 'treesit-ensure-installed)) ; Emacs 31.1
                 (treesit-ensure-installed 'sql))
             (treesit-ready-p 'sql))
    (setq treesit-primary-parser (treesit-parser-create 'sql))

    ;; Indent.
    (setq-local indent-tabs-mode nil)
    (setq-local treesit-simple-indent-rules sql-ts--indent-rules)

    ;; Font-lock.
    (setq-local treesit-font-lock-settings sql-ts--font-lock-settings)
    (setq-local treesit-font-lock-feature-list
                '((comment keyword string)
                  (builtin constant type function attribute property variable number)
                  (punctuation error)))
    ;; Imenu.
    (setq-local treesit-defun-name-function #'sql-ts--defun-name)
    (setq-local treesit-simple-imenu-settings
                `(("Statement" ,sql-ts--statement-regexp nil nil)))
    (setq-local treesit-outline-predicate sql-ts--statement-regexp)

    ;; Navigation.
    (setq-local treesit-thing-settings
                `((sql
                   (defun ,sql-ts--statement-regexp)
                   (list ,(rx bos (or
                                   "list"
                                   "column_definitions"
                                   "index_fields"
                                   "function_arguments"
                                   "subquery")
                              eos))
                   (sexp ,(rx bos (or "statement" "select" "insert"
                                      "update" "delete" "cte")
                              eos))
                   (sentence ,(rx bos (or "statement" "transaction") eos))
                   (text ,(rx bos (or "comment" "marginalia" "literal") eos))
                   (comment ,(rx bos (or "comment" "marginalia") eos)))))
    (treesit-major-mode-setup)))

(derived-mode-add-parents 'sql-ts-mode '(sql-mode))

;;;###autoload
(defun sql-ts-mode-maybe ()
  "Enable `sql-ts-mode' when its grammar is available, `sql-mode' otherwise."
  (let ((enabled (bound-and-true-p treesit-enabled-modes))) ; Emacs 31.1
    (if (or (treesit-language-available-p 'sql)
            (eq enabled t)
            (memq 'sql-ts-mode enabled))
        (sql-ts-mode)
      (sql-mode))))

;;;###autoload
(add-to-list 'auto-mode-alist '("\\.sql\\'" . sql-ts-mode-maybe))

;;;###autoload
(if (boundp 'treesit-major-mode-remap-alist)   ; Emacs 31.1
    (add-to-list 'treesit-major-mode-remap-alist '(sql-mode . sql-ts-mode))
  (add-to-list 'major-mode-remap-defaults '(sql-mode . sql-ts-mode)))

(provide 'sql-ts-mode)
;;; sql-ts-mode.el ends here
