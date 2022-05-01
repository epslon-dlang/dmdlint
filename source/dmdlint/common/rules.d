module dmdlint.common.rules;

enum Rule
{
    compiler, /// compiler related diagnostics
    h1,       /// unused imported module
    h2,       /// already imported module by default
    h3,       /// duplicate imported module
}

string toString(Rule rule)
{
    return [ __traits(allMembers, Rule) ][cast(size_t)rule];
}

unittest {
    assert(toString(Rule.compiler) == "compiler");
    assert(toString(Rule.h2) == "h2");
}
