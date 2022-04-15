module dmdlint.app;

import dmdlint.opt;

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
    auto opt = Options();
    auto gopt = getopt(args,
        "S|single-instance", &opt.singleInstance,
        "s|source", &opt.sourcePaths,
        "I|imports", &opt.importPaths,
        "daemon", &opt.daemon,
        "daemon-mode", &opt.daemonMode);


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
