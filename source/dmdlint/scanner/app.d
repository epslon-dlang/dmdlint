module dmdlint.scanner.app;

import dmdlint.common.scanopt;
import dmdlint.common.utils;
import dmdlint.common.diag;

import std.file;
import std.algorithm;
import std.stdio;
import std.getopt;
import std.array;

import std.experimental.logger;

import core.exception;
import core.stdc.stdarg;

import dmd.frontend;
import dmd.errors;
import dmd.globals;
import dmd.console;

void processSourceFile(string path)
{
    auto parseResult = parseModule(path);
    if (parseResult.module_)
        parseResult.module_.fullSemantic();
}

// no need to be on TLS since the compiler is single-threaded
__gshared Appender!(Diagnostic[]) diagnostics;

void initCompilerContext()
{
    // handlers
    static immutable DiagnosticHandler diagnosticHandler = (
        const ref Loc loc,
        Color headerColor,
        const(char)* header,
        const(char)* messageFormat,
        va_list args,
        const(char)* prefix1,
        const(char)* prefix2
    ) {
        Severity severity = headerColor.toSeverity();
        Location location = loc.toLocation();

        strinc message = void;
        {
            // Avoid copy/reallocating a new buffer for performance reasons.
            // Instead, take the ownership of the data and add it to the GC
            // ranges list to be collected.
            OutBuffer tmp;
            tmp.vprintf(messageFormat, args);
            message = tmp.extractSlice();
            GC.addRange(message.ptr, message.length);
        }

        diagnostics ~= Diagnostic(location, severity, message);

        return true;
    };

    static immutable FatalErrorHandler errorHandler = () {
        onAssertErrorMsg(__FILE__, __LINE__, "fatal error");
        return true;
    };

    // set globals
    global.params.errorLimit = 0;

    // init global state
    initDMD(diagnosticHandler, errorHandler);
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

    // check if stdin is open
    if (args.length == 1)
    {
        static immutable minSizeChunk = genPackedBuffer(ScanOptions.init).length;
        Appender!(ubyte[]) buf;
        buf.reserve(minSizeChunk);

        foreach(ubyte[] chunk; stdin.byChunk(min(minSizeChunk, 4096)))
            buf ~= chunk;

        auto nopt = buf.unpackBuffer!(ScanOptions, SignatureChecks.none);
        assert(!nopt.isNull, "can't decode packed buffer");
        opt = nopt.get();
    } else {
        auto gopt = getopt(args,
            "s|source", &opt.sourcePaths,
            "I|imports", &opt.importPaths,
            );
    }


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
