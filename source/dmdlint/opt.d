module dmdlint.opt;

struct Options {
    bool singleInstance;
    string[] sourcePaths;
    string[] importPaths;

    enum DaemonMode {
        watch,
        lsp
    }

    bool daemon;
    DaemonMode daemonMode;
}
