//
//  UnitTests.m
//  UnitTests
//
//  Created by April Marino on 5/21/17.
//  Copyright © 2017 SwiftySwiftVim. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "XCDependencyGraph.h"
#import "CompilationDatabase.h"

@interface UnitTests : XCTestCase

@end

@implementation UnitTests

#define STRINGIFY(x) @#x
#define TOSTRING(x) STRINGIFY(x)

- (void)testSwiftFlagExtraction {
    NSString *swiftKey = @"CompileSwiftSources normal x86_64 com.apple.xcode.tools.swift.compiler";
    NSString *buildRoot = [TOSTRING(SRCROOT) stringByAppendingString:@"/UnitTests/TestData/ExampleBuildRoot8.3.2"];
    PBXTargetBuildContext *ctx = [NSClassFromString(@"PBXTargetBuildContext") new];
    NSError *e;
    XCDependencyGraph *graph = [NSClassFromString(@"XCDependencyGraph") readFromBuildDirectory:buildRoot withTargetBuildContext:ctx error:&e];    
    NSDictionary <NSString *, XCDependencyCommandInvocationRecord *> *records = [graph valueForKey:@"_commandInvocRecordsByIdent"];
    XCDependencyCommandInvocationRecord *swiftCRecord = records[swiftKey];
    NSArray *entries = EntriesForSwiftCRecord(swiftCRecord);
    
    NSDictionary *appDelegateEntry;
    NSMutableArray *swiftEntries = [NSMutableArray array];
    for (NSDictionary *entry in entries) {
        if ([entry[@"file"] hasSuffix:@".swift"]) {
            [swiftEntries addObject:entry];
        }
        if ([entry[@"file"] hasSuffix:@"AppDelegate.swift"]) {
            appDelegateEntry = entry;
        }
    }
    XCTAssertNotNil(appDelegateEntry);
    XCTAssertEqual(swiftEntries.count, 3);
    
}


@end
