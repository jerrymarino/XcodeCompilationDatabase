//
//  main.m
//  XcodeDepGraph
//
//  Created by Jerry Marino on 5/15/17.
//  Copyright © 2017 SwiftySwiftVim. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import "XCDependencyGraph.h"

// Generate Compile commands based on the XCDependencyGraph output.
// Based on my Xcode reversing article __INSERT_LINK__
int main(int argc, const char * argv[]) {
    NSArray *args = [NSProcessInfo processInfo].arguments;
    if (args.count < 2) {
        printf("%s", [[@[
        @"Generate Compile commands based on the XCDependencyGraph output.",
        @"Usage: [BuildRootURI]",
        @"BuildRootURI: ex:",
        @"__DERIVED_DATA/MyProj-UID/Build/Intermediates/MyProj.build/Debug/MyTarget.build/",
        @"\0"
        ] componentsJoinedByString:@"\n"] cStringUsingEncoding:NSUTF8StringEncoding]);
        return 0;
    }

    // Be quite
    freopen([@"/dev/null" cStringUsingEncoding: NSASCIIStringEncoding], "a+", stderr);

    NSString *buildRoot = [NSProcessInfo processInfo].arguments[1];
    // Create a build graph from output
    NSError *e;
    PBXTargetBuildContext *ctx = [NSClassFromString(@"PBXTargetBuildContext") new];
    XCDependencyGraph *graph = [NSClassFromString(@"XCDependencyGraph") readFromBuildDirectory:buildRoot withTargetBuildContext:ctx error:&e];
    assert(graph);
    assert(e == nil && "Can't create graph");
    
    NSDictionary <NSString *, XCDependencyCommandInvocationRecord *> *records = [graph valueForKey:@"_commandInvocRecordsByIdent"];

    // Build a Compilation Database from the graph
    NSMutableArray <NSDictionary *>*compDB = [NSMutableArray array];
    for (NSString *key in records) {
        XCDependencyCommandInvocationRecord *record = records[key];
        if ([record.identifier hasPrefix:@"CompileSwiftSources"]) {
            // Get the directoy from swiftInvocation
            // Usually this is last in the form of:
            // -working-directory/Path/ToRoot/
            NSArray *swiftCInvocation = record.commandLineArguments;
            NSString *workingDir = nil;
            for (NSString *arg in swiftCInvocation.reverseObjectEnumerator) {
                if ([arg hasPrefix:@"-working-directory"]) {
                    workingDir = [arg stringByReplacingOccurrencesOfString:@"-working-directory" withString:@""];
                    break;
                }
            }
            
            assert(workingDir != nil && "Malformed SwiftC Invocation: missing working directory");
            
            IDEActivityLogSection *log = [record activityLog];
            NSArray <IDEActivityLogSection *>*compileSections = [log subsections];
            for (IDEActivityLogSection *compileSection in compileSections) {
                // Title @"Compile /Path/To/ViewController.swift"
                NSString *detailedDesc = compileSection.commandDetailDescription;
                NSString *sourceFile = [compileSection.title componentsSeparatedByString:@" "][1];
                // Compiler invocation is 3rd
                NSString *compilerInvocation = [detailedDesc componentsSeparatedByString:@"\n"][2];
                [compDB addObject:@{
                                    @"file" : sourceFile,
                                    @"command" : compilerInvocation,
                                    @"directory" : workingDir
                                    }];
            }
        }
    }
    
    // Write the Comp DB
    NSError *jsonError;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:compDB options:NSJSONWritingPrettyPrinted error:&jsonError];
    assert(jsonError == nil && "Invalid DB");
    NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    
    // Write the Comp DB in the current directory with the cargo cult naming convention.
    // This isn't in the spec, but CMake uses it.
    NSString *cargoCultDBName = @"/compile_commands.json";
    NSString *outFile = [[[NSFileManager defaultManager] currentDirectoryPath] stringByAppendingString:cargoCultDBName];
    NSError *writeError;
    [jsonString writeToFile:outFile atomically:NO encoding:NSUTF8StringEncoding error:&writeError];
    return writeError != nil;
}
