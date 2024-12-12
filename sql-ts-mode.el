;;; sql-ts-mode.el --- Major mode for editing SQL files  -*- lexical-binding: t -*-

;; Copyright (C) 2024 Mario Rodas <marsam@users.noreply.github.com>

;; Author: Mario Rodas <marsam@users.noreply.github.com>
;; URL: https://github.com/emacs-pe/sql-ts-mode
;; Keywords: sql languages tree-sitter
;; Version: 0.1
;; Package-Requires: ((emacs "29.1"))

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

(defgroup sql-ts nil
  "Major mode for editing SQL files."
  :prefix "sql-ts-"
  :group 'languages)

(defcustom sql-ts-indent-offset 4
  "Number of spaces for each indentation step in `sql-ts-mode'."
  :type 'integer
  :safe 'integerp)

(defvar sql-ts--keywords
  '((keyword_select) (keyword_from) (keyword_where) (keyword_index)
    (keyword_join) (keyword_primary) (keyword_delete) (keyword_create)
    (keyword_show) (keyword_unload) (keyword_insert) (keyword_merge)
    (keyword_distinct) (keyword_replace) (keyword_update)
    (keyword_into) (keyword_overwrite) (keyword_matched)
    (keyword_values) (keyword_value) (keyword_attribute) (keyword_set)
    (keyword_left) (keyword_right) (keyword_outer) (keyword_inner)
    (keyword_full) (keyword_order) (keyword_partition) (keyword_group)
    (keyword_with) (keyword_without) (keyword_as) (keyword_having)
    (keyword_limit) (keyword_offset) (keyword_table) (keyword_tables)
    (keyword_key) (keyword_references) (keyword_foreign)
    (keyword_constraint) (keyword_force) (keyword_use) (keyword_for)
    (keyword_if) (keyword_exists) (keyword_column) (keyword_columns)
    (keyword_cross) (keyword_lateral) (keyword_natural)
    (keyword_alter) (keyword_drop) (keyword_add) (keyword_view)
    (keyword_end) (keyword_is) (keyword_using) (keyword_between)
    (keyword_window) (keyword_no) (keyword_data) (keyword_type)
    (keyword_rename) (keyword_to) (keyword_schema) (keyword_owner)
    (keyword_authorization) (keyword_all) (keyword_any) (keyword_some)
    (keyword_returning) (keyword_begin) (keyword_commit)
    (keyword_rollback) (keyword_transaction) (keyword_only)
    (keyword_like) (keyword_similar) (keyword_over) (keyword_change)
    (keyword_modify) (keyword_after) (keyword_before) (keyword_range)
    (keyword_rows) (keyword_groups) (keyword_exclude)
    (keyword_current) (keyword_ties) (keyword_others)
    (keyword_zerofill) (keyword_format) (keyword_fields) (keyword_row)
    (keyword_sort) (keyword_compute) (keyword_comment)
    (keyword_location) (keyword_cached) (keyword_uncached)
    (keyword_lines) (keyword_stored) (keyword_virtual)
    (keyword_partitioned) (keyword_analyze) (keyword_explain)
    (keyword_verbose) (keyword_truncate) (keyword_rewrite)
    (keyword_optimize) (keyword_vacuum) (keyword_cache)
    (keyword_language) (keyword_called) (keyword_conflict)
    (keyword_declare) (keyword_filter) (keyword_function)
    (keyword_input) (keyword_name) (keyword_oid) (keyword_oids)
    (keyword_precision) (keyword_regclass) (keyword_regnamespace)
    (keyword_regproc) (keyword_regtype) (keyword_restricted)
    (keyword_return) (keyword_returns) (keyword_separator)
    (keyword_setof) (keyword_stable) (keyword_support)
    (keyword_tblproperties) (keyword_trigger) (keyword_unsafe)
    (keyword_admin) (keyword_connection) (keyword_cycle)
    (keyword_database) (keyword_encrypted) (keyword_increment)
    (keyword_logged) (keyword_none) (keyword_owned) (keyword_password)
    (keyword_reset) (keyword_role) (keyword_sequence) (keyword_start)
    (keyword_restart) (keyword_tablespace) (keyword_until)
    (keyword_user) (keyword_valid) (keyword_action) (keyword_definer)
    (keyword_invoker) (keyword_security) (keyword_extension)
    (keyword_version) (keyword_out) (keyword_inout) (keyword_variadic)
    (keyword_ordinality) (keyword_session) (keyword_isolation)
    (keyword_level) (keyword_serializable) (keyword_repeatable)
    (keyword_read) (keyword_write) (keyword_committed)
    (keyword_uncommitted) (keyword_deferrable) (keyword_names)
    (keyword_zone) (keyword_immediate) (keyword_deferred)
    (keyword_constraints) (keyword_snapshot) (keyword_characteristics)
    (keyword_off) (keyword_follows) (keyword_precedes) (keyword_each)
    (keyword_instead) (keyword_of) (keyword_initially) (keyword_old)
    (keyword_new) (keyword_referencing) (keyword_statement)
    (keyword_execute) (keyword_procedure) (keyword_copy)
    (keyword_delimiter) (keyword_encoding) (keyword_escape)
    (keyword_force_not_null) (keyword_force_null)
    (keyword_force_quote) (keyword_freeze) (keyword_header)
    (keyword_match) (keyword_program) (keyword_quote) (keyword_stdin)
    (keyword_extended) (keyword_main) (keyword_plain)
    (keyword_storage) (keyword_compression) (keyword_duplicate)
    ;; Conditionals
    (keyword_case) (keyword_when) (keyword_then) (keyword_else)
    ;; Operators
    (keyword_in) (keyword_and) (keyword_or) (keyword_not) (keyword_by)
    (keyword_on) (keyword_do) (keyword_union) (keyword_except)
    (keyword_intersect))
  "SQL keywords for tree-sitter font-locking.")

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
  "SQL built-in functions for tree-sitter font-locking.")

(defvar sql-ts--attributes
  '((keyword_asc) (keyword_desc) (keyword_terminated)
    (keyword_escaped) (keyword_unsigned) (keyword_nulls)
    (keyword_last) (keyword_delimited) (keyword_replication)
    (keyword_auto_increment) (keyword_default) (keyword_collate)
    (keyword_concurrently) (keyword_engine) (keyword_always)
    (keyword_generated) (keyword_preceding) (keyword_following)
    (keyword_first) (keyword_current_timestamp) (keyword_immutable)
    (keyword_atomic) (keyword_parallel) (keyword_leakproof)
    (keyword_safe) (keyword_cost) (keyword_strict)))

(defvar sql-ts--operators
  '("+" "-" "*" "/" "%" "^" ":=" "=" "<" "<=" "!=" ">=" ">" "<>"
    (op_other) (op_unary_other))
  "SQL operators for tree-sitter font-locking.")

(defvar sql-ts-mode--font-lock-settings
  (treesit-font-lock-rules
   :language 'sql
   :feature 'comment
   '([(comment) (marginalia)] @font-lock-comment-face)

   :language 'sql
   :feature 'bracket
   '((["(" ")"]) @font-lock-bracket-face)

   :language 'sql
   :feature 'delimiter
   '(([";" "," "."]) @font-lock-delimiter-face)

   :language 'sql
   :feature 'operator
   `([,@sql-ts--operators] @font-lock-operator-face)

   :language 'sql
   :feature 'builtin
   `([,@sql-ts--builtins] @font-lock-builtin-face)

   :language 'sql
   :feature 'constant
   `([(keyword_true) (keyword_false)] @font-lock-constant-face)

   :language 'sql
   :feature 'keyword
   `([,@sql-ts--keywords] @font-lock-keyword-face)

   :language 'sql
   :feature 'attribute
   `([,@sql-ts--attributes] @font-lock-preprocessor-face)

   :language 'sql
   :feature 'string
   '((literal) @font-lock-string-face)

   :language 'sql
   :feature 'type
   `((relation
      (object_reference name: (identifier) @font-lock-type-face)))

   :language 'sql
   :feature 'function
   '((invocation
      (object_reference name: (identifier) @font-lock-function-call-face))
     [(keyword_gist) (keyword_btree) (keyword_hash) (keyword_spgist)
      (keyword_gin) (keyword_brin) (keyword_array)] @font-lock-function-call-face)

   :language 'sql
   :feature 'error
   :override t
   '((ERROR) @font-lock-warning-face))
  "Tree-sitter font-lock settings for `sql-ts-mode'.")

