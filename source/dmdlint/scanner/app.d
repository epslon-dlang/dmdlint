module dmdlint.scanner.app;

import dmdlint.common.scanopt;
import dmdlint.common.utils;
import dmdlint.common.diag;
import dmdlint.scanner.diag;

import std.file;
import std.algorithm;
import std.stdio;
import std.getopt;
import std.array;

import std.experimental.logger;

import core.exception;
import core.stdc.stdarg;
import core.sys.posix.unistd : isatty, STDIN_FILENO;

import dmd.frontend;
import dmd.errors;
import dmd.globals;
import dmd.console;

import argparse;

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

        string message = void;
        {
            // Avoid copy/reallocating a new buffer for performance reasons.
            // Instead, take the ownership of the data and add it to the GC
            // ranges list to be collected.
            import dmd.common.outbuffer;
            OutBuffer tmp;
            tmp.vprintf(messageFormat, args);
            message = tmp.extractSlice();

            import core.memory : GC;
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

struct AppOptions
{
    @(
        NamedArgument("imports", "I")
        .Description("Specify additional import paths")
    )
    string[] importPaths;

    @MutuallyExclusive
    {
        @(
            NamedArgument("stdin")
            .Description("Read a D source file from the standard input")
        )
        bool stdin;

        @(
            NamedArgument("files", "f")
            .Description("D source files to scan. You can provide a regex to match multiple files")
        )
        string[] files;
    }

    @TrailingArguments string[] trailingArgs;
}

int main(string[] args)
{
    auto opt = ScanOptions();
    ScanOptions options;
    AppOptions appOptions;

    // check if stdin is open and it's not in a tty
    // FIXME: Make it less OS-dependent by using UCRT library
    if (args.length == 1 && stdin.isOpen() && !isatty(STDIN_FILENO))
    {
        static immutable minSizeChunk = genPackedBuffer(ScanOptions.init).length;
        Appender!(ubyte[]) buf;
        buf.reserve(minSizeChunk);

        foreach(ubyte[] chunk; stdin.byChunk(min(minSizeChunk, 4096)))
            buf ~= chunk;

        if (buf[].empty)
        {
            stderr.writeln("Please provide a packed buffer with the options!");
            return 1;
        }

        // FIXME: Use appender when it has range interfaces
        auto nopt = buf[].unpackBuffer!(ScanOptions, SignatureChecks.none);
        assert(!nopt.isNull, "can't decode packed buffer");
        options = nopt.get();
    } else {
        assert(args.length > 0);

        bool readStdin;
        // seek for - argument (read from stdin)
        foreach(i, arg; args)
        {
            if(arg == "-")
            {
                readStdin = true;
                args = args.remove(i);
                break;
            }
        }

        auto nappopt = parseCLIArgs!AppOptions(args[1 .. $]);
        if (nappopt.isNull)
            return 1;

        appOptions = nappopt.get();
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
