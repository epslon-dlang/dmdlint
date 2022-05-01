module dmdlint.scanner.diag;

import dmdlint.common.diag;
import dmdlint.common.rules;
import dmdlint.common.utils;

import dmd.errors;
import dmd.console;
import dmd.globals;

import core.stdc.stdarg;
import core.stdc.stdio;

import std.array;
import std.stdio;
import std.algorithm;

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

Color toColor(Severity severity) nothrow @nogc @safe pure
{
    final switch(severity) with(Severity)
    {
        case error:       return Color.red;
        case warning:     return Color.yellow;
        case deprecation: return Color.cyan;
        case gagged:      return Color.blue;
        case hint:        return Color.green;
        case message:     return Color.white;
    }
}

Location toLocation(Loc loc) nothrow @nogc pure
{
    return Location(loc.filename.toDString(), loc.linnum, loc.charnum);
}

/**
 * Context used by the diagnostic handler
 */
struct DiagnosticContext
{
    /**
     * Wether to use console to output diagnostic events. If false, `events` is
     * still expected to be appended when an event triggers the diagnostic
     * handler, unless `reportEvents` is set to `false`.
     */
    bool console;
    /// Wether to enable console colors.
    bool consoleColors;

    /// Wether to report the events to the `events` appender.
    bool reportEvents;
    /// List of diagnostic events.
    Appender!(Diagnostic[]) events;
}

/**
 * Single instance of the diagnostic context.
 *
 * Note: there is no need to be on TLS since the compiler is single-threaded.
 */
__gshared DiagnosticContext diagnosticContext;

private __gshared Console consoleInterface;

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

    bool supplemental = true;
    foreach(c; header.toDString())
        if (c != ' ')
            supplemental = false;

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

    diagnosticWriter(
        Diagnostic(location, severity, Rule.compiler, message, supplemental)
    );
    return true;
}

void diagnosticWriter(in Diagnostic diagnostic) nothrow
{
    with (diagnosticContext)
    {
        if (console)
            diagnosticPrinter(diagnostic);

        if (reportEvents)
            events ~= diagnostic;
    }
}

void diagnosticPrinter(in Diagnostic diagnostic) nothrow
{
    with(diagnostic)
    {
        if (consoleInterface is null)
            consoleInterface = createConsole(core.stdc.stdio.stderr);

        alias stderr = std.stdio.stderr;

        try {
            consoleInterface.setColor(Color.white);
            if (location != Location.init)
            {
                if (location.filename)
                {
                    stderr.write(location.filename);
                    if (location.line)
                    {
                        stderr.writef("(%d", location.line);
                        if (location.col)
                            stderr.writef(":%d", location.col);
                        stderr.write(")");
                    }
                }
            }
            stderr.writef("[%s]: ", toString(diagnostic.rule));

            if (!supplemental) // normal error
            {
                consoleInterface.setColor(severity.toColor);
                consoleInterface.setColorBright(true);
                stderr.writef("%s: ", severity.toString);
                consoleInterface.resetColor();
            } else {
                consoleInterface.resetColor();
                stderr.write("       ");
            }
            stderr.writeln(message);
        } catch (Exception ex)
        {
            assert(0, ex.msg);
        }
    }
}

class FatalError : Error
{
    @safe pure nothrow @nogc this(string file, size_t line)
    {
        super("fatal error", file, line, cast(Throwable)null);
    }
}

bool fatalErrorHandler() nothrow @nogc
{
    template maxAlignment(Ts...)
    if (Ts.length > 0)
    {
        enum maxAlignment =
        {
            size_t result = 0;
            static foreach (T; Ts)
                if (T.alignof > result) result = T.alignof;
            return result;
        }();
    }

    // globally shared storage for fatal errors (garanteed to use one thread)
    __gshared align(maxAlignment!(void*, FatalError.tupleof))
        void[__traits(classInstanceSize, FatalError)] fatalErrorStore = void;

    static FatalError get()
    {
        return cast(FatalError) fatalErrorStore.ptr;
    }
    auto errorInstance = (cast(FatalError function() @trusted pure nothrow @nogc) &get)();
    import core.lifetime : emplace;
    emplace(errorInstance, __FILE__, __LINE__);

    throw errorInstance;
}
