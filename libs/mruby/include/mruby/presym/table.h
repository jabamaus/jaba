static const uint16_t presym_length_table[] = {
  1,	/* ! */
  1,	/* % */
  1,	/* & */
  1,	/* * */
  1,	/* + */
  1,	/* - */
  1,	/* / */
  1,	/* < */
  1,	/* > */
  1,	/* ^ */
  1,	/* ` */
  1,	/* a */
  1,	/* b */
  1,	/* c */
  1,	/* e */
  1,	/* h */
  1,	/* i */
  1,	/* j */
  1,	/* k */
  1,	/* m */
  1,	/* n */
  1,	/* s */
  1,	/* v */
  1,	/* x */
  1,	/* y */
  1,	/* | */
  1,	/* ~ */
  2,	/* != */
  2,	/* !~ */
  2,	/* && */
  2,	/* ** */
  2,	/* +@ */
  2,	/* -@ */
  2,	/* << */
  2,	/* <= */
  2,	/* == */
  2,	/* =~ */
  2,	/* >= */
  2,	/* >> */
  2,	/* GC */
  2,	/* [] */
  2,	/* ar */
  2,	/* at */
  2,	/* sv */
  2,	/* || */
  3,	/* <=> */
  3,	/* === */
  3,	/* JDL */
  3,	/* NAN */
  3,	/* []= */
  3,	/* abs */
  3,	/* ary */
  3,	/* beg */
  3,	/* blk */
  3,	/* cmp */
  3,	/* dig */
  3,	/* div */
  3,	/* dup */
  3,	/* end */
  3,	/* idx */
  3,	/* key */
  3,	/* len */
  3,	/* lim */
  3,	/* low */
  3,	/* map */
  3,	/* max */
  3,	/* mid */
  3,	/* min */
  3,	/* new */
  3,	/* num */
  3,	/* obj */
  3,	/* pop */
  3,	/* pos */
  3,	/* quo */
  3,	/* res */
  3,	/* row */
  3,	/* str */
  3,	/* sub */
  3,	/* sym */
  3,	/* tmp */
  3,	/* val */
  4,	/* Data */
  4,	/* Hash */
  4,	/* NONE */
  4,	/* Proc */
  4,	/* all? */
  4,	/* any? */
  4,	/* arg0 */
  4,	/* arg1 */
  4,	/* arg2 */
  4,	/* args */
  4,	/* arys */
  4,	/* attr */
  4,	/* call */
  4,	/* ceil */
  4,	/* chop */
  4,	/* each */
  4,	/* elem */
  4,	/* eql? */
  4,	/* exit */
  4,	/* fdiv */
  4,	/* fill */
  4,	/* find */
  4,	/* flag */
  4,	/* grep */
  4,	/* gsub */
  4,	/* hash */
  4,	/* high */
  4,	/* join */
  4,	/* key? */
  4,	/* keys */
  4,	/* last */
  4,	/* list */
  4,	/* loop */
  4,	/* map! */
  4,	/* name */
  4,	/* nan? */
  4,	/* next */
  4,	/* nil? */
  4,	/* node */
  4,	/* note */
  4,	/* opts */
  4,	/* plen */
  4,	/* push */
  4,	/* size */
  4,	/* sort */
  4,	/* step */
  4,	/* sub! */
  4,	/* succ */
  4,	/* to_a */
  4,	/* to_f */
  4,	/* to_h */
  4,	/* to_i */
  4,	/* to_s */
  4,	/* type */
  4,	/* uniq */
  4,	/* upto */
  4,	/* vals */
  5,	/* @args */
  5,	/* @name */
  5,	/* Array */
  5,	/* Class */
  5,	/* Float */
  5,	/* Range */
  5,	/* arity */
  5,	/* array */
  5,	/* ary_F */
  5,	/* ary_T */
  5,	/* assoc */
  5,	/* begin */
  5,	/* block */
  5,	/* bytes */
  5,	/* chomp */
  5,	/* chop! */
  5,	/* class */
  5,	/* clear */
  5,	/* clone */
  5,	/* depth */
  5,	/* exit! */
  5,	/* fetch */
  5,	/* first */
  5,	/* floor */
  5,	/* found */
  5,	/* group */
  5,	/* gsub! */
  5,	/* index */
  5,	/* is_a? */
  5,	/* merge */
  5,	/* names */
  5,	/* other */
  5,	/* raise */
  5,	/* round */
  5,	/* shift */
  5,	/* slice */
  5,	/* sort! */
  5,	/* split */
  5,	/* start */
  5,	/* store */
  5,	/* times */
  5,	/* title */
  5,	/* total */
  5,	/* union */
  5,	/* uniq! */
  6,	/* Fixnum */
  6,	/* JDLDef */
  6,	/* Kernel */
  6,	/* Module */
  6,	/* Object */
  6,	/* Regexp */
  6,	/* String */
  6,	/* Symbol */
  6,	/* __id__ */
  6,	/* append */
  6,	/* chomp! */
  6,	/* concat */
  6,	/* define */
  6,	/* delete */
  6,	/* detect */
  6,	/* divmod */
  6,	/* downto */
  6,	/* empty? */
  6,	/* enable */
  6,	/* equal? */
  6,	/* extend */
  6,	/* freeze */
  6,	/* ifnone */
  6,	/* inject */
  6,	/* insert */
  6,	/* intern */
  6,	/* lambda */
  6,	/* length */
  6,	/* longer */
  6,	/* method */
  6,	/* offset */
  6,	/* others */
  6,	/* public */
  6,	/* rassoc */
  6,	/* reduce */
  6,	/* rehash */
  6,	/* reject */
  6,	/* result */
  6,	/* rindex */
  6,	/* rotate */
  6,	/* select */
  6,	/* slice! */
  6,	/* status */
  6,	/* string */
  6,	/* to_int */
  6,	/* to_str */
  6,	/* to_sym */
  6,	/* upcase */
  6,	/* value? */
  6,	/* values */
  7,	/* Complex */
  7,	/* Integer */
  7,	/* Numeric */
  7,	/* __merge */
  7,	/* bsearch */
  7,	/* collect */
  7,	/* compact */
  7,	/* compile */
  7,	/* default */
  7,	/* disable */
  7,	/* entries */
  7,	/* example */
  7,	/* filter! */
  7,	/* finite? */
  7,	/* flatten */
  7,	/* frozen? */
  7,	/* getbyte */
  7,	/* include */
  7,	/* inspect */
  7,	/* keep_if */
  7,	/* member? */
  7,	/* members */
  7,	/* message */
  7,	/* pattern */
  7,	/* pointer */
  7,	/* prepend */
  7,	/* private */
  7,	/* product */
  7,	/* reject! */
  7,	/* replace */
  7,	/* reverse */
  7,	/* rotate! */
  7,	/* select! */
  7,	/* sep_len */
  7,	/* setbyte */
  7,	/* shorter */
  7,	/* to_enum */
  7,	/* to_hash */
  7,	/* to_proc */
  7,	/* unshift */
  7,	/* upcase! */
  7,	/* variant */
  8,	/* INFINITY */
  8,	/* KeyError */
  8,	/* NilClass */
  8,	/* Rational */
  8,	/* __delete */
  8,	/* __send__ */
  8,	/* __svalue */
  8,	/* __to_int */
  8,	/* allocate */
  8,	/* between? */
  8,	/* bytesize */
  8,	/* collect! */
  8,	/* compact! */
  8,	/* default= */
  8,	/* downcase */
  8,	/* each_key */
  8,	/* extended */
  8,	/* find_all */
  8,	/* flatten! */
  8,	/* has_key? */
  8,	/* include? */
  8,	/* included */
  8,	/* kind_of? */
  8,	/* modified */
  8,	/* reverse! */
  8,	/* self_len */
  8,	/* str_each */
  8,	/* truncate */
  9,	/* $__FILE__ */
  9,	/* Exception */
  9,	/* MethodDef */
  9,	/* NameError */
  9,	/* TrueClass */
  9,	/* TypeError */
  9,	/* __compact */
  9,	/* __outer__ */
  9,	/* _gc_root_ */
  9,	/* _sys_fail */
  9,	/* ancestors */
  9,	/* backtrace */
  9,	/* byteindex */
  9,	/* byteslice */
  9,	/* const_get */
  9,	/* const_set */
  9,	/* delete_at */
  9,	/* delete_if */
  9,	/* downcase! */
  9,	/* each_byte */
  9,	/* each_line */
  9,	/* exception */
  9,	/* infinite? */
  9,	/* inherited */
  9,	/* iterator? */
  9,	/* object_id */
  9,	/* on_called */
  9,	/* partition */
  9,	/* prepended */
  9,	/* protected */
  9,	/* satisfied */
  9,	/* separator */
  9,	/* transient */
  9,	/* transpose */
  9,	/* values_at */
  10,	/* Comparable */
  10,	/* Enumerable */
  10,	/* FalseClass */
  10,	/* IndexError */
  10,	/* RangeError */
  10,	/* SystemExit */
  10,	/* __case_eqq */
  10,	/* __num_to_a */
  10,	/* byterindex */
  10,	/* bytesplice */
  10,	/* capitalize */
  10,	/* class_eval */
  10,	/* difference */
  10,	/* each_index */
  10,	/* each_value */
  10,	/* has_value? */
  10,	/* initialize */
  10,	/* intersect? */
  10,	/* step_ratio */
  10,	/* superclass */
  11,	/* BasicObject */
  11,	/* FrozenError */
  11,	/* RUBY_ENGINE */
  11,	/* RegexpError */
  11,	/* ScriptError */
  11,	/* SyntaxError */
  11,	/* __members__ */
  11,	/* attr_reader */
  11,	/* attr_writer */
  11,	/* capitalize! */
  11,	/* combination */
  11,	/* module_eval */
  11,	/* permutation */
  11,	/* respond_to? */
  11,	/* step_ratio= */
  12,	/* AttributeDef */
  12,	/* RUBY_VERSION */
  12,	/* RuntimeError */
  12,	/* __ENCODING__ */
  12,	/* __attached__ */
  12,	/* alias_method */
  12,	/* block_given? */
  12,	/* column_count */
  12,	/* column_index */
  12,	/* default_proc */
  12,	/* exclude_end? */
  12,	/* fetch_values */
  12,	/* instance_of? */
  12,	/* intersection */
  12,	/* method_added */
  12,	/* remove_const */
  12,	/* reverse_each */
  12,	/* undef_method */
  13,	/* $PROGRAM_NAME */
  13,	/* ArgumentError */
  13,	/* FlagOptionDef */
  13,	/* MRUBY_VERSION */
  13,	/* NoMemoryError */
  13,	/* NoMethodError */
  13,	/* StandardError */
  13,	/* StopIteration */
  13,	/* __classname__ */
  13,	/* __sub_replace */
  13,	/* __update_hash */
  13,	/* attr_accessor */
  13,	/* bsearch_index */
  13,	/* const_missing */
  13,	/* default_proc= */
  13,	/* define_method */
  13,	/* extend_object */
  13,	/* global_method */
  13,	/* in_lower_half */
  13,	/* instance_eval */
  13,	/* set_backtrace */
  14,	/* LocalJumpError */
  14,	/* __upto_endless */
  14,	/* const_defined? */
  14,	/* interval_ratio */
  14,	/* method_missing */
  14,	/* paragraph_mode */
  15,	/* MRUBY_COPYRIGHT */
  15,	/* SystemCallError */
  15,	/* append_features */
  15,	/* each_with_index */
  15,	/* initialize_copy */
  15,	/* interval_ratio= */
  15,	/* method_defined? */
  15,	/* module_function */
  16,	/* FloatDomainError */
  16,	/* MRUBY_RELEASE_NO */
  16,	/* SystemStackError */
  16,	/* prepend_features */
  17,	/* MRUBY_DESCRIPTION */
  17,	/* ZeroDivisionError */
  17,	/* generational_mode */
  18,	/* MRUBY_RELEASE_DATE */
  18,	/* generational_mode= */
  19,	/* NotImplementedError */
  19,	/* RUBY_ENGINE_VERSION */
  19,	/* respond_to_missing? */
  20,	/* __inspect_recursive? */
  20,	/* repeated_combination */
  20,	/* repeated_permutation */
  21,	/* __coerce_step_counter */
  22,	/* __repeated_combination */
  22,	/* singleton_method_added */
  24,	/* remove_instance_variable */
};

