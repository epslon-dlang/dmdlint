module dmdlint.common.scanopt;

import std.array;
import std.traits;

import dmdlint.common.rules;
import dmdlint.common.utils;

struct ScanOptions {
    /// Files to scan
    string[] files;

    /// Provided import paths (-I option in the compiler)
    string[] importPaths;

    /// Provided string import paths (-J option in the compiler)
    string[] stringImportPaths;

    /// Excluded rules to diagnose
    Rule[] excludeRules;
}
