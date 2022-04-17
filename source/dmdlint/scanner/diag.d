module dmdlint.scanner.diag;

import dmdlint.common.diag;

import dmd.errors;
import dmd.console;
import dmd.globals;

import core.stdc.stdarg;

import std.array;

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

/**
 * Context used by the diagnostic handler
 */
struct DiagnosticContext
{
    /**
     * Wether to use console to output diagnostic events. If false, `events` is
     * expected to be appended when an event triggers the diagnostic handler.
     */
    bool console;
    /// List of diagnostic events
    Appender!(Diagnostic[]) events;
}

/**
 * Single instance of the diagnostic context.
 *
 * Note: there is no need to be on TLS since the compiler is single-threaded.
 */
__gshared DiagnosticContext diagnosticContext;

/**
 * Diagnostic handler used by the compiler frontend to handle diagnostic events
 * on compilation.
 */
bool diagnosticHandler(
    const ref Loc loc,
    Color headerColor,
    const(char)* header,
    const(char)* messageFormat,
    va_list args,
    const(char)* prefix1,
    const(char)* prefix2
) nothrow
{
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

    diagnosticContext.events ~= Diagnostic(location, severity, message);

    return true;
}

class FatalError : Error
{
    @safe pure nothrow this(string file, size_t line)
    {
        super("fatal error", file, line, cast(Throwable)null);
    }
}

bool fatalErrorHandler() nothrow
{
    // globally shared storage for fatal errors (garanteed to use one thread)
    __gshared align(2 * size_t.sizeof)
        void[__traits(classInstanceSize, FatalError)] fatalErrorStore;

    static FatalError get()
    {
        return cast(FatalError) fatalErrorStore.ptr;
    }
    auto errorInstance = (cast(FatalError function() @trusted pure nothrow @nogc) &get)();
    import core.lifetime : emplace;
    emplace(errorInstance, __FILE__, __LINE__);

    throw errorInstance;
}
