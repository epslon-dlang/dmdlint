module dmdlint.common.diag;

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

/**
 * Diagnostic structure that represents each error reported by the linter
 */
struct Diagnostic
{
    Location loc;      /// location in the source code
    Severity severity; /// diagnostic severity
    string message;    /// description of the diagnosed problem
}
