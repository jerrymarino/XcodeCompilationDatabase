//
//  CompilationDatabase.m
//  XcodeCompilationDatabase
//
//  Created by Jerry Marino on 5/21/17.
//  Copyright © 2017 SwiftySwiftVim. All rights reserved.
//

#import "XCDependencyGraph.h"
#import "CompilationDatabase.h"
#import <string>
#include <sstream>
#include <vector>
#include <iterator>

#pragma mark - Helper Utils

inline bool ends_with(std::string const & value, std::string const & ending)
{
    if (ending.size() > value.size()) return false;
    return std::equal(ending.rbegin(), ending.rend(), value.rbegin());
}

template<typename Out>
void split(const std::string &s, char delim, Out result) {
    std::stringstream ss;
    ss.str(s);
    std::string item;
    while (std::getline(ss, item, delim)) {
        *(result++) = item;
    }
}

std::vector<std::string> split(const std::string &s, char delim) {
    std::vector<std::string> elems;
    split(s, delim, std::back_inserter(elems));
    return elems;
}

// Lex a shell  invocation
template<class C = std::vector<std::string>>
C shlex(std::string s)
{
    auto result = C{};
    
    auto accumulator = std::string{};
    auto quote = char{};
    auto escape = bool{};
    
    auto evictAccumulator = [&]() {
        if (!accumulator.empty()) {
            result.push_back(std::move(accumulator));
            accumulator = "";
        }
    };
    
    for (auto c : s) {
        if (escape) {
            escape = false;
            accumulator += c;
        } else if (c == '\\') {
            escape = true;
        } else if ((quote == '\0' && c == '\'') ||
                   (quote == '\0' && c == '\"')) {
            quote = c;
        } else if ((quote == '\'' && c == '\'') ||
                   (quote == '"'  && c == '"')) {
            quote = '\0';
        } else if (!isspace(c) || quote != '\0' ) {
            accumulator += c;
        } else {
            evictAccumulator();
        }
    }
    
    evictAccumulator();
    
    return result;
}

/**
 Extract a swift file from a `swift` invocation.
 
 The compiler is now invoked with all of the partial swift modules to
 create the final swift module. In that case, we will return nil implicitly.
 */
static NSString *SwiftFileInSwiftInvocationRecord(NSString *invocation)
{
    // 1) Find the object file we are compiling.
    // 2) Lookup the path of the object file.
    // Assume that object files correspond to .swift files
    // Typically the object file is at the end, and the corresponding file is at the beginning.
    auto arguments = shlex(std::string([invocation UTF8String]));
    for (auto argIt = arguments.begin(); argIt != arguments.end(); ++argIt) {
        auto components = split(*argIt, '/');
        if (ends_with(*argIt, std::string(".o"))) {
            auto objectName = split(components.at(components.size() - 1), '.').at(0);
            auto objectFileName = objectName + std::string(".swift");
            for (auto &arg : arguments) {
                if (ends_with(arg, objectFileName)) {
                    return [NSString stringWithUTF8String:arg.c_str()];
                }
            }
        }
    }
    return nil;
}

// Xcode runs a clang for each .m/.c/.cxx
static NSArray *EntriesForCompileCRecord(XCDependencyCommandInvocationRecord *record, NSString *workingDir) {
    __block NSString *fileName;
    NSArray *CLIArgs = record.commandLineArguments;
    [CLIArgs enumerateObjectsUsingBlock:^(NSString *_Nonnull arg, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([arg isEqualToString:@"-c"]) {
            fileName = CLIArgs[idx + 1];
            *stop = YES;
        }
    }];

    // This is malformed, but be safe.
    if (!fileName) {
        return @[];
    }
    return @[@{
                 @"file" : fileName,
                 @"command" : [CLIArgs componentsJoinedByString:@" "],
                 @"directory" : workingDir
                 }];
}

// Xcode runs SwiftC which controls swift compilation.
static NSArray *EntriesForSwiftCRecord(XCDependencyCommandInvocationRecord *record) {
    NSMutableArray *entries = [NSMutableArray array];
    // Get the directoy from swiftInvocation
    // Usually this is last in the form of:
    // -working-directory/Path/ToRoot/
    NSArray *swiftCInvocation = record.commandLineArguments;
    NSString *workingDir;
    for (NSString *arg in swiftCInvocation.reverseObjectEnumerator) {
        if ([arg hasPrefix:@"-working-directory"]) {
            workingDir = [arg stringByReplacingOccurrencesOfString:@"-working-directory" withString:@""];
            break;
        }
    }
    
    assert(workingDir != nil && "Malformed SwiftC Invocation: missing working directory");
    
    IDEActivityLogSection *log = [record activityLog];
    NSArray <IDEActivityLogSection *>*compileSections = [log subsections];

    // Enumerate invocations SwiftC makes to the swift compiler.
    for (IDEActivityLogSection *compileSection in compileSections) {
        NSString *detailedDesc = compileSection.commandDetailDescription;
        NSArray *descLines = [detailedDesc componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
        if (descLines.count < 3) {
            // Unknown format
            continue;
        }
        
        // Get the compiler invocation from the description
        NSString *compilerInvocation = descLines[2];
        NSString *sourceFile = SwiftFileInSwiftInvocationRecord(compilerInvocation);
        if (!sourceFile) {
            continue;
        }

        [entries addObject:@{
                             @"file" : sourceFile,
                             @"command" : compilerInvocation,
                             @"directory" : workingDir
                             }];
    }
    return entries;
}

#pragma mark - Public

NSArray *CompilationDatabaseFromGraph(XCDependencyGraph *graph) {
    NSDictionary <NSString *, XCDependencyCommandInvocationRecord *> *records = [graph valueForKey:@"_commandInvocRecordsByIdent"];
    
    // Build a Compilation Database from the graph
    NSMutableArray <NSDictionary *>*compDB = [NSMutableArray array];
    NSString *basePath = graph.basePath ?: @"";
    for (NSString *key in records) {
        XCDependencyCommandInvocationRecord *record = records[key];
        if ([record.identifier hasPrefix:@"CompileSwiftSources"]) {
            [compDB addObjectsFromArray:EntriesForSwiftCRecord(record)];
        } else if ([record.identifier hasPrefix:@"CompileC"]) {
            // Assume the working directoy is the `basePath` of the Xcode project.
            [compDB addObjectsFromArray:EntriesForCompileCRecord(record, basePath)];
        }
    }
    return compDB;
}

