module dmdlint.common.scanopt;

import std.array;
import std.traits;

import dmdlint.common.utils;

struct ScanOptions {
    string[] sourceFiles;
    string[] sourcePaths;
    string[] importPaths;
}
