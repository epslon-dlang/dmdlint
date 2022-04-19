project('dmdlint', 'd')

dcompiler = meson.get_compiler('d')

# External dependencies
argparse_dep = dependency('argparse', method: 'dub')
emsi_containers_dep = dependency('emsi_containers', method: 'dub')
# FIXME: Meson should pick this
stdx_allocator_dep = dependency('stdx-allocator', method: 'dub')

subdir('compiler')

# DMDLint
dmdlint_incdir = include_directories('source')

dmdlint_common_src = [
  'source/dmdlint/common/diag.d',
  'source/dmdlint/common/scanopt.d',
  'source/dmdlint/common/utils.d',
]

dmdlint_common_lib = static_library('dmdlint_common',
  dmdlint_common_src,
  include_directories: dmdlint_incdir
)

dmdlint_linter_src = [
  'source/dmdlint/linter/app.d',
]


dmdlint_scanner_src = [
  'source/dmdlint/scanner/app.d',
  'source/dmdlint/scanner/compiler.d',
  'source/dmdlint/scanner/diag.d',
  'source/dmdlint/scanner/utils.d',
  'source/dmdlint/scanner/rules/unused.d',
]

executable('dmdlint-scan',
  dmdlint_scanner_src,
  include_directories: dmdlint_incdir,
  d_import_dirs: dmd_d_import_dirs,
  d_module_versions: dmd_d_module_versions,
  dependencies: [
    dmd_dep,
    argparse_dep,
    emsi_containers_dep,
    stdx_allocator_dep,
  ],
  link_with: [dmdlint_common_lib],
  install: true
)
