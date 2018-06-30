import XcodeCompilationDatabaseCore
import Foundation

/// TODO:
/// - Allow selection of the output path and input log
/// - Read standard input
/// - Merge previous compile commands database

let outPath = FileManager.default.currentDirectoryPath 
    + "/compile_commands.json"

guard CommandLine.arguments.count > 1 else {
    print("""
          usage: /path/to/xcodebuild.log
          """)
    exit(0)
}

let logPath = CommandLine.arguments[1]

do {
    let log = try String(contentsOf: URL(fileURLWithPath: logPath), encoding: .utf8)
    let parsed = parse(log: log)
    let entries = getEntries(parsed: parsed)
    try writeEntries(entries: entries, to: outPath)
} catch {
    fatalError(error.localizedDescription)
}
