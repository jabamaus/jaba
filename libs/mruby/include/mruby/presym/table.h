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
  1,	/* z */
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
  2,	/* bi */
  2,	/* bs */
  2,	/* cp */
  2,	/* e2 */
  2,	/* e3 */
  2,	/* ed */
  2,	/* ei */
  2,	/* nv */
  2,	/* sv */
  2,	/* tr */
  2,	/* || */
  3,	/* <=> */
  3,	/* === */
  3,	/* JDL */
  3,	/* NAN */
  3,	/* []= */
  3,	/* abs */
  3,	/* arg */
  3,	/* ary */
  3,	/* beg */
  3,	/* blk */
  3,	/* chr */
  3,	/* cmp */
  3,	/* dig */
  3,	/* div */
  3,	/* dup */
  3,	/* end */
  3,	/* hex */
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
  3,	/* oct */
  3,	/* ord */
  3,	/* pat */
  3,	/* pop */
  3,	/* pos */
  3,	/* quo */
  3,	/* res */
  3,	/* row */
  3,	/* sep */
  3,	/* str */
  3,	/* sub */
  3,	/* sum */
  3,	/* sym */
  3,	/* tmp */
  3,	/* tr! */
  3,	/* val */
  3,	/* zip */
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
  4,	/* bsiz */
  4,	/* call */
  4,	/* ceil */
  4,	/* chop */
  4,	/* drop */
  4,	/* dump */
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
  4,	/* idx2 */
  4,	/* init */
  4,	/* join */
  4,	/* key? */
  4,	/* keys */
  4,	/* last */
  4,	/* line */
  4,	/* list */
  4,	/* loop */
  4,	/* map! */
  4,	/* name */
  4,	/* nan? */
  4,	/* next */
  4,	/* nil? */
  4,	/* node */
  4,	/* note */
  4,	/* one? */
  4,	/* opts */
  4,	/* pad1 */
  4,	/* pad2 */
  4,	/* plen */
  4,	/* push */
  4,	/* puts */
  4,	/* send */
  4,	/* size */
  4,	/* sort */
  4,	/* step */
  4,	/* str2 */
  4,	/* sub! */
  4,	/* succ */
  4,	/* take */
  4,	/* to_a */
  4,	/* to_f */
  4,	/* to_h */
  4,	/* to_i */
  4,	/* to_s */
  4,	/* tr_s */
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
  5,	/* chars */
  5,	/* chomp */
  5,	/* chop! */
  5,	/* class */
  5,	/* clear */
  5,	/* clone */
  5,	/* count */
  5,	/* cycle */
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
  5,	/* lines */
  5,	/* ljust */
  5,	/* merge */
  5,	/* names */
  5,	/* next! */
  5,	/* none? */
  5,	/* other */
  5,	/* raise */
  5,	/* rjust */
  5,	/* round */
  5,	/* shift */
  5,	/* slice */
  5,	/* sort! */
  5,	/* split */
  5,	/* start */
  5,	/* state */
  5,	/* store */
  5,	/* strip */
  5,	/* succ! */
  5,	/* tally */
  5,	/* times */
  5,	/* title */
  5,	/* total */
  5,	/* tr_s! */
  5,	/* union */
  5,	/* uniq! */
  5,	/* width */
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
  6,	/* center */
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
  6,	/* filter */
  6,	/* freeze */
  6,	/* grep_v */
  6,	/* ifnone */
  6,	/* inject */
  6,	/* insert */
  6,	/* intern */
  6,	/* lambda */
  6,	/* length */
  6,	/* longer */
  6,	/* lstrip */
  6,	/* max_by */
  6,	/* maxlen */
  6,	/* method */
  6,	/* min_by */
  6,	/* minmax */
  6,	/* offset */
  6,	/* others */
  6,	/* padstr */
  6,	/* public */
  6,	/* rassoc */
  6,	/* reduce */
  6,	/* rehash */
  6,	/* reject */
  6,	/* result */
  6,	/* rindex */
  6,	/* rotate */
  6,	/* rstrip */
  6,	/* select */
  6,	/* slice! */
  6,	/* status */
  6,	/* string */
  6,	/* strip! */
  6,	/* to_int */
  6,	/* to_str */
  6,	/* to_sym */
  6,	/* upcase */
  6,	/* value? */
  6,	/* values */
  7,	/* Complex */
  7,	/* Integer */
  7,	/* Numeric */
  7,	/* __lines */
  7,	/* __merge */
  7,	/* bsearch */
  7,	/* casecmp */
  7,	/* collect */
  7,	/* compact */
  7,	/* compile */
  7,	/* default */
  7,	/* delete! */
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
  7,	/* lstrip! */
  7,	/* max_cmp */
  7,	/* member? */
  7,	/* members */
  7,	/* message */
  7,	/* methods */
  7,	/* min_cmp */
  7,	/* nesting */
  7,	/* padding */
  7,	/* pattern */
  7,	/* pointer */
  7,	/* prepend */
  7,	/* private */
  7,	/* process */
  7,	/* product */
  7,	/* reject! */
  7,	/* replace */
  7,	/* reverse */
  7,	/* rotate! */
  7,	/* rstrip! */
  7,	/* select! */
  7,	/* sep_len */
  7,	/* setbyte */
  7,	/* shorter */
  7,	/* sort_by */
  7,	/* squeeze */
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
  8,	/* casecmp? */
  8,	/* collect! */
  8,	/* compact! */
  8,	/* default= */
  8,	/* downcase */
  8,	/* each_key */
  8,	/* extended */
  8,	/* finalise */
  8,	/* find_all */
  8,	/* flat_map */
  8,	/* flatten! */
  8,	/* group_by */
  8,	/* has_key? */
  8,	/* include? */
  8,	/* included */
  8,	/* kind_of? */
  8,	/* modified */
  8,	/* reverse! */
  8,	/* self_len */
  8,	/* sort_by! */
  8,	/* squeeze! */
  8,	/* str_each */
  8,	/* swapcase */
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
  9,	/* constants */
  9,	/* delete_at */
  9,	/* delete_if */
  9,	/* downcase! */
  9,	/* each_byte */
  9,	/* each_char */
  9,	/* each_cons */
  9,	/* each_line */
  9,	/* end_with? */
  9,	/* exception */
  9,	/* exclusive */
  9,	/* infinite? */
  9,	/* inherited */
  9,	/* iterator? */
  9,	/* minmax_by */
  9,	/* object_id */
  9,	/* on_called */
  9,	/* partition */
  9,	/* prepended */
  9,	/* protected */
  9,	/* satisfied */
  9,	/* separator */
  9,	/* swapcase! */
  9,	/* transient */
  9,	/* transpose */
  9,	/* validated */
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
  10,	/* codepoints */
  10,	/* difference */
  10,	/* drop_while */
  10,	/* each_entry */
  10,	/* each_index */
  10,	/* each_slice */
  10,	/* each_value */
  10,	/* filter_map */
  10,	/* find_index */
  10,	/* has_value? */
  10,	/* initialize */
  10,	/* intersect? */
  10,	/* rpartition */
  10,	/* step_ratio */
  10,	/* superclass */
  10,	/* take_while */
  11,	/* BasicObject */
  11,	/* FrozenError */
  11,	/* RUBY_ENGINE */
  11,	/* RegexpError */
  11,	/* ScriptError */
  11,	/* SyntaxError */
  11,	/* __members__ */
  11,	/* ascii_only? */
  11,	/* attr_reader */
  11,	/* attr_writer */
  11,	/* capitalize! */
  11,	/* combination */
  11,	/* module_eval */
  11,	/* permutation */
  11,	/* respond_to? */
  11,	/* start_with? */
  11,	/* step_ratio= */
  12,	/* AttributeDef */
  12,	/* RUBY_VERSION */
  12,	/* RuntimeError */
  12,	/* __ENCODING__ */
  12,	/* __attached__ */
  12,	/* __codepoints */
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
  13,	/* delete_prefix */
  13,	/* delete_suffix */
  13,	/* extend_object */
  13,	/* global_method */
  13,	/* in_lower_half */
  13,	/* instance_eval */
  13,	/* remove_method */
  13,	/* set_backtrace */
  14,	/* CmdlineManager */
  14,	/* LocalJumpError */
  14,	/* __upto_endless */
  14,	/* collect_concat */
  14,	/* const_defined? */
  14,	/* delete_prefix! */
  14,	/* delete_suffix! */
  14,	/* each_codepoint */
  14,	/* interval_ratio */
  14,	/* method_missing */
  14,	/* method_removed */
  14,	/* paragraph_mode */
  14,	/* public_methods */
  15,	/* MRUBY_COPYRIGHT */
  15,	/* SystemCallError */
  15,	/* append_features */
  15,	/* class_variables */
  15,	/* each_with_index */
  15,	/* initialize_copy */
  15,	/* interval_ratio= */
  15,	/* local_variables */
  15,	/* method_defined? */
  15,	/* module_function */
  15,	/* pad_repetitions */
  15,	/* private_methods */
  15,	/* singleton_class */
  15,	/* valid_encoding? */
  16,	/* FloatDomainError */
  16,	/* MRUBY_RELEASE_NO */
  16,	/* SystemStackError */
  16,	/* each_with_object */
  16,	/* global_variables */
  16,	/* included_modules */
  16,	/* instance_methods */
  16,	/* prepend_features */
  16,	/* require_relative */
  17,	/* MRUBY_DESCRIPTION */
  17,	/* ZeroDivisionError */
  17,	/* generational_mode */
  17,	/* protected_methods */
  17,	/* singleton_methods */
  18,	/* MRUBY_RELEASE_DATE */
  18,	/* class_variable_get */
  18,	/* class_variable_set */
  18,	/* generational_mode= */
  18,	/* instance_variables */
  19,	/* NotImplementedError */
  19,	/* RUBY_ENGINE_VERSION */
  19,	/* respond_to_missing? */
  20,	/* __inspect_recursive? */
  20,	/* repeated_combination */
  20,	/* repeated_permutation */
  21,	/* __coerce_step_counter */
  21,	/* instance_variable_get */
  21,	/* instance_variable_set */
  21,	/* remove_class_variable */
  22,	/* __repeated_combination */
  22,	/* singleton_method_added */
  23,	/* class_variable_defined? */
  23,	/* define_singleton_method */
  24,	/* remove_instance_variable */
  26,	/* instance_variable_defined? */
  26,	/* undefined_instance_methods */
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
  "z",
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
  "bi",
  "bs",
  "cp",
  "e2",
  "e3",
  "ed",
  "ei",
  "nv",
  "sv",
  "tr",
  "||",
  "<=>",
  "===",
  "JDL",
  "NAN",
  "[]=",
  "abs",
  "arg",
  "ary",
  "beg",
  "blk",
  "chr",
  "cmp",
  "dig",
  "div",
  "dup",
  "end",
  "hex",
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
  "oct",
  "ord",
  "pat",
  "pop",
  "pos",
  "quo",
  "res",
  "row",
  "sep",
  "str",
  "sub",
  "sum",
  "sym",
  "tmp",
  "tr!",
  "val",
  "zip",
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
  "bsiz",
  "call",
  "ceil",
  "chop",
  "drop",
  "dump",
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
  "idx2",
  "init",
  "join",
  "key?",
  "keys",
  "last",
  "line",
  "list",
  "loop",
  "map!",
  "name",
  "nan?",
  "next",
  "nil?",
  "node",
  "note",
  "one?",
  "opts",
  "pad1",
  "pad2",
  "plen",
  "push",
  "puts",
  "send",
  "size",
  "sort",
  "step",
  "str2",
  "sub!",
  "succ",
  "take",
  "to_a",
  "to_f",
  "to_h",
  "to_i",
  "to_s",
  "tr_s",
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
  "chars",
  "chomp",
  "chop!",
  "class",
  "clear",
  "clone",
  "count",
  "cycle",
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
  "lines",
  "ljust",
  "merge",
  "names",
  "next!",
  "none?",
  "other",
  "raise",
  "rjust",
  "round",
  "shift",
  "slice",
  "sort!",
  "split",
  "start",
  "state",
  "store",
  "strip",
  "succ!",
  "tally",
  "times",
  "title",
  "total",
  "tr_s!",
  "union",
  "uniq!",
  "width",
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
  "center",
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
  "filter",
  "freeze",
  "grep_v",
  "ifnone",
  "inject",
  "insert",
  "intern",
  "lambda",
  "length",
  "longer",
  "lstrip",
  "max_by",
  "maxlen",
  "method",
  "min_by",
  "minmax",
  "offset",
  "others",
  "padstr",
  "public",
  "rassoc",
  "reduce",
  "rehash",
  "reject",
  "result",
  "rindex",
  "rotate",
  "rstrip",
  "select",
  "slice!",
  "status",
  "string",
  "strip!",
  "to_int",
  "to_str",
  "to_sym",
  "upcase",
  "value?",
  "values",
  "Complex",
  "Integer",
  "Numeric",
  "__lines",
  "__merge",
  "bsearch",
  "casecmp",
  "collect",
  "compact",
  "compile",
  "default",
  "delete!",
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
  "lstrip!",
  "max_cmp",
  "member?",
  "members",
  "message",
  "methods",
  "min_cmp",
  "nesting",
  "padding",
  "pattern",
  "pointer",
  "prepend",
  "private",
  "process",
  "product",
  "reject!",
  "replace",
  "reverse",
  "rotate!",
  "rstrip!",
  "select!",
  "sep_len",
  "setbyte",
  "shorter",
  "sort_by",
  "squeeze",
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
  "casecmp?",
  "collect!",
  "compact!",
  "default=",
  "downcase",
  "each_key",
  "extended",
  "finalise",
  "find_all",
  "flat_map",
  "flatten!",
  "group_by",
  "has_key?",
  "include?",
  "included",
  "kind_of?",
  "modified",
  "reverse!",
  "self_len",
  "sort_by!",
  "squeeze!",
  "str_each",
  "swapcase",
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
  "constants",
  "delete_at",
  "delete_if",
  "downcase!",
  "each_byte",
  "each_char",
  "each_cons",
  "each_line",
  "end_with?",
  "exception",
  "exclusive",
  "infinite?",
  "inherited",
  "iterator?",
  "minmax_by",
  "object_id",
  "on_called",
  "partition",
  "prepended",
  "protected",
  "satisfied",
  "separator",
  "swapcase!",
  "transient",
  "transpose",
  "validated",
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
  "codepoints",
  "difference",
  "drop_while",
  "each_entry",
  "each_index",
  "each_slice",
  "each_value",
  "filter_map",
  "find_index",
  "has_value?",
  "initialize",
  "intersect?",
  "rpartition",
  "step_ratio",
  "superclass",
  "take_while",
  "BasicObject",
  "FrozenError",
  "RUBY_ENGINE",
  "RegexpError",
  "ScriptError",
  "SyntaxError",
  "__members__",
  "ascii_only?",
  "attr_reader",
  "attr_writer",
  "capitalize!",
  "combination",
  "module_eval",
  "permutation",
  "respond_to?",
  "start_with?",
  "step_ratio=",
  "AttributeDef",
  "RUBY_VERSION",
  "RuntimeError",
  "__ENCODING__",
  "__attached__",
  "__codepoints",
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
  "delete_prefix",
  "delete_suffix",
  "extend_object",
  "global_method",
  "in_lower_half",
  "instance_eval",
  "remove_method",
  "set_backtrace",
  "CmdlineManager",
  "LocalJumpError",
  "__upto_endless",
  "collect_concat",
  "const_defined?",
  "delete_prefix!",
  "delete_suffix!",
  "each_codepoint",
  "interval_ratio",
  "method_missing",
  "method_removed",
  "paragraph_mode",
  "public_methods",
  "MRUBY_COPYRIGHT",
  "SystemCallError",
  "append_features",
  "class_variables",
  "each_with_index",
  "initialize_copy",
  "interval_ratio=",
  "local_variables",
  "method_defined?",
  "module_function",
  "pad_repetitions",
  "private_methods",
  "singleton_class",
  "valid_encoding?",
  "FloatDomainError",
  "MRUBY_RELEASE_NO",
  "SystemStackError",
  "each_with_object",
  "global_variables",
  "included_modules",
  "instance_methods",
  "prepend_features",
  "require_relative",
  "MRUBY_DESCRIPTION",
  "ZeroDivisionError",
  "generational_mode",
  "protected_methods",
  "singleton_methods",
  "MRUBY_RELEASE_DATE",
  "class_variable_get",
  "class_variable_set",
  "generational_mode=",
  "instance_variables",
  "NotImplementedError",
  "RUBY_ENGINE_VERSION",
  "respond_to_missing?",
  "__inspect_recursive?",
  "repeated_combination",
  "repeated_permutation",
  "__coerce_step_counter",
  "instance_variable_get",
  "instance_variable_set",
  "remove_class_variable",
  "__repeated_combination",
  "singleton_method_added",
  "class_variable_defined?",
  "define_singleton_method",
  "remove_instance_variable",
  "instance_variable_defined?",
  "undefined_instance_methods",
};