static const char * const presym_name_table[] = {
  "!",
  "%",
  "&",
  "*",
  "+",
  "-",
  "/",
  "<",
  ">",
  "^",
  "`",
  "a",
  "b",
  "c",
  "e",
  "h",
  "i",
  "j",
  "k",
  "m",
  "n",
  "s",
  "v",
  "x",
  "y",
  "|",
  "~",
  "!=",
  "!~",
  "&&",
  "**",
  "+@",
  "-@",
  "<<",
  "<=",
  "==",
  "=~",
  ">=",
  ">>",
  "GC",
  "[]",
  "ar",
  "at",
  "sv",
  "||",
  "<=>",
  "===",
  "JDL",
  "NAN",
  "[]=",
  "abs",
  "ary",
  "beg",
  "blk",
  "cmp",
  "dig",
  "div",
  "dup",
  "end",
  "idx",
  "key",
  "len",
  "lim",
  "low",
  "map",
  "max",
  "mid",
  "min",
  "new",
  "num",
  "obj",
  "pop",
  "pos",
  "quo",
  "res",
  "row",
  "str",
  "sub",
  "sym",
  "tmp",
  "val",
  "Data",
  "Hash",
  "NONE",
  "Proc",
  "all?",
  "any?",
  "arg0",
  "arg1",
  "arg2",
  "args",
  "arys",
  "attr",
  "call",
  "ceil",
  "chop",
  "each",
  "elem",
  "eql?",
  "exit",
  "fdiv",
  "fill",
  "find",
  "flag",
  "grep",
  "gsub",
  "hash",
  "high",
  "join",
  "key?",
  "keys",
  "last",
  "list",
  "loop",
  "map!",
  "name",
  "nan?",
  "next",
  "nil?",
  "node",
  "note",
  "opts",
  "plen",
  "push",
  "size",
  "sort",
  "step",
  "sub!",
  "succ",
  "to_a",
  "to_f",
  "to_h",
  "to_i",
  "to_s",
  "type",
  "uniq",
  "upto",
  "vals",
  "@args",
  "@name",
  "Array",
  "Class",
  "Float",
  "Range",
  "arity",
  "array",
  "ary_F",
  "ary_T",
  "assoc",
  "begin",
  "block",
  "bytes",
  "chomp",
  "chop!",
  "class",
  "clear",
  "clone",
  "depth",
  "exit!",
  "fetch",
  "first",
  "floor",
  "found",
  "group",
  "gsub!",
  "index",
  "is_a?",
  "merge",
  "names",
  "other",
  "raise",
  "round",
  "shift",
  "slice",
  "sort!",
  "split",
  "start",
  "store",
  "times",
  "title",
  "total",
  "union",
  "uniq!",
  "Fixnum",
  "JDLDef",
  "Kernel",
  "Module",
  "Object",
  "Regexp",
  "String",
  "Symbol",
  "__id__",
  "append",
  "chomp!",
  "concat",
  "define",
  "delete",
  "detect",
  "divmod",
  "downto",
  "empty?",
  "enable",
  "equal?",
  "extend",
  "freeze",
  "ifnone",
  "inject",
  "insert",
  "intern",
  "lambda",
  "length",
  "longer",
  "method",
  "offset",
  "others",
  "public",
  "rassoc",
  "reduce",
  "rehash",
  "reject",
  "result",
  "rindex",
  "rotate",
  "select",
  "slice!",
  "status",
  "string",
  "to_int",
  "to_str",
  "to_sym",
  "upcase",
  "value?",
  "values",
  "Complex",
  "Integer",
  "Numeric",
  "__merge",
  "bsearch",
  "collect",
  "compact",
  "compile",
  "default",
  "disable",
  "entries",
  "example",
  "filter!",
  "finite?",
  "flatten",
  "frozen?",
  "getbyte",
  "include",
  "inspect",
  "keep_if",
  "member?",
  "members",
  "message",
  "pattern",
  "pointer",
  "prepend",
  "private",
  "product",
  "reject!",
  "replace",
  "reverse",
  "rotate!",
  "select!",
  "sep_len",
  "setbyte",
  "shorter",
  "to_enum",
  "to_hash",
  "to_proc",
  "unshift",
  "upcase!",
  "variant",
  "INFINITY",
  "KeyError",
  "NilClass",
  "Rational",
  "__delete",
  "__send__",
  "__svalue",
  "__to_int",
  "allocate",
  "between?",
  "bytesize",
  "collect!",
  "compact!",
  "default=",
  "downcase",
  "each_key",
  "extended",
  "find_all",
  "flatten!",
  "has_key?",
  "include?",
  "included",
  "kind_of?",
  "modified",
  "reverse!",
  "self_len",
  "str_each",
  "truncate",
  "$__FILE__",
  "Exception",
  "MethodDef",
  "NameError",
  "TrueClass",
  "TypeError",
  "__compact",
  "__outer__",
  "_gc_root_",
  "_sys_fail",
  "ancestors",
  "backtrace",
  "byteindex",
  "byteslice",
  "const_get",
  "const_set",
  "delete_at",
  "delete_if",
  "downcase!",
  "each_byte",
  "each_line",
  "exception",
  "infinite?",
  "inherited",
  "iterator?",
  "object_id",
  "on_called",
  "partition",
  "prepended",
  "protected",
  "satisfied",
  "separator",
  "transient",
  "transpose",
  "values_at",
  "Comparable",
  "Enumerable",
  "FalseClass",
  "IndexError",
  "RangeError",
  "SystemExit",
  "__case_eqq",
  "__num_to_a",
  "byterindex",
  "bytesplice",
  "capitalize",
  "class_eval",
  "difference",
  "each_index",
  "each_value",
  "has_value?",
  "initialize",
  "intersect?",
  "step_ratio",
  "superclass",
  "BasicObject",
  "FrozenError",
  "RUBY_ENGINE",
  "RegexpError",
  "ScriptError",
  "SyntaxError",
  "__members__",
  "attr_reader",
  "attr_writer",
  "capitalize!",
  "combination",
  "module_eval",
  "permutation",
  "respond_to?",
  "step_ratio=",
  "AttributeDef",
  "RUBY_VERSION",
  "RuntimeError",
  "__ENCODING__",
  "__attached__",
  "alias_method",
  "block_given?",
  "column_count",
  "column_index",
  "default_proc",
  "exclude_end?",
  "fetch_values",
  "instance_of?",
  "intersection",
  "method_added",
  "remove_const",
  "reverse_each",
  "undef_method",
  "$PROGRAM_NAME",
  "ArgumentError",
  "FlagOptionDef",
  "MRUBY_VERSION",
  "NoMemoryError",
  "NoMethodError",
  "StandardError",
  "StopIteration",
  "__classname__",
  "__sub_replace",
  "__update_hash",
  "attr_accessor",
  "bsearch_index",
  "const_missing",
  "default_proc=",
  "define_method",
  "extend_object",
  "global_method",
  "in_lower_half",
  "instance_eval",
  "set_backtrace",
  "LocalJumpError",
  "__upto_endless",
  "const_defined?",
  "interval_ratio",
  "method_missing",
  "paragraph_mode",
  "MRUBY_COPYRIGHT",
  "SystemCallError",
  "append_features",
  "each_with_index",
  "initialize_copy",
  "interval_ratio=",
  "method_defined?",
  "module_function",
  "FloatDomainError",
  "MRUBY_RELEASE_NO",
  "SystemStackError",
  "prepend_features",
  "MRUBY_DESCRIPTION",
  "ZeroDivisionError",
  "generational_mode",
  "MRUBY_RELEASE_DATE",
  "generational_mode=",
  "NotImplementedError",
  "RUBY_ENGINE_VERSION",
  "respond_to_missing?",
  "__inspect_recursive?",
  "repeated_combination",
  "repeated_permutation",
  "__coerce_step_counter",
  "__repeated_combination",
  "singleton_method_added",
  "remove_instance_variable",
};