module dmdlint.scanner.rules.unused;

import dmdlint.common.utils;
import dmdlint.common.diag;
import dmdlint.scanner.diag;

import dmd.visitor;
import dmd.dmodule;
import dmd.dimport;
import dmd.dsymbol;
import dmd.statement;
import dmd.common.outbuffer;
import dmd.id;

import std.typecons;
import std.algorithm;
import std.format;
import std.experimental.logger;

void reportUnusedRule(Module module_)
{
    auto v = new UnusedRuleVisitor(module_);
    module_.accept(v);

    v.reportUnusedImports();
}

private void reportUnusedImports(UnusedRuleVisitor v)
{
    auto isyms = v.importedModules.values
        .filter!(im => !im.used)
        .map!(im => im.sym);
    foreach(i; isyms)
    {
        OutBuffer buf;
        i.mod.fullyQualifiedName(buf);
        auto name = buf[];

        diagnosticWriter(Diagnostic(
                i.mod.loc.toLocation,
                Severity.hint,
                format!"Unused imported module '%s'"(name)
            ));
    }
}

/*
TODO: Compiler need to export public modules
private struct PublicModuleIterator
{
    this(Module module_)
    {
        stack.insert(module_);
    }

    int opApply(int delegate(ref Module) dg)
    {
        int res;

        while(!stack.empty)
        {

        }
    }

    Module cur;
    SList!Module stack;
}
*/

extern(C++) final class UnusedRuleVisitor : Visitor
{
    alias visit = Visitor.visit;

    Tuple!(Import, "sym", bool, "used")[Module] importedModules;
    Module rootModule;

    this(Module rootModule) {
        this.rootModule = rootModule;
    }

    override void visit(Module m)
    {
        if (m.members)
            foreach(sym; *m.members)
                sym.accept(this);
    }

    private Module getImportModule(Module mod)
    {
        if (!mod
            || mod.importedFrom is null
            || mod.importedFrom is rootModule
            || mod.importedFrom is mod)
            return mod;

        return getImportModule(mod.importedFrom);
    }

    override void visit(Dsymbol sym)
    {
        // ignore import symbols
        if(sym.isImport())
            return;

        // ignore non-scope symbols that are not imported
        if (!sym.isImportedSymbol() && !sym.isScopeDsymbol())
            return;

        if (auto mod = sym.getAccessModule())
            if(auto tup = getImportModule(mod) in importedModules)
                tup.used = true;
    }

    override void visit(Import i)
    {
        // ignore non-private import
        if (i.visibility.kind != Visibility.Kind.private_)
            return;

        // ignore special object module import
        if (i.id == Id.object)
            return;

        // add root module
        if (i.mod)
            importedModules[i.mod] = tuple(i, false);

        // add any publicly imported module
        /* foreach(mod; PublicModuleIterator(i.mod)) */
        /*     importedModules[mod] = tuple(i, false); */
    }
}
