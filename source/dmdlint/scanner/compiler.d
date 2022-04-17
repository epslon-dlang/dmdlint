module dmdlint.scanner.compiler;

import dmdlint.scanner.diag;
import dmdlint.scanner.utils;

import dmd.frontend;
import dmd.globals;

import std.functional;
import std.path;
import std.file;

void initCompilerContext()
{
    // set globals
    global.params.errorLimit = 0;

    addImport(getDefaultImportPaths());

    // init global state
    initDMD(
        toDelegate(&diagnosticHandler),
        toDelegate(&fatalErrorHandler)
    );
}

void reinitCompilerContext()
{
    // TODO: No need to reinitialize the whole global state. Performance can be
    // improved here.
    deinitializeDMD();
    initCompilerContext();
}

bool compilerSourcesSanityCheck(string path)
{
    try
        // D Runtime
        return buildPath(path, "object.d").isFile &&
            buildPath(path, "core").isDir &&
        // Phobos
            buildPath(path, "std").isDir &&
            buildPath(path, "etc").isDir;
    catch (FileException)
        return false;
}
