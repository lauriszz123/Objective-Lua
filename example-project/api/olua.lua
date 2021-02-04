--[[
	File: olua.lua
	Made by: Laurynas.
	Date: 2021/01/29
]]

local function split (inputstr, sep)
	if sep == nil then
		sep = "%s"
	end
	local t={}
	for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
		table.insert(t, str)
	end
	return t
end

function class(base, init)
	local c = {__version="ObjectiveLua v1.0"}
	if not init and type(base) == 'function' then
		init = base
		base = nil
	elseif type(base) == 'table' then
		for i,v in pairs(base) do
			c[i] = v
		end
		c._base = base
	end
	c.__index = c

	local mt = {}
	mt.__call = function(class_tbl, ...)
		local obj = {}
		setmetatable(obj,c)
		if init then
			init(obj,...)
		else
			if base and base.init then
				base.init(obj, ...)
			end
		end
		return obj
	end
	c.init = init
	c.instanceof = function(self, klass)
		local m = getmetatable(self)
		while m do 
			if m == klass then return true end
			m = m._base
		end
		return false
	end
	setmetatable(c, mt)
	return c
end

local function findchar( str, chr )
	for i=1, #str do
		if str:sub( i, i ) == chr then
			return true
		end
	end
end

local function parseBlock( block )
	local str = ""
	local i = 1
	while #block > 0 do
		local curr = table.remove( block, i )
		if curr == "class" then
			local classstr = ""
			local classname = table.remove( block, i )
			local inherits
			if block[ i ] == "inherits" then
				table.remove( block, i )
				inherits = table.remove( block, i )
			end
			local ends = 0
			local currblock = {}
			while true do
				local curr = table.remove( block, i )
				if curr == "end" then
					if ends == 0 then
						 break
					elseif ends < 0 then
						error( "Missing 'end' keyword in a class: '"..classname.."'!" )
					end
					ends = ends - 1
				end
				currblock[ #currblock + 1 ] = curr
				if curr == "function" then ends = ends + 1 end
				if curr == "while" then ends = ends + 1 end
				if curr == "if" then ends = ends + 1 end
				if curr == "for" then ends = ends + 1 end
			end
			
			local functions = {}
			ends = 0
			
			while #currblock > 0 do
				local curr = table.remove( currblock, 1 )
				if curr == "function" then
					local rawname = table.remove( currblock, 1 )
					local name = ""
					rawname:gsub( "%w+", function( r ) name = r end )
					local b = {}
					
					local arg = ""
					if findchar( rawname, ')' ) == nil then
						while #currblock > 0 do
							local curr = table.remove( currblock, 1 )
							if findchar( curr, ')' ) == true then
								arg = arg .. curr
								break
							end
							arg = arg .. curr
						end
					end
					
					if #arg > 1 then
						b.arguments = arg
					end
					
					while #currblock > 0 do
						local curr = table.remove( currblock, 1 )
						if curr == "end" then
							if ends == 0 then
								 break
							elseif ends < 0 then
								error( "Missing 'end' keyword in a function: '"..rawname.."'!" )
							end
							ends = ends - 1
						end
						if curr == "function" then ends = ends + 1 end
						if curr == "while" then ends = ends + 1 end
						if curr == "if" then ends = ends + 1 end
						if curr == "for" then ends = ends + 1 end
						b[ #b + 1 ] = curr
					end
					
					functions[ name ] = b
				end
			end
		
			local func = ""
		
			if functions[ classname ] then
				local b = functions[ classname ]
				if b[ "arguments" ] ~= nil then
					if inherits then
						classstr = classstr .. classname.."=class(" .. inherits .. ",function( self,"..b[ "arguments" ].." "
					else
						classstr = classstr .. classname.."=class(function( self,"..b[ "arguments" ].." "
					end
					for _, v in ipairs( b ) do
						classstr = classstr .. v .. " "
					end
					classstr = classstr .. "end) "
				else
					if inherits then
						classstr = classstr .. classname.."=class(" .. inherits .. ",function( self ) "
					else
						classstr = classstr .. classname.."=class(function( self ) "	
					end
					for _, v in ipairs( b ) do
						classstr = classstr .. v .. " "
					end
					classstr = classstr .. "end) "
				end
				functions[ classname ] = nil
			end
		
			for fname, body in pairs( functions ) do
				if body.arguments then
					classstr = classstr .. "function " .. classname..":"..fname.."("..body.arguments.." "
				else
					classstr = classstr .. "function " .. classname..":"..fname.."() "
				end
				for _=1, #body do
					classstr = classstr .. body[ _ ] .. " "
				end
				classstr = classstr .. "end "
			end

			classstr = classstr:gsub( "self%s-%(%s-%)", function( s )
				if inherits then
					return inherits..".init(self) "
				else
					error( "class does not inherit." )
				end
			end )

			classstr = classstr:gsub( "self%s-%(", function( s )
				if inherits then
					return inherits..".init(self,"
				else
					error( "Class '"..classname.."' does not inherit other class, self(...) not required!" )
				end
			end )

			str = str .. classstr
		else
			str = str .. curr .. " "
		end
	end
	str = str:gsub( "new %w+%(", function( s )
		s = s:gsub( "new", "" )
		return s
	end )
	str = str:gsub( "%w+ instanceof %w+", function( s )
		local spl = split( s, " " )
		return spl[ 1 ]..":instanceof("..spl[3]..")"
	end )
	return str
end

local parse = function( program, name )
	program = program:gsub( "(%-%-%[%[(.-)%]%])", "" )
	program = program:gsub( "(%-%-(.-)(\n))", "" )
	--print( program )
	program = split( program, " \t\n\r" )
	local parsed = parseBlock( program )
	local func, err = loadstring( parsed, name )
	if not func then error( err ) end
	setfenv( func, _G )
	return func
end

local requires = {}
local orequire = require

function require( ... )
	local str = "classes."..({ ... })[ 1 ]
	str = str:gsub( "%.", "/" ) .. ".olua"
	if love.filesystem.getInfo( str ) ~= nil then
		if requires[ str ] == nil then
			local file = love.filesystem.newFile( str )
			local func = parse( file:read(), str )
			local ok, err = pcall( func )
			if not ok then error( err ) end
			requires[ str ] = true
			return err
		end
	else
		return orequire( ... )
	end
end

require "Main"

if Main then
	return Main()
else
	error( "Main class not found!" )
end