import XCTest
import XcodeCompilationDatabaseCore

class LogParsingTests: XCTestCase {

    func testFrontendInvocation() {
        let invocation = "  /Applications/Xcode-9.4.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swift -frontend -c -primary-file /Users/jerrymarino/Projects/SwiftVimTestHost/BasicOSX/BasicOSX/ViewController.swift /Users/jerrymarino/Projects/SwiftVimTestHost/BasicOSX/BasicOSX/AppDelegate.swift -o /Users/jerrymarino/Library/Developer/Xcode/DerivedData/BasicOSX-ewknyqiuzzuhnyahwszezoamdooo/Build/Intermediates.noindex/BasicOSX.build/Debug/BasicOSX.build/Objects-normal/x86_64/ViewController.o -Xcc -working-directory/Users/jerrymarino/Projects/SwiftVimTestHost/BasicOSX"
        guard let entry = Entry.entry(for: shlex(invocation)) else {
            XCTFail()
            return 
        }
        XCTAssertEqual(entry.file,
            "/Users/jerrymarino/Projects/SwiftVimTestHost/BasicOSX/BasicOSX/ViewController.swift")
        XCTAssertEqual(entry.command, invocation)
        XCTAssertEqual(entry.directory,
            "/Users/jerrymarino/Projects/SwiftVimTestHost/BasicOSX")
    }

    func testClangInvocation() {
        let invocation = "/Applications/Xcode-9.4.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/clang -c /Some/Foo.c /Out/Foo.o -Xcc -working-directory/Some"
        guard let entry = Entry.entry(for: shlex(invocation), dirHint: "DIR") else {
            XCTFail()
            return 
        }

        XCTAssertEqual(entry.file, "/Some/Foo.c")
        XCTAssertEqual(entry.command, invocation)
        XCTAssertEqual(entry.directory, "DIR")
    }

    func testClangLogParse() {
        let invocation = "/Applications/Xcode-9.4.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/clang -c /Some/Foo.c /Out/Foo.o"
        let log = """
            cd /Some
            export FOO=Bar
            \(invocation)
        """
        let parsed = parse(log: log)
        guard case let .shell(_, lexed) = parsed[0] else {
            XCTFail()
            return
        }
        XCTAssertEqual(lexed[1], "cd")

        guard case let .entry(_, _, entry) = parsed[2] else {
            XCTFail()
            return
        }
        XCTAssertEqual(entry.file, "/Some/Foo.c")
        // FIXME: Consider stripping off leading spaces of commands
        XCTAssertEqual(entry.command, "  " + invocation)
        XCTAssertEqual(entry.directory, "/Some")

        let entries = getEntries(parsed: parsed)
        XCTAssertEqual(entries.first?.directory,  "/Some")
    }
}
