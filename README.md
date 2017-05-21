# Xcode Compilation Database

This program generates a compilation database based on [Xcode's build
graph](http://jerrymarino.com/2017/05/16/reversing-xcodes-build-graph.html).
It simply loads the build graph then writes out `compile_commands.json`.

[Compilation
Database](https://clang.llvm.org/docs/JSONCompilationDatabase.html) is a file
format for storing compile commands.

Program language tooling needs a Compilation Databases as input in order to
setup the compiler stack; canonical uses are LibTooling and clang-c.

The program is fast enough to run as part of the build pipeline. This is a
requirement for swift projects, because, the (implicit) file dependency graph
changes a lot.

I originally wrote this for
[SwiftySwiftVim](https://github.com/jerrymarino/swiftyswiftvim), to
generate Compilation Databases for Swift and setup YouCompleteMe.

### Features

- Generate a compilation database for Swift and C compilations

**Note: Tested on Xcode 8.3.1 - it uses undocumented  Xcode APIs**

## Usage

First, build and install. Optionally, use the install script:

```
./install.sh
```

It should be able to generate `compile_commands.json`.
```
# Usage: [BuildRootURI] -db_dir /Path/To/Write/compile_commands.json
XCCompilationDB __DERIVED_DATA/MyProj-UID/Build/Intermediates/MyProj.build/Debug/MyTarget.build/
```
This directory is the directory containing a `dpgh` file ( Dependency Graph )

### Create a Compilation Database for each build ( like CMake )

Create a `Post Build Action` in build phase, a script that runs, after the
build. Make sure to **pass the environment variables** of the target.

```
# Run the CompilationDatabase program for builds
if [[ -z $SWIFT_OPTIMIZATION_LEVEL ]]; then
    exit 0
fi
XCCompilationDB $TARGET_TEMP_DIR -db_dir $SOURCE_ROOT
```

*Xcode does not pass the `$ACTION` to this script, so checking the
`$SWIFT_OPTIMIZATION_LEVEL` is a hacky way to differentiate between builds and
cleans.*

![whatisapostaction](https://cloud.githubusercontent.com/assets/1245820/26285776/0387c780-3e0b-11e7-9f9f-bb8bba12e3d8.png)


## Alternatives

- XCPretty can generate a Comp DB for clang. Eventually, it may for swift too.

