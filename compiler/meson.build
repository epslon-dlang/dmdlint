
dmd_incdir = include_directories('dmd/src')

dmd_src = [
  # Lexer
  'dmd/src/dmd/id.d',
  'dmd/src/dmd/identifier.d',
  'dmd/src/dmd/lexer.d',
  'dmd/src/dmd/tokens.d',

  # Utility
  'dmd/src/dmd/console.d',
  'dmd/src/dmd/cli.d',
  'dmd/src/dmd/dinifile.d',
  'dmd/src/dmd/entity.d',
  'dmd/src/dmd/errors.d',
  'dmd/src/dmd/file_manager.d',
  'dmd/src/dmd/globals.d',
  'dmd/src/dmd/mars.d',
  'dmd/src/dmd/dmdparams.d',
  'dmd/src/dmd/utils.d',

  # Common library
  'dmd/src/dmd/common/bitfields.d',
  'dmd/src/dmd/common/file.d',
  'dmd/src/dmd/common/int128.d',
  'dmd/src/dmd/common/outbuffer.d',
  'dmd/src/dmd/common/string.d',

  # Parser
  'dmd/src/dmd/astbase.d',
  'dmd/src/dmd/parse.d',
  'dmd/src/dmd/transitivevisitor.d',
  'dmd/src/dmd/permissivevisitor.d',
  'dmd/src/dmd/strictvisitor.d',

  # Root library
  'dmd/src/dmd/root/aav.d',
  'dmd/src/dmd/root/array.d',
  'dmd/src/dmd/root/bitarray.d',
  'dmd/src/dmd/root/complex.d',
  'dmd/src/dmd/root/ctfloat.d',
  'dmd/src/dmd/root/env.d',
  'dmd/src/dmd/root/file.d',
  'dmd/src/dmd/root/filename.d',
  'dmd/src/dmd/root/hash.d',
  'dmd/src/dmd/root/longdouble.d',
  'dmd/src/dmd/root/man.d',
  'dmd/src/dmd/root/optional.d',
  'dmd/src/dmd/root/port.d',
  'dmd/src/dmd/root/region.d',
  'dmd/src/dmd/root/response.d',
  'dmd/src/dmd/root/rmem.d',
  'dmd/src/dmd/root/rootobject.d',
  'dmd/src/dmd/root/speller.d',
  'dmd/src/dmd/root/string.d',
  'dmd/src/dmd/root/stringtable.d',
  'dmd/src/dmd/root/strtold.d',
  'dmd/src/dmd/root/utf.d',

  # Glue layer code
  'dmd/src/dmd/gluelayer.d',

  # Frontend: AST / Semantics
  'dmd/src/dmd/access.d',
  'dmd/src/dmd/frontend.d',
  'dmd/src/dmd/aggregate.d',
  'dmd/src/dmd/aliasthis.d',
  'dmd/src/dmd/apply.d',
  'dmd/src/dmd/argtypes_aarch64.d',
  'dmd/src/dmd/argtypes_sysv_x64.d',
  'dmd/src/dmd/argtypes_x86.d',
  'dmd/src/dmd/arrayop.d',
  'dmd/src/dmd/arraytypes.d',
  'dmd/src/dmd/ast_node.d',
  'dmd/src/dmd/astcodegen.d',
  'dmd/src/dmd/astenums.d',
  'dmd/src/dmd/asttypename.d',
  'dmd/src/dmd/attrib.d',
  'dmd/src/dmd/blockexit.d',
  'dmd/src/dmd/builtin.d',
  'dmd/src/dmd/canthrow.d',
  'dmd/src/dmd/chkformat.d',
  'dmd/src/dmd/clone.d',
  'dmd/src/dmd/compiler.d',
  'dmd/src/dmd/cond.d',
  'dmd/src/dmd/constfold.d',
  'dmd/src/dmd/cparse.d',
  'dmd/src/dmd/cppmangle.d',
  'dmd/src/dmd/cppmanglewin.d',
  'dmd/src/dmd/ctfeexpr.d',
  'dmd/src/dmd/ctorflow.d',
  'dmd/src/dmd/dcast.d',
  'dmd/src/dmd/dclass.d',
  'dmd/src/dmd/declaration.d',
  'dmd/src/dmd/delegatize.d',
  'dmd/src/dmd/denum.d',
  'dmd/src/dmd/dimport.d',
  'dmd/src/dmd/dinterpret.d',
  'dmd/src/dmd/dmacro.d',
  'dmd/src/dmd/dmangle.d',
  'dmd/src/dmd/dmodule.d',
  'dmd/src/dmd/doc.d',
  'dmd/src/dmd/dscope.d',
  'dmd/src/dmd/dstruct.d',
  'dmd/src/dmd/dsymbol.d',
  'dmd/src/dmd/dsymbolsem.d',
  'dmd/src/dmd/dtemplate.d',
  'dmd/src/dmd/dtoh.d',
  'dmd/src/dmd/dversion.d',
  'dmd/src/dmd/escape.d',
  'dmd/src/dmd/expression.d',
  'dmd/src/dmd/expressionsem.d',
  'dmd/src/dmd/foreachvar.d',
  'dmd/src/dmd/func.d',
  'dmd/src/dmd/hdrgen.d',
  'dmd/src/dmd/impcnvtab.d',
  'dmd/src/dmd/imphint.d',
  'dmd/src/dmd/importc.d',
  'dmd/src/dmd/init.d',
  'dmd/src/dmd/initsem.d',
  'dmd/src/dmd/inline.d',
  'dmd/src/dmd/inlinecost.d',
  'dmd/src/dmd/intrange.d',
  'dmd/src/dmd/json.d',
  'dmd/src/dmd/lambdacomp.d',
  'dmd/src/dmd/mtype.d',
  'dmd/src/dmd/mustuse.d',
  'dmd/src/dmd/nogc.d',
  'dmd/src/dmd/nspace.d',
  'dmd/src/dmd/ob.d',
  'dmd/src/dmd/objc.d',
  'dmd/src/dmd/opover.d',
  'dmd/src/dmd/optimize.d',
  'dmd/src/dmd/printast.d',
  'dmd/src/dmd/safe.d',
  'dmd/src/dmd/sapply.d',
  'dmd/src/dmd/semantic2.d',
  'dmd/src/dmd/semantic3.d',
  'dmd/src/dmd/sideeffect.d',
  'dmd/src/dmd/statement.d',
  'dmd/src/dmd/statement_rewrite_walker.d',
  'dmd/src/dmd/statementsem.d',
  'dmd/src/dmd/staticassert.d',
  'dmd/src/dmd/staticcond.d',
  'dmd/src/dmd/stmtstate.d',
  'dmd/src/dmd/target.d',
  'dmd/src/dmd/templateparamsem.d',
  'dmd/src/dmd/traits.d',
  'dmd/src/dmd/typesem.d',
  'dmd/src/dmd/typinf.d',
  'dmd/src/dmd/utils.d',
  'dmd/src/dmd/visitor.d',
]

