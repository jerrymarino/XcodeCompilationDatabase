# Xcode Compilation Database

This program generate a compilation database based on Xcode's build graph.

It loads the data structure, `XCDependencyGraph`, from an Xcode build directory
directory, and writes `compile_commands.json` to the working directory.

The file format written is [Clang's Compilation
Database](https://clang.llvm.org/docs/JSONCompilationDatabase.html).

It currently supports Swift Commands only: I wrote this project for
[SwiftySwiftVim](https://github.com/jerrymarino/swiftyswiftvim), to generate
compilation databases for basic Swift Xcode projects. 

**It uses undocumented private frameworks in Xcode**

## Usage

First, build and install. Optionally, use the install script:

```
./install.sh
```

```
XCCompilationDB __DERIVED_DATA/MyProj-UID/Build/Intermediates/MyProj.build/Debug/MyTarget.build/
```
This directory is the directory containing a `dpgh` file ( Dependency Graph )

### Create a Compilation Database for each build ( like CMake )

You'll need a `Post Build Action` your build.

![whatisapostaction](https://cloud.githubusercontent.com/assets/1245820/26285776/0387c780-3e0b-11e7-9f9f-bb8bba12e3d8.png)

First, create a post action, and **pass environment variables** of the target.

Run the CompilationDatabase program for `builds`. 
```
if [[ -z $SWIFT_OPTIMIZATION_LEVEL ]]; then
    exit 0
fi
XCCompilationDB $TARGET_TEMP_DIR -db_dir $SOURCE_ROOT
```

*note: Xcode does not pass the `$ACTION` to this script, so checking the
`$SWIFT_OPTIMIZATION_LEVEL` is a hacky way to differentiate between builds and
cleans.*


## Future Ideas:

- Support clang, so this can be used for YouCompleteMe and LibTooling and more.

## Alternatives

- XCPretty can generate a Comp DB for clang. Eventually, I hope it will for
  swift too.

