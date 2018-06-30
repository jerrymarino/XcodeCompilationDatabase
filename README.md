# Xcode Compilation Database

Generate a Compilation Database from Xcode's build log - nothing more :).

### Context

[Compilation Database](https://clang.llvm.org/docs/JSONCompilationDatabase.html) is a file
format for storing compile commands.
Program language tooling needs a Compilation Databases as input in order to
setup the compiler stack; canonical uses of this format are LibTooling and
clang-c.

This program is mainly used to generate a _Swift_ Compilation Database for
usage in [iCompleteMe](https://github.com/jerrymarino/iCompleteMe), as it
requires `compile_commands.json` to determine how to setup the Swift compiler
for code completion.

## Usage

First, build and install. Optionally, use the install script:

```
./install.sh
```

`tee` build output of a *clean build* to a log, and pass the result to
`XCCompilationDB`.

```
xcodebuild .... | tee /path/to/last_build.log
XCCompilationDB /path/to/last_build.log
```

It outputs `compile_commands.json` to the root of the `CWD`.

## Notes on unstructured log parsing

There are several ways to extract this information from Xcode.
XcodeCompilationDatabase is built on Xcode's unstructured logs for simplicity.
Given the general stability of Xcode's log format, this approach should be
somewhat maintainable.

All known approaches are less than ideal, including this one. *Ideally Xcode
and SwiftPM would stream a parsable log containing tool invocations, and
standard error and standard out, similar to how [the Swift driver
does](https://github.com/apple/swift/blob/master/docs/DriverParseableOutput.rst).*

## Alternatives

There are several other implementations of this on the internet, none of which
are known to have Swift support and work in this capacity.

