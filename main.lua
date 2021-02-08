require "olua"
io.stdout:setvbuf("no")

local outs = {}

function out( value )
	table.insert( outs, value )
end

local function createTestCase( name, capture, func, ... )
	local status = "("..name..") PASSED!"
	local failed = false
	local ok, err = pcall( func )
	local ins = { ... }
	local expect
	if capture then
		expect = table.remove( ins, 1 )
	end
	if not ok then
		if capture == true then
			if expect ~= err then
				status = "("..name..") FAILED: expected different error, got: "..err
			end
		else
			failed = true
			status = "("..name..") FAILED: "..err
		end
	end
	
	if failed == false then
		for i=1, #ins do
			if ins[ i ] ~= outs[ i ] then
				status = "("..name..") FAILED: Inputs do not match Outputs."
				break
			end
		end
	end

	outs = {}

	return status
end

print( createTestCase( "testcase-class-1", false, function()
	require "testcase-class-1"
end, "test", "test2" ) )

print( createTestCase( "testcase-class-end", true, function()
	require "testcase-class-end"
end, "<classes/testcase-class-end.olua> expected class constructor in class: Test" ) )

print( createTestCase( "testcase-user-pgimeno-fancy-strings", false, function()
	require "testcase-user-pgimeno-fancy-strings"
end, [====[
the end is near
]====], [==[
--[[
if only...
]]
]==], [==[
		the end is near
		]==], [===[
		--[[
		if only...
		]]
		]===] ) )

print( createTestCase( "testcase-user-pgimeno-observed-fails", false, function()
	require "testcase-user-pgimeno-observed-fails"
end, "--", "--", "test", "test", "test2", "test2" ) )

print( createTestCase( "testcase-user-pgimeno-string-errors", false, function()
	require "testcase-user-pgimeno-string-errors"
end, "The end is near", "The    TITLE    is this", "The end is near" ) )

print( createTestCase( "testcase-inherits-not-found", true, function()
	require "testcase-inherits-not-found"
end, "<classes/testcase-inherits-not-found.olua> Class 'testcase_inheritance' does not inherit other class, self(...) not required!" ) )

print( createTestCase( "testcase-class-inheritance-failure", true, function()
	require "testcase-class-inheritance-failure"
end, "<classes/testcase-class-inheritance-failure.olua> inheritance expected, got keyword 'function'." ) )

print( createTestCase( "testcase-big-string", false, function()
	require "testcase-big-string"
end, [[test
string
big
]], [[test
		string
		big
		]], [[test
		string
		big
		]
		kull
		[ok]
		]], [===[test
		string
		big
		]
		kull
		[ok]
		]===] ) )

love.event.quit()
