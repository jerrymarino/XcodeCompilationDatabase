debug:
	swift build | tee .build/last_build.log

release:
	swift build -c release | tee .build/last_build.log

run:
	swift run | tee .build/last_build.log

test:
	swift test | tee .build/last_build.log

integration-test: debug
	.build/debug/XcodeCompilationDatabase $(PWD)/ExampleLogs/BasicOSX.txt
	.build/debug/XcodeCompilationDatabase $(PWD)/ExampleLogs/ExampleCpp.txt

