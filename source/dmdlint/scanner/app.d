module dmdlint.scanner.app;

import dmdlint.common.scanopt;
import dmdlint.common.utils;
import dmdlint.common.diag;
import dmdlint.scanner.compiler;
import dmdlint.scanner.diag;
import dmdlint.scanner.utils;
import dmdlint.scanner.rules.useless;

import std.algorithm;
import std.array;
import std.file;
import std.functional;
import std.getopt;
import std.path;
import std.stdio;

import std.experimental.logger;

import core.exception;
import core.stdc.stdarg;

import dmd.frontend;
import dmd.errors;
import dmd.globals;
import dmd.console;

import argparse;

void processSourceFile(string path)
{
    auto parseResult = parseModule(path);
    if (parseResult.module_)
    {
        parseResult.module_.fullSemantic();

        // rules
        parseResult.module_.reportUselessRule();
    }
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
}

version(unittest) {}
else
int main(string[] args)
{
    ScanOptions options;
    bool readStdin;

    static bool detectTerminal() nothrow
    {
        version (Posix)
        {
            import core.sys.posix.unistd : isatty, STDIN_FILENO;
            import core.stdc.stdlib : getenv;
            import core.stdc.string : strcmp;

            const(char)* term = getenv("TERM");
            return isatty(STDIN_FILENO) && term && term[0] && strcmp(term, "dumb") != 0;
        }
        else version (Windows)
        {
            import core.sys.windows.winbase;
            import core.sys.windows.wincon;
            import core.sys.windows.windef;
            import core.stdc.stdio : stdin;

            version (CRuntime_DigitalMars)
                return isatty(stdin._file) != 0;
            else version (CRuntime_Microsoft)
                return isatty(fileno(stdin)) != 0;
            else
                static assert(0, "Unsupported Windows runtime.");
        }

    }


    // check if stdin is open and it's not in a tty
    if (args.length == 1 && stdin.isOpen() && !detectTerminal())
    {
        static immutable minPackedBufChunkSize = genPackedBuffer(ScanOptions.init).length;
        static immutable minChunkSize = min(minPackedBufChunkSize, 4096);
        Appender!(ubyte[]) buf;
        buf.reserve(minPackedBufChunkSize);

        foreach(ubyte[] chunk; stdin.byChunk(minChunkSize))
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

        diagnosticContext.reportEvents = true;
    } else {
        assert(args.length > 0);

        // TODO: Tweak this
        diagnosticContext.console = true;
        diagnosticContext.consoleColors = true;

        // seek for - argument (read from stdin)
        foreach(ref arg; args)
        {
            if(arg == "-")
            {
                arg = "--stdin";
                break;
            }
        }

        AppOptions appopt;
        if (!CLI!AppOptions.parseArgs(appopt, args[1 .. $]))
            return 1;

        with (appopt)
        {
            options.files = files;
            options.importPaths = importPaths;
            readStdin = stdin;
        }

        if (!readStdin && options.files.empty)
        {
            stderr.writeln("Please specify file!\n");
            AppOptions _;
            CLI!AppOptions.parseArgs(_, ["-h"]);
            return 1;
        }
    }

    compilerContext.importPaths ~= getDefaultImportPaths();
    foreach(path; options.importPaths)
        compilerContext.importPaths ~= path;

    compilerContext.initialize();
    scope(exit) compilerContext.deinitialize();

    foreach (path; options.files)
    {
        if (!path.isValidPath)
        {
            stderr.writefln("Invalid path: '%s'", path);
            return 1;
        }
        if (!path.exists)
        {
            stderr.writefln("Path doesn't exist: '%s'", path);
            return 1;
        }

        if (DirEntry(path).isDir)
        {
            foreach(entry; dirEntries(path, "*.{d,di,dd}", SpanMode.depth).filter!(e => e.isFile))
            {
                try {
                    processSourceFile(entry.name);
                } catch (FatalError e) {
                    compilerContext.reinitialize();
                }
            }
        } else {
            try {
                processSourceFile(path);
            } catch (FatalError e) {
                compilerContext.reinitialize();
            }
        }
    }

    return 0;
}