dmd_d_import_dirs = [
  # FIXME: Remove this and generate SYSCONFDIR.imp
  include_directories('.'),
  include_directories('dmd'),
  include_directories('dmd/src/dmd/res/')
]

dmd_d_module_versions = [
  'NoBackend',
  'GC',
  'NoMain',
  'MARS',
  'CallbackAPI',
]

# FIXME: make this more portable
env = environment()
find_program('bash')
run_command('bash', '-c', 'python -c \'print("' + get_option('dmd_sysconfdir').replace('"', '\"') + '")\' > SYSCONFDIR.imp',
  env: env,
  check: true
)

dmd_lib = static_library('dmd',
  dmd_src,
  include_directories: dmd_incdir,
  d_import_dirs: dmd_d_import_dirs,
  d_module_versions: dmd_d_module_versions,
)

dmd_dep = declare_dependency(
  link_with: dmd_lib,
  include_directories: dmd_incdir,

  # FIXME: Meson doesn't read d_import_dirs nor d_module_versions here!
  # d_import_dirs: dmd_d_import_dirs,
  # d_module_versions: dmd_d_module_versions,
)

# Install Phobos & D Runtime

sources_loc = get_option('datadir') / 'dmdlint' / 'sources'

install_subdir('phobos/etc', install_dir: sources_loc)
install_subdir('phobos/std', install_dir: sources_loc)

install_subdir('druntime/src/core', install_dir: sources_loc)
install_subdir('druntime/src/etc', install_dir: sources_loc)
install_subdir('druntime/src/rt', install_dir: sources_loc)
install_data([
    'druntime/src/__builtins.di',
    'druntime/src/importc.h',
    'druntime/src/object.d',
    'druntime/src/test_runner.d',
  ],
  install_dir: sources_loc
)
