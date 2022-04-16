module dmdlint.scanner.app;

import dmdlint.common.scanopt;

import std.file;
import std.algorithm.iteration : filter;
import std.stdio;
import std.getopt;

import std.experimental.logger;

import core.exception;

import dmd.frontend;
import dmd.errors;
import dmd.globals;

void processSourceFile(string path)
{
    auto parseResult = parseModule(path);
    if (parseResult.module_)
        parseResult.module_.fullSemantic();
}

void initCompilerContext()
{
    // handlers
    static immutable DiagnosticHandler ignoreErrors =
        (ref _1, _2, _3, _4, _5, _6, _7) => true;

    static immutable FatalErrorHandler errorHandler = () {
        onAssertErrorMsg(__FILE__, __LINE__, "fatal error");
        return true;
    };

    // set globals
    global.params.errorLimit = 0;

    // init global state
    initDMD(null, errorHandler);
}

void reinitCompilerContext()
{
    // TODO: No need to reinitialize the whole global state. Performance can be
    // improved here.
    deinitializeDMD();
    initCompilerContext();
}

int main(string[] args)
{
    auto opt = ScanOptions();
    auto gopt = getopt(args,
        "s|source", &opt.sourcePaths,
        "I|imports", &opt.importPaths,
        );

    initCompilerContext();
    scope(exit) deinitializeDMD();

    auto files = dirEntries(".", "*.{d,di,dd}", SpanMode.depth)
        .filter!(e => e.isFile);

    foreach (entry; files)
    {
        log(entry);
        try {
            processSourceFile(entry.name);
        } catch (AssertError e) {
            reinitCompilerContext();
        }
    }

    return 0;
}
