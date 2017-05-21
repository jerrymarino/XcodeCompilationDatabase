#!/bin/bash
xcodebuild -target XcodeCompilationDatabase

echo "Installing to /usr/local/bin"
ditto build/Release/XCCompilationDB /usr/local/bin
