module dmdlint.common.diag;

import dmdlint.common.rules;

/**
 * Location structure that represents a location within source code
 */
struct Location
{
    string filename; /// file name
    size_t line;     /// line number
    size_t col;      /// column number
}

/**
 * Severity enumeration that represents severity levels of the diagnosed code
 */
enum Severity
{
    message,     /// normal message
    hint,        /// suggestions
    warning,     /// warnings
    deprecation, /// deprecation messages
    error,       /// errors
    gagged,      /// gagged errors
}

string toString(Severity severity) @nogc nothrow @safe pure
{
    final switch(severity) with(Severity)
    {
        case message:     return "Message";
        case hint:        return "Hint";
        case warning:     return "Warning";
        case deprecation: return "Deprecation";
        case error:       return "Error";
        case gagged:      return "Gagged";
    }
}

/**
 * Diagnostic structure that represents each error reported by the linter
 */
struct Diagnostic
{
    Location location; /// location in the source code
    Severity severity; /// diagnostic severity
    Rule rule;         /// diagnostic rule id
    string message;    /// description of the diagnosed problem
    bool supplemental; /// wether its a supplemental diagnostic
}
