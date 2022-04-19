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

import containers.slist;

void reportUnusedRule(Module module_)
{
    auto v = new UnusedRuleVisitor(module_);
    module_.accept(v);

    v.reportUnusedImports();
}

private void reportUnusedImports(UnusedRuleVisitor v)
{
    auto isyms = v.importedModules.values
        .chunkBy!"a.sym == b.sym"
        .map!(g => g.map!"tuple(a[0], cast(size_t)a[1])")
        .map!(g => tuple(g.front[0], g.map!"a[1]".sum))
        .filter!"a[1] == 0"
        .map!"a[0]";

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

private struct PublicModuleIterator
{
    Module module_;

    // Perform a simple depth-first search on the imported scopes
    int opApply(int delegate(ref Module) dg)
    {
        SList!Module stack;
        bool[Module] visited;

        stack.insert(module_);

        do
        {
            auto m = stack.front();
            stack.popFront();

            if (m in visited)
                continue;

            visited[m] = true;

            if (auto isc = m.getImportedScopes())
            {
                auto visibilities = m.getImportVisibilities();
                foreach(i, sym; *isc)
                    if (visibilities[i] == Visibility.Kind.public_)
                        if (auto im = sym.isModule())
                            stack.insert(im);
            }

            int res = dg(m);
            if (res) return res;
        } while(!stack.empty);

        return 0;
    }
}

extern(C++) final class UnusedRuleVisitor : Visitor
{
    import dmd.dtemplate : TemplateInstance;

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

    override void visit(TemplateInstance ti)
    {
        // skip template instances from other modules
        if (ti.minst != rootModule || ti.tinst)
            return;

        this.visit(cast(Dsymbol)ti);
    }

    override void visit(Dsymbol sym)
    {
        if (auto mod = sym.getModule())
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

        // add root module and any publicly imported module
        foreach(mod; PublicModuleIterator(i.mod))
            importedModules[mod] = tuple(i, false);
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
}
