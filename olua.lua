--[[
	File: olua.lua
	Made by: Laurynas.
	Date: 2021/01/29
]]

local function split(inputstr, sep)
	if sep == nil then sep = "%s" end
	local t={}
	for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
		table.insert(t, str)
	end
	return t
end

function class(base, init)
	local c = {__version="Objective Lua v2.6"}
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

local function input( prog, f )
	local i = 1
	return {
		next = function()
			local v = prog:sub( i, i )
			i = i + 1
			return v
		end;
		peek = function()
			return prog:sub( i, i )
		end;
		eof = function()
			return i > #prog
		end;
		filename = function()
			return f
		end;
	}
end

local function tokenizer( prog )
	local function white( s )
		return s:match( "[\t\n\r ]" ) ~= nil
	end
	local function idstart( s )
		return s:match( "[a-zA-Z_]" ) ~= nil
	end
	local function id( s )
		return s:match( "[a-zA-Z_0-9%.:]" ) ~= nil
	end
	local function num( s )
		return s:match( "[0-9xXp%.i%-a-fA-F]" ) ~= nil
	end
	local function nums( s )
		return s:match( "[0-9]" ) ~= nil
	end
	local function op( s )
		return s:match( "[<=>%+%-%%^/%*~]" ) ~= nil
	end
	local function dots( s )
		return s:match( "[%.]" ) ~= nil
	end
	local function dowhile( func )
		local str = ""
		while prog.eof() == false and func( prog.peek() ) do
			str = str .. prog.next()
		end
		return str
	end
	local function strf( e )
		local str = ""
		str = str .. prog.next()
		local isback = 0
		str = str .. dowhile( function( p )
			isback = isback - 1
			if p == "\\" then
				isback = 2
				return true
			end
			if p == e and isback <= 0 then
				return false
			end
			return true
		end )
		str = str .. prog.next()
		return str
	end
	local function _n()
		dowhile( white )
		local p = prog.peek()
		if idstart( p ) then return dowhile( id ) end
		if nums( p ) then return dowhile( num ) end
		if p == "[" then
			local str = ""
			local long = 0
			str = str .. prog.next()
			if prog.peek() == "=" then
				--str = str .. "="
				while prog.eof() == false do
					if prog.peek() == "[" then
						break
					elseif prog.peek() == "=" then
						str = str .. prog.next()
						long = long + 1
					else
						error( "<"..toks.filename().."> long string start not found.", 0 )
					end
				end
			end
			if prog.peek() == "[" then
				str = str .. prog.next()
				while prog.eof() == false do
					if prog.peek() == "]" then
						str = str .. prog.next()
						if prog.peek() == "=" then
							for i=1, long do
								if prog.next() == "=" then
									str = str .. "="
								else
									error( "<"..toks.filename().."> long string end not found.", 0 )
								end
							end
							long = 0
						end
						if prog.peek() == "]" then
							str = str .. prog.next()
							if long == 0 then
								break
							end
						end
					else
						str = str .. prog.next()
					end
				end
			end
			return str
		end
		if p == "'" or p == '"' then return strf( p ) end
		if p == "-" then
			local last = prog.next()
			p = prog.peek()
			local long = 0
			if p == "-" then
				prog.next()
				if prog.peek() == "[" then
					prog.next()
					if prog.peek() == "=" then
						while prog.eof() == false do
							if prog.peek() == "[" then
								break
							elseif prog.peek() == "=" then
								prog.next()
								long = long + 1
							else
								error( "<"..toks.filename().."> long comment start not found.", 0 )
							end
						end
					end
					if prog.peek() == "[" then
						while prog.eof() == false do
							local p = prog.next()
							if p == "]" then
								if prog.peek() == "=" then
									for i=1, long do
										if prog.peek() == "=" then
											prog.next()
										else
											error( "<"..toks.filename().."> long comment end not found.", 0 )
										end
									end
									long = 0
								end
								if prog.peek() == "]" then
									prog.next()
									if long == 0 then
										break
									end
								end
							end
						end
					else
						while prog.eof() == false do
							local p = prog.next()
							if p:match( "[\n\r]" ) ~= nil then
								break
							end
						end
					end
					return ""
				else
					while prog.eof() == false do
						local p = prog.next()
						if p:match( "[\n\r]" ) ~= nil then
							break
						end
					end
					return ""
				end
			end
			return last
		end
		if op( p ) then return dowhile( op ) end
		if dots( p ) then
			local dot = prog.next()
			if nums( prog.peek() ) then
				return dot..dowhile( num )
			else
				return dot..dowhile( dots )
			end
		end
		return prog.next()
	end
	local curr
	return {
		next = function()
			local c = curr or _n()
			curr = nil
			return c
		end;
		peek = function()
			if curr then
				return curr
			else
				curr = _n()
				return curr
			end
		end;
		eof = prog.eof;
		filename = prog.filename;
	}
