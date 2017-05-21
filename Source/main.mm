//
//  main.m
//  XcodeDepGraph
//
//  Created by Jerry Marino on 5/15/17.
//  Copyright © 2017 SwiftySwiftVim. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "XCDependencyGraph.h"
#import "CompilationDatabase.h"

// Generate Compile commands based on the XCDependencyGraph output.
// Based on my Xcode reversing article __INSERT_LINK__
int main(int argc, const char * argv[]) {
    NSArray *args = [NSProcessInfo processInfo].arguments;
    if (args.count < 2) {
        printf("%s", [[@[
        @"Generate Compile commands based on the XCDependencyGraph output.",
        @"Usage: [BuildRootURI] -db_dir /Path/To/Write/compile_commands.json",
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
    
    NSArray *compDB = CompilationDatabaseFromGraph(graph);
    // Write the Comp DB
    NSError *jsonError;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:compDB options:NSJSONWritingPrettyPrinted error:&jsonError];
    assert(jsonError == nil && "Invalid DB");
    NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    
    // Write the Comp DB in the current directory with the cargo cult naming convention.
    // This isn't in the spec, but CMake uses it.
    NSString *cargoCultDBName = @"/compile_commands.json";
    // Use the db_dir option if available
    NSString *outDir = [[NSUserDefaults standardUserDefaults] valueForKey:@"db_dir"] ?: [[NSFileManager defaultManager] currentDirectoryPath];
    NSString *outFile = [outDir stringByAppendingString:cargoCultDBName];
    NSError *writeError;
    [jsonString writeToFile:outFile atomically:NO encoding:NSUTF8StringEncoding error:&writeError];
    return writeError != nil;
}
