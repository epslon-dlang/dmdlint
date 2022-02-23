module dmdlint.app;

import dmdlint.opt;

import std.file;
import std.algorithm.iteration : filter;
import std.stdio;
import std.getopt;

import dmd.frontend: initDMD, deinitializeDMD, parseModule;
import dmd.errors: DiagnosticHandler;
import dmd.globals;

void processSourceFile(string path)
{
    auto parseResult = parseModule(path);
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

    DiagnosticHandler ignoreErrors = (ref _1, _2, _3, _4, _5, _6, _7) => true;

    global.params.errorLimit = 0;
    initDMD(null);
    scope(exit) deinitializeDMD();

    auto files = dirEntries(".", "*.{d,di,dd}", SpanMode.depth)
        .filter!(e => e.isFile);

    foreach (entry; files)
    {
        processSourceFile(entry.name);
    }

    return 0;
}
