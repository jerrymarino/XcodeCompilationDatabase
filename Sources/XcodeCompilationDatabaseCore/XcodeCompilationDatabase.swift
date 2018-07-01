import Foundation

let doubleQuote = "\""
let singleQuote = "\'"
let unitQuote = ""

/// Lex parts of a shell command.
public func shlex(_ input: String) -> [String] {
    var result: [String] = []
   
    var accumulator = ""
    var quote = unitQuote
    var escape = true
    
    let terminateLexeme = {
        if accumulator != "" {
            result.append(accumulator)
            accumulator = "";
        }
    }

    for character in input {
        let str = String(character)
        if escape {
            escape = false;
            accumulator += str
        } else if str == "\\" {
            escape = true;
        } else if (quote == unitQuote && str == singleQuote) ||
                   (quote == unitQuote && str == unitQuote) {
            quote = str
        } else if (quote == singleQuote && str == singleQuote) ||
                   (quote == doubleQuote  && str == doubleQuote) {
            quote = unitQuote
        } else if str != " " || quote != unitQuote {
            accumulator += String(str)
        } else {
            terminateLexeme()
        }
    }
    terminateLexeme()
    return result;
}

/// This detects tools by name.
/// Consider determining tools from the names of actions in Xcodes log, for
/// this doesn't work when the user sets a custom CC or SWIFT_EXEC with a name
/// other than the canonical name.

/// Check if the first non " " argument is clang
func isCC(lexed: [String]) -> Bool {
    for arg in lexed {
        if arg == " " {
            continue
        }
        // Naieve checking for clanginess
        return arg.hasSuffix("clang") || arg.hasSuffix("clang++")
    }
    return false
}

/// Frontend invocations
/// Currently, it uses frontend invocations to prevent duplication of Swift's
/// driver. ( consider using `swiftc` instead ) 
func isSwiftFrontend(lexed: [String]) -> Bool {
    for arg in lexed {
        if arg == " " {
            continue
        }
        /// Naieve checking for swiftieness
        return arg.hasSuffix("swift")
    }
    return false
}

func swiftFileInSwiftInvocation(lexed: [String]) -> String? {
    var swiftSources: [String] = []
    var objectFile: String = ""
    for arg in lexed {
        if arg.hasSuffix(".swift") {
            swiftSources.append(arg)
        } else if arg.hasSuffix(".o") {
            objectFile = arg
        }
    }

    if objectFile == "" {
        return swiftSources.first
    }

    // 1) Find the object file we are compiling.
    // 2) Lookup the path of the object file.
    let components = objectFile.components(separatedBy: "/")
    // Several fatal assumptions about Xcode's log output here.
    // FIXME: make this more sloppy/safe
    let objectName = components[components.count - 1].components(separatedBy: ".")[0]
    let swiftFile = objectName + ".swift"

    /// If the file is not in the list, then return the first file
    return swiftSources.filter { $0.hasSuffix(swiftFile) }.first ?? swiftSources.first
}

func workingDirectoryInSwiftInvocation(lexed: [String]) -> String? {
     return lexed.reversed().compactMap {
         arg in
         arg.hasPrefix("-working-directory") ?
            arg.replacingOccurrences(of:"-working-directory", with: "") : nil
     }.lazy.first
}

// Mark - Parsing

public struct Entry: Codable {
    public let file: String
    public let command: String
    public let directory: String
}

extension Entry {
    public static func entry(for lexed: [String], dirHint: String? = nil) -> Entry? {
        let line = lexed.joined(separator: " ")
        if isSwiftFrontend(lexed: lexed) {
            guard
              let file = swiftFileInSwiftInvocation(lexed: lexed),
              let dir = workingDirectoryInSwiftInvocation(lexed: lexed) else {
                  return nil
              }
              return Entry(file: file, command: line, directory: dir)
        }
        if isCC(lexed: lexed) {
            let firstFile = lexed.enumerated().compactMap {
                (idx, arg) -> String? in
                guard arg == "-c" else { return nil }
                return lexed[idx + 1]
            }.lazy.first
            guard
                let file = firstFile,
                let dirHint = dirHint else { return nil }
            return Entry(file: file, command: line, directory: dirHint)
        }

        return nil
    }
}

public enum ParsedNode {
    // Save the entire context for convenience.
    case shell(line: String, lexed: [String])
    case entry(line: String, lexed: [String], entry: Entry)
}

/// Xcode thankfully emits the working dir of clang and env vars
/// in the log
/// __SPACES__ export a=b
/// __SPACES__ cd /Path/To/WorkingDir
func getPreviousCDAction(parsed: [ParsedNode]) -> String? {
    for node in parsed {
        // If we're looping backwards and hit a non shell command,
        // we've gone too far. This is an error condition and really,
        // it'd be better if the program was written in a way that
        // didn't require this in the first place.
        guard case let .shell(_, lexed) = node else {
            return nil
        }
        // __SPACES__ cd /Path/To/WorkingDir
        if lexed.count > 2, lexed[1] == "cd" {
            return lexed[2]
        }
    }
    return nil
}

/// Parse a log into a fully serialized representation
public func parse(log: String) -> [ParsedNode] {
    // Consider moving this into shlex
    let lines = log.components(separatedBy: "\n")
    return lines.reduce(into: [ParsedNode]()) {
        accum, line in
        let lexed = shlex(line)
        if isSwiftFrontend(lexed: lexed) {
            if let entry = Entry.entry(for: lexed) {
                accum.append(.entry(line: line, lexed: lexed, entry: entry))
            }
        } else if isCC(lexed: lexed) {
            // We need to look back at the previous 
            guard let cdAction = getPreviousCDAction(parsed: accum) else {
                print("warning: unexpected usage of clang")
                return
            }
            if let entry = Entry.entry(for: lexed, dirHint: cdAction) {
                accum.append(.entry(line: line, lexed: lexed, entry: entry))
            }
        } else if lexed.first == " " {
            /// Parse fragments of shell commands in Xcode.
            /// Assume that Xcode is putting spaces in the front of commands.
            accum.append(.shell(line: line, lexed: lexed))
        }
    }
}

public func getEntries(parsed: [ParsedNode]) -> [Entry] {
    return parsed.compactMap {
        guard case let .entry(_, _, entry) = $0 else {
            return nil
        }
        return entry
    }
}

/// Mark - Utils

public func writeEntries(entries: [Entry], to path: String) throws {
    let encoder = JSONEncoder()
    let data = try encoder.encode(entries)
    try data.write(to: URL(fileURLWithPath: path), options: .atomic)
}

