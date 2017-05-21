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

- (void)hybridSwiftObjCTest {
    // This test data is created off of the example project in
    // TestData/BasiciOSExampleWithCompileCommandHook
    NSString *buildRoot = [TOSTRING(SRCROOT) stringByAppendingString:@"/UnitTests/TestData/ExampleBuildRoot8.3.2"];
    PBXTargetBuildContext *ctx = [NSClassFromString(@"PBXTargetBuildContext") new];
    NSError *e;
    XCDependencyGraph *graph = [NSClassFromString(@"XCDependencyGraph") readFromBuildDirectory:buildRoot withTargetBuildContext:ctx error:&e];
    NSArray *entries = CompilationDatabaseFromGraph(graph);
    
    NSDictionary *appDelegateEntry = nil;
    NSDictionary *monsterEntry =nil;

    NSMutableArray *swiftEntries = [NSMutableArray array];
    NSMutableArray *objCEntries = [NSMutableArray array];
    for (NSDictionary *entry in entries) {
        if ([entry[@"file"] hasSuffix:@".swift"]) {
            [swiftEntries addObject:entry];
        } else if ([entry[@"file"] hasSuffix:@".m"]) {
            [objCEntries addObject:entry];
        }
        
        if ([entry[@"file"] hasSuffix:@"AppDelegate.swift"]) {
            appDelegateEntry = entry;
        } else if ([entry[@"file"] hasSuffix:@"Monster.m"]) {
            monsterEntry = entry;
        }
    }
    XCTAssertNotNil(appDelegateEntry);
    XCTAssertNotNil(monsterEntry);
    XCTAssertEqual(swiftEntries.count, 3);
    XCTAssertEqual(objCEntries.count, 1);
}


@end