(defvar sql-ts--indent-rules
  `((sql
     ((parent-is "program") column-0 0)
     ((node-is ")") parent-bol 0)
     ((node-is "comment") prev-adaptive-prefix 0)
     ((or (node-is "select")
          (node-is "cte")
          (node-is "column_definitions")
          (node-is "case")
          (node-is "subquery")
          (node-is "insert")
          (node-is "when_clause"))
      parent-bol sql-ts-indent-offset)
     ((or (node-is "from")
          (node-is "term"))
      prev-sibling 0)
     ((or (node-is "keyword_end")
          (node-is "keyword_values")
          (node-is "group_by")
          (node-is "join")
          (node-is "where")
          (node-is "keyword_into"))
      parent-bol 0)
     ((or (parent-is "list")
          (parent-is "from")
          (parent-is "cte")
          (parent-is "where"))
      parent-bol sql-ts-indent-offset)
     ((node-is "keyword_on") parent-bol sql-ts-indent-offset)
     ((parent-is "column_definitions") parent-bol sql-ts-indent-offset)))
  "Tree-sitter indent rules for `sql-ts-mode'.")

;;;###autoload
(define-derived-mode sql-ts-mode prog-mode "SQL"
  "Major mode for editing SQL, powered by tree-sitter."
  :group 'sql
  :syntax-table sql-mode-syntax-table

  (when (treesit-ready-p 'sql)
    (setq treesit-primary-parser (treesit-parser-create 'sql))

    ;; Comments.
    (setq-local comment-start "--")

    ;; Indent.
    (setq-local indent-tabs-mode nil)
    (setq-local treesit-simple-indent-rules sql-ts--indent-rules)

    ;; Font-lock.
    (setq-local treesit-font-lock-settings sql-ts-mode--font-lock-settings)
    (setq-local treesit-font-lock-feature-list
                '((comment keyword string)
                  (builtin constant type function attribute)
                  (bracket delimiter error operator)))
    ;; Imenu.
    (setq-local treesit-simple-imenu-settings
                `(("Statement" "\\`statement\\'" nil nil)))

    ;; Navigation.
    (setq-local treesit-thing-settings
                `((sql
                   (defun "statement")
                   (list ,(rx bos (or
                                   "list"
                                   "column_definitions"
                                   "select_expression")
                              eos))
                   (sexp ,(rx bos (or
                                   "cte"
                                   "select"
                                   "update")
                              eos))
                   (text (or comment "literal"))
                   (comment ,(rx bos "comment" eos)))))

    ;; Abbrev.
    (setq-local local-abbrev-table sql-mode-abbrev-table)

    (treesit-major-mode-setup)))

(when (fboundp 'derived-mode-add-parents)
  (derived-mode-add-parents 'sql-ts-mode '(sql-mode)))

(when (treesit-ready-p 'sql)
  (setq major-mode-remap-defaults
        (assq-delete-all 'sql-mode major-mode-remap-defaults))
  (add-to-list 'major-mode-remap-defaults
               '(sql-mode . sql-ts-mode)))

(provide 'sql-ts-mode)
;;; sql-ts-mode.el ends here