end

local function parse( toks )
	local function parseTable()
		local str = ""
		local c = 0
		while toks.eof() == false do
			local p = toks.next()
			if p == "{" then c = c + 1 end
			if p == "}" and c <= 0 then
				str = str .. p .. " "
				break
			elseif p == "}" then
				c = c - 1
			end
			str = str .. p .. " "
		end
		return str
	end
	local function parseWhileTableArgs()
		local str = ""
		local c = 0
		toks.next()
		while toks.eof() == false do
			local p = toks.next()
			if p == "[" then c = c + 1 end
			if p == "]" and c <= 0 then
				break
			elseif p == "]" then
				c = c - 1
			end
			str = str .. p .. " "
		end
		return str
	end
	function parseWhileArgs()
		local str = ""
		local c = 0
		toks.next()
		while toks.eof() == false do
			local p = toks.next()
			if p == "(" then c = c + 1 end
			if p == ")" and c <= 0 then
				break
			elseif p == ")" then
				c = c - 1
			end
			str = str .. p .. " "
		end
		return str
	end
	local function parseExpr()
		local expr = ""
		while toks.eof() == false do
			local a1 = toks.next()
			if a1 == "(" then
				a1 = a1 .. parseExpr()
				if toks.next() ~= ")" then
					error( "<"..toks.filename().."> expression parse fail, expected ')'.", 0 )
				else
					a1 = a1 .. ") "
				end
			end
			if a1 == "{" then
				a1 = a1 .. parseTable()
			end
			if a1 == "function" then
				a1 = a1 .. "("..parseWhileArgs()..") "..parseWhileEnd().."end "
			end
			if toks.peek() == "." or toks.peek() == ":" then
				a1 = a1 .. toks.next()
				a1 = a1 .. toks.next() .. " "
			end
			if toks.peek() == "[" then
				while toks.eof() == false do
					a1 = a1 .."["..parseWhileTableArgs().."]"
					if toks.peek() ~= "[" then
						break
					end
				end
			end
			if toks.peek() == "(" then
				a1 = a1 .. "("..parseWhileArgs()..") "
			end
			if toks.peek():match( "[%+%-%*^%%=~<>]" ) ~= nil then
				expr = expr .. a1.." "..toks.next().." "
			else
				expr = expr .. a1 .. " "
				break
			end
		end
		return expr
	end

	function parseWhileEnd()
		local str = ""
		local ec = 0
		local curr = 0
		while toks.eof() == false do
			local p = toks.next()
			if p == "if" then
				str = str .. p .. " "
				ec = ec + 1
				curr = curr + 1
			elseif p == "for" then
				str = str .. p .. " "
				ec = ec + 1
				curr = curr + 1
			elseif p == "function" then
				str = str .. p .. " "
				ec = ec + 1
				curr = curr + 1
			elseif p == "do" then
				str = str .. p .. " "
				if curr <= 0 then
					ec = ec + 1
				end
				curr = curr - 1
			elseif p == "end" and ec == 0 then
				break
			else
				if p == "end" then
					ec = ec - 1
				end
				local v = {p}
				while toks.eof() == false do
					while toks.eof() == false do
						if toks.peek() == "[" then
							v[ #v ] = v[ #v ] .. "[" .. parseWhileTableArgs() .. "]"
						else
							break
						end
					end
					if toks.peek() == "," then
						toks.next()
						str = str .. v[ #v ] .. ","
					else
						str = str .. v[ #v ] .. " "
						break
					end
					v[ #v + 1 ] = toks.next()
				end
				if toks.peek() == "+=" then
					toks.next()
					str = str .. "="
					for i=1, #v do
						str = str.. v[ i ] .. "+(" .. parseExpr() .. ") "
						if toks.peek() == "," then
							toks.next()
							str = str .. ", "
						else
							break
						end
					end
				elseif toks.peek() == "-" then
					local s = toks.next()
					if toks.peek() == "=" then
						toks.next()
						str = str .. "="
						for i=1, #v do
							str = str.. v[ i ] .. "-(" .. parseExpr() .. ") "
							if toks.peek() == "," then
								toks.next()
								str = str .. ", "
							else
								break
							end
						end
					else
						str = str..s
					end
				elseif toks.peek() == "*=" then
					toks.next()
					str = str .. "="
					for i=1, #v do
						str = str.. v[ i ] .. "*(" .. parseExpr() .. ") "
						if toks.peek() == "," then
							toks.next()
							str = str .. ", "
						else
							break
						end
					end
				elseif toks.peek() == "/=" then
					toks.next()
					str = str .. "="
					for i=1, #v do
						str = str.. v[ i ] .. "/(" .. parseExpr() .. ") "
						if toks.peek() == "," then
							toks.next()
							str = str .. ", "
						else
							break
						end
					end
				elseif toks.peek() == "^=" then
					toks.next()
					str = str .. "="
					for i=1, #v do
						str = str.. v[ i ] .. "^(" .. parseExpr() .. ") "
						if toks.peek() == "," then
							toks.next()
							str = str .. ", "
						else
							break
						end
					end
				elseif toks.peek() == "%=" then
					toks.next()
					str = str .. "="
					for i=1, #v do
						str = str.. v[ i ] .. "%(" .. parseExpr() .. ") "
						if toks.peek() == "," then
							toks.next()
							str = str .. ", "
						else
							break
						end
					end
				end
			end
		end
		return str
	end

	local str = ""
	while toks.eof() == false do
		local p = toks.peek()
		if p == "class" then
			toks.next()
			local classstr = ""
			local classname = toks.next()
			local inherits
			if toks.peek() == "inherits" then
				toks.next()
				inherits = toks.next()
				if inherits == "function" then
					error( "<"..toks.filename().."> inheritance expected, got keyword 'function'.", 0 )
				end
			end
			local functions = {}
			while toks.eof() == false do
				local p = toks.next()
				if p == "function" then
					local fname = toks.next()
					local args = parseWhileArgs()
					local body = parseWhileEnd()
					functions[ fname ] = {args, body}
				else
					if #p > 0 then
						if p == "end" then
							break
						else
							error( "<"..toks.filename().."> Expected 'end' for class: "..classname, 0 )
						end
					end
				end
			end
			if functions[ classname ] then
				if inherits then
					if #functions[ classname ][ 1 ] == 0 then
						classstr = classstr .. classname .. "=class("..inherits..",function(self) "..functions[ classname ][ 2 ].."end) "
					else
						classstr = classstr .. classname .. "=class("..inherits..",function(self,"..functions[ classname ][ 1 ]..") "..functions[ classname ][ 2 ].."end) "
					end
				else
					if #functions[ classname ][ 1 ] == 0 then
						classstr = classstr .. classname .. "=class(function(self) "..functions[ classname ][ 2 ].."end) "
					else
						classstr = classstr .. classname .. "=class(function(self,"..functions[ classname ][ 1 ]..") "..functions[ classname ][ 2 ].."end) "
					end
				end
				functions[ classname ] = nil
			else
				error( "<"..toks.filename().."> expected class constructor in class: "..classname, 0 )
			end
			for k, v in pairs( functions ) do
				classstr = classstr .. "function "..classname..":"..k.."("..v[1]..") "..v[2].."end "
			end
			classstr = classstr:gsub( "self%s-%(%s-%)", function( s )
				if inherits then
					return inherits..".init(self) "
				else
					error( "<"..toks.filename().."> Class '"..classname.."' does not inherit other class, self(...) not required!", 0 )
				end
			end )
			classstr = classstr:gsub( "self%s-%(", function( s )
				if inherits then
					return inherits..".init(self,"
				else
					error( "<"..toks.filename().."> Class '"..classname.."' does not inherit other class, self(...) not required!", 0 )
				end
			end )
			str = str .. classstr
		else
			local v = {}
			while toks.eof() == false do
				v[ #v + 1 ] = toks.next()
				while toks.eof() == false do
					if toks.peek() == "[" then
						v[ #v ] = v[ #v ] .. "[" .. parseWhileTableArgs() .. "]"
					else
						break
					end
				end
				if toks.peek() == "," then
					toks.next()
					str = str .. v[ #v ] .. ","
				else
					str = str .. v[ #v ] .. " "
					break
				end
			end
			if toks.peek() == "+=" then
				toks.next()
				str = str .. "="
				for i=1, #v do
					str = str.. v[ i ] .. "+(" .. parseExpr() .. ") "
					if toks.peek() == "," then
						toks.next()
						str = str .. ", "
					else
						break
					end
				end
			elseif toks.peek() == "-" then
				local s = toks.next()
				if toks.peek() == "=" then
					toks.next()
					str = str .. "="
					for i=1, #v do
						str = str.. v[ i ] .. "-(" .. parseExpr() .. ") "
						if toks.peek() == "," then
							toks.next()
							str = str .. ", "
						else
							break
						end
					end
				else
					str = str..s
				end
			elseif toks.peek() == "*=" then
				toks.next()
				str = str .. "="
				for i=1, #v do
					str = str.. v[ i ] .. "*(" .. parseExpr() .. ") "
					if toks.peek() == "," then
						toks.next()
						str = str .. ", "
					else
						break
					end
				end
			elseif toks.peek() == "/=" then
				toks.next()
				str = str .. "="
				for i=1, #v do
					str = str.. v[ i ] .. "/(" .. parseExpr() .. ") "
					if toks.peek() == "," then
						toks.next()
						str = str .. ", "
					else
						break
					end
				end
			elseif toks.peek() == "^=" then
				toks.next()
				str = str .. "="
				for i=1, #v do
					str = str.. v[ i ] .. "^(" .. parseExpr() .. ") "
					if toks.peek() == "," then
						toks.next()
						str = str .. ", "
					else
						break
					end
				end
			elseif toks.peek() == "%=" then
				toks.next()
				str = str .. "="
				for i=1, #v do
					str = str.. v[ i ] .. "%(" .. parseExpr() .. ") "
					if toks.peek() == "," then
						toks.next()
						str = str .. ", "
					else
						break
					end
				end
			end
		end
	end

	str = str:gsub( "(new ([a-zA-Z_0-9]+) %()", function( s )
		s = s:gsub( "new", "" )
		return s
	end )
	str = str:gsub( "(([a-zA-Z_0-9]+) instanceof ([a-zA-Z_0-9]+))", function( s )
		local spl = split( s, " " )
		return spl[ 1 ]..":instanceof("..spl[3]..")"
	end )

--	print(  )
--	print( toks.filename() )
--	print(  )
--	print( str )
--	print(  )
	
	local func, err = loadstring( str, toks.filename() )
	if not func then error( err, 0 ) end
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
			local func = parse( tokenizer( input( file:read().."\n", str ) ) )
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