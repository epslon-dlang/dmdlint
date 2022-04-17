module dmdlint.scanner.compiler;

import dmdlint.scanner.diag;

import dmd.frontend;
import dmd.globals;

import std.functional;

void initCompilerContext()
{
    // set globals
    global.params.errorLimit = 0;

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

