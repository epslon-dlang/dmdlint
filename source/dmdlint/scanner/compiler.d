module dmdlint.scanner.compiler;

import dmdlint.scanner.diag;
import dmdlint.scanner.utils;

import dmd.frontend;
import dmd.globals;

import std.functional;
import std.path;
import std.file;
import std.array;

struct CompilerContext
{
    void initialize()
    {
        // set globals
        global.params.errorLimit = 0;

        foreach(path; importPaths)
            addImport(path);

        foreach(path; stringImportPaths)
            addStringImport(path);

        // init global state
        initDMD(
            toDelegate(&diagnosticHandler),
            toDelegate(&fatalErrorHandler)
        );
    }

    void deinitialize()
    {
        deinitializeDMD();
    }

    void reinitialize()
    {
        // TODO: No need to reinitialize the whole global state. Performance
        // can be improved here.
        deinitialize();
        initialize();
    }

    Appender!(string[]) importPaths;
    Appender!(string[]) stringImportPaths;
}

__gshared CompilerContext compilerContext;

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
