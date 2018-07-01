#!/bin/bash
make release

echo "Installing to /usr/local/bin"
ditto .build/release/XcodeCompilationDatabase /usr/local/bin/XCCompilationDB 
