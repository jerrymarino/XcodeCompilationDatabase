//
//  CompilationDatabase.h
//  XcodeCompilationDatabase
//
//  Created by April Marino on 5/21/17.
//  Copyright © 2017 SwiftySwiftVim. All rights reserved.
//

#import <Foundation/Foundation.h>

@class XCDependencyCommandInvocationRecord;
@class XCDependencyGraph;

extern NSArray *EntriesForSwiftCRecord(XCDependencyCommandInvocationRecord *record);

extern NSArray *CompilationDatabaseFromGraph(XCDependencyGraph *graph);
