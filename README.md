# Xcode Compilation Database

This program generate a compilation database based on Xcode's build graph.

It loads the data structure, `XCDependencyGraph`, from an Xcode build directory
directory, and writes `compile_commands.json` to the working directory.

The file format written is [Clang's Compilation Database](https://clang.llvm.org/docs/JSONCompilationDatabase.html).

It currently supports Swift only, I wrote this project for [SwiftySwiftVim](https://github.com/jerrymarino/swiftyswiftvim), to generate compilation databases for basic Swift Xcode projects.

**It uses undocumented private frameworks in Xcode**

## Usage

```
XCCompilationDB __DERIVED_DATA/MyProj-UID/Build/Intermediates/MyProj.build/Debug/MyTarget.build/
```
This directory is the directory containing a `dpgh` file ( Dependency Graph )

This should be triggered by Xcode to ensure the comp DB is updated. Trigger
this asynchronously as a build phase.

## Future Ideas:

Support clang, so this can be used for YouCompleteMe and LibTooling and more.

## Alternatives

- XCPretty can generate a Comp DB for clang.

