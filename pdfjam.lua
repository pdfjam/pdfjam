#!/usr/bin/env texlua
kpse.set_program_name("pdfjam")
version="N.NN"

-- utility

require "lualibs"

function coalesce(...) -- return first non-nil
	for i = 1, select("#", ...) do
		if select(i, ...) ~= nil then return (select(i, ...)) end
	end
end

function replace(s, a, b)
	i, j = string.find(s, a, 1, true)
	assert(i~=nil)
	return string.sub(s, 1, i-1) .. b .. string.sub(s, j+1)
end

--function rmdir(t) os.spawn({"rm", "-rf", t[1]}) end
function rmdir(t) end
function tmpdir()
	local x = os.tmpname()
	os.remove(x)
	if not lfs.mkdir(x) then error("Could not create tmpdir") end
	local t = {x}
	setmetatable(t, {__gc = rmdir})
	return t
end

-- option parser

Parser = {}

function Parser:new(obj)
	local obj = obj or {}
	obj.options = obj.options or {}
	obj.short_options = obj.short_options or {}
	obj.no_options = obj.no_options or ""
	self.__index = self
	setmetatable(obj, self)
	return obj
end

function Parser:parse(args)
	self._args = args
	self.as = {}
	self.t = {}
	self.i = 1
	while self.i <= #args do
		self:parse_word(args[self.i])
		self.i = self.i + 1
	end
	return self.as, self.t
end

function Parser:parse_word(word)
	if not self.dash_seen and word == "--" then
		self.dash_seen = true
	elseif not self.dash_seen and string.sub(word, 1, 2) == "--" then
		self:parse_long_option(string.sub(word, 3))
	elseif self.dash_seen or string.sub(word, 1, 1) ~= "-"
		or not self:parse_short_options(word) then
		self:parse_positional_argument(word)
	end
end

function Parser:parse_long_option(a)
	local v
	local p = string.find(a, "=", 2, true)
	if p then v = string.sub(a, p+1) a = string.sub(a, 1, p-1) end
	self:set_option(a, v)
end

function Parser:parse_short_options(word)
	self.j = 2
	local s = string.sub(word, 2, 2)
	if string.find(self.no_options, s, 1, true) then return false end
	while s ~= "" do
		a = self.short_options[s]
		if a then
			self:set_option(a)
		elseif string.find(self.no_options, s, 1, true) then
			self:error("invalid short option -" .. s)
		else
			self:warn("unknown option -" .. s)
		end
		self.j = self.j + 1
		s = string.sub(word, self.j, self.j)
	end
	self.j = nil
	return true
end

function Parser:set_option(a, v)
	self.positional_argument_read = nil
	if string.sub(a, 1, 3) == "no-" then
		self:unset(string.sub(a, 4))
		if v then self:error("unsetting expects no value") end
		return
	end
	o = self.options[a] or normalopt
	if type(o) == "string" then -- alias
		return self:set_option(o, v)
	end
	assert(type(o) == "table")
	if o.argument == "required" then
		v = v or self:argument()
	elseif o.argument == "forbidden" then
		if v then self:error("no argument allowed") end
	elseif not v and self:word(1) then
		local value = o.func(self:word(1), a, self.t)
		self:set(a, coalesce(value, o.argument))
		return
	end
	local value, err = o.func(v, a, self.t)
	self:error(err)
	self:set(a, value)
end

function Parser:parse_positional_argument(word)
	table.insert(self.as, word)
end

function Parser:set(a, value) if value ~= nil then self.t[a] = value end end
function Parser:unset(a) self.t[a] = nil end
function Parser:word(n) return self._args[self.i + (n or 0)] end

function Parser:argument()
	local w
	if self.j then
		w = string.sub(self:word(), self.j+1)
		if w ~= "" then self.j = #self:word() return w end
	end
	w = self:word(1)
	if not w then
		self:error("argument required, but end of command line reached")
	elseif string.sub(w, 1, 1) == "-" then
		self:error("argument required, but the following word '" .. w ..
			"' starts with '-'. Use --option=value syntax for values starting with '-'")
	end
	self.i = self.i+1
	return w
end

function Parser:error(s, ...)
	if not s then return end
	collectgarbage()
	error(string.format("Error while parsing %s: " .. s .. ".", self:word(), ...))
end

function Parser:warn(s, ...)
	if not s then return end
	print(string.format("Warning while parsing %s: " .. s .. ".", self:word(), ...))
end

-- pdfjam options

normalopt = {
	argument = "required",
	func = function(v) return v end
}

flagopt = {
	argument = "forbidden",
	func = function(_, a) return a end
}

paperopt = {
	argument = "forbidden",
	func = function(_, a, t) t.paper = a end
}

bool_prose = { ["true"]=true, yes=true, on=true, ["false"]=false, no=false, off=false }

boolopt = {
	argument = true,
	func = function(v)
		b = bool_prose[string.lower(v)]
		if b == nil then
			return nil, "Cannot interpret '" .. v .. "' as boolean value."
		else
			return b
		end
	end
}

