module dmdlint.scanner.diag;

import dmdlint.common.diag;

import dmd.errors;
import dmd.console;
import dmd.globals;

Severity toSeverity(Color color) nothrow @nogc @safe pure
{
    switch(color) with(Color)
    {
        case red:
        case brightRed:
            return Severity.error;
        case yellow:
        case brightYellow:
            return Severity.warning;
        case blue:
        case brightBlue:
            return Severity.gagged;
        case cyan:
        case brightCyan:
            return Severity.deprecation;
        case green:
        case brightGreen:
            return Severity.hint;
        default:
            return Severity.message;
    }
}

Location toLocation(Loc loc) nothrow @nogc pure
{
    import core.stdc.string : strlen;
    string filename = (loc.filename)
        ? cast(string) loc.filename[0..strlen(loc.filename)]
        : null;

    return Location(filename, loc.linnum, loc.charnum);
}
