module dmdlint.scanner.app;

import dmdlint.common.scanopt;
import dmdlint.common.utils;
import dmdlint.common.diag;
import dmdlint.scanner.compiler;
import dmdlint.scanner.diag;

import std.file;
import std.algorithm;
import std.stdio;
import std.getopt;
import std.array;
import std.functional;

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
    ScanOptions options;
    bool readStdin;

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

        with (nappopt.get())
        {
            options.files = files;
            options.importPaths = importPaths;
            readStdin = stdin;
        }
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
        } catch (FatalError e) {
            reinitCompilerContext();
        }
    }

    return 0;
}