function define_options()
	local options = {}
	bool_options = {
		"flip-other-edge", "landscape", "frame", "column", "columnstrict",
		"openright", "openrighteach", "turn", "noautoscale", "fitpaper",
		"reflect", "booklet", "booklet*", "rotateoversize",
		"link", "thread", "keepaspectratio", "clip", "draft", "interpolate",
		"doublepages", "doublepagestwist", "doublepagestwistodd",
		"doublepagestwist*", "doublepagestwistodd*"
	}
	flag_options = {"vanilla", "quiet", "tidy", "keepinfo",
		"landscape", "twoside", "otheredge"
	}
	paper_options = {
		"a0paper","a1paper","a2paper","a3paper","a4paper","a5paper","a6paper",
		"b0paper","b1paper","b2paper","b3paper","b4paper","b5paper","b6paper",
		"c0paper","c1paper","c2paper","c3paper","c4paper","c5paper","c6paper",
		"ansiapaper","ansibpaper","ansicpaper","ansidpaper","ansiepaper",
		"letterpaper","legalpaper","executivepaper",
		"b0j","b1j","b2j","b3j","b4j","b5j","b6j"
	}
	mode_options = {help = show_help, version = show_version,
		configpath = show_configpath
	}
	for _, o in ipairs(bool_options) do options[o] = boolopt end
	for _, o in ipairs(flag_options) do options[o] = flagopt end
	for _, o in ipairs(paper_options) do options[o] = paperopt end
	for o, f in pairs(mode_options) do options[o] = {argument = "forbidden", func = f} end
	options.paper = {argument = "required", func = function(v)
		v = string.lower(v)
		if paper_options[v] then
			return v
		elseif paper_options[v .. "paper"] then
			return v .. "paper"
		else
			return nil, "Unknown paper format '" .. v .. "'."
		end
	end}
	options.papersize = {argument = "required", func = function(v, _, t)
		v = unbrace(v)
		h, h_unit, w, w_unit = string.match(v, "^(%d+)(%l*),(%d+)(%l*)$")
		if not h then return nil, "wrong syntax for papersize" end
		h_unit = h_unit ~= "" and h_unit or "bp"
		w_unit = w_unit ~= "" and w_unit or "bp"
		t.paper = {h .. h_unit, w .. w_unit}
	end}
	options.preamble = {argument = "required", func = function(v, _, t)
		t.preamble = t.preamble or {}
		table.insert(t.preamble, v)
	end}
	options.longedge = "otheredge"
	options.shortedge = "no-otheredge"
	return options
end

short_options = {h="help", V="version", q="quiet", o="outfile"}
no_options = ",-0123456789l" -- explicitely no short options
-- all other chars may be used in future pdfjam versions

function exit(code) collectgarbage() os.exit(code, true) end
function show_help() print("This is how to use it.") exit() end
function show_version() print("pdfjam version "..version) exit() end
function show_configpath() print("configpath is ...") exit() end

function getopt()
	parser = Parser:new({
		options = define_options(),
		short_options = short_options,
		no_options = no_options
	})
	return parser:parse(arg)
end

-- pdfjam

function is_valid_pagespec(word)
	for _, r in ipairs(string.split(word, ",", true)) do
		if r ~= "{}" then
			local pages = string.split(r, "-", true)
			if #pages > 2 then return false end
			for _, p in ipairs(pages) do
				if not (tonumber(p) or p == "" or p == "last") then
					return false
				end
			end
		end
	end
	return true
end

function with_pagespec(l, ps)
	local r = {}
	for _, a in ipairs(l) do
		table.insert(r, a)
		table.insert(r, ps)
	end
	return r
end

template = [[
\documentclass[~documentoptions~]{article}~colorcode~
\usepackage[~geometryoptions~]{geometry}
\usepackage[utf8]{inputenc}~raw_pdfinfo~
\usepackage{pdfpages}~otheredge~~preamble~
\begin{document}
\includepdfmerge[~options~]{~filepagelist~}
\end{document}]]

-- main

function main()
	local as, opts = getopt()

	local dd = tmpdir()
	local d = dd[1]

	local filepagelist = {}
	local l = {}
	for i, x in ipairs(as) do
		if l and is_valid_pagespec(x) then
			table.append(filepagelist, with_pagespec(l, x))
			l = {}
		else
			if not io.exists(x) then error("File '"..x.."' does not exist.") end
			local y = file.join(d, "source-"..i..".pdf")
			file.copy(x, y)
			table.insert(l, y)
		end
	end
	table.append(filepagelist, with_pagespec(l, "-"))

	local pwd = lfs.currentdir()
	local outfile = file.join(pwd, "out.pdf")
	lfs.chdir(d)

	local t = {
		documentoptions = "",
		geometryoptions = "a4paper",
		colorcode = "",
		raw_pdfinfo = "",
		otheredge = "",
		preamble = "",
		options = "scale=.8",
		filepagelist = table.concat(filepagelist, ",")
	}
	local content = template
	for k, v in pairs(t) do
		content = replace(content, "~"..k.."~", v)
	end

	local f = io.open("a.tex", "w")
	f:write(content)
	f:close()
	os.spawn({"pdflatex", "a.tex"})
	file.copy("a.pdf", outfile)
end

success, msg = pcall(main)
collectgarbage()
if not success then
	print("pdfjam run unsuccessfull.")
	print(msg)
	exit(1)
end
