module dmdlint.scanner.diag;

import dmdlint.common.diag;

import dmd.errors;
import dmd.console;

Severity toSeverity(Color color)
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

Location toLocation(Loc loc)
{
    import core.stdc.string : strlen;
    string filename = (loc.filename)
        ? loc.filename[0..strlen(loc.filename)]
        : null;

    return Location(filename, loc.linnum, loc.charnum);
}
