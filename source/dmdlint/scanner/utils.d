module dmdlint.scanner.utils;

import dmdlint.scanner.compiler;

import std.process;
import std.path;
import std.file;

// FIXME: Make it less OS-dependent
string getDefaultImportPaths()
{
    static immutable DIST_SOURCES = "/usr/share/dmdlint/sources";
    static immutable SYSTEM_LOCAL_SOURCES = "/usr/local/share/dmdlint/sources";

    /*
     * Check for following folders in order:
     * 1. XDG folder
     * 2. Default user folder
     * 3. Default system folder
     * 3.1. /usr/local/share
     * 3.2. /usr/share
     */
    immutable homedir = environment.get("HOME");
    immutable xdg = environment.get("XDG_DATA_HOME", buildPath(homedir, ".local/share"));
    immutable userSources = buildPath(xdg, "dmdlint/sources");

    foreach(sources; [userSources, SYSTEM_LOCAL_SOURCES, DIST_SOURCES])
        if (exists(sources) && compilerSourcesSanityCheck(sources))
            return sources;

    return null;
}
