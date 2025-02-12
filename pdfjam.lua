#!/usr/bin/env texlua
kpse.set_program_name("pdfjam")
version="N.NN"

-- utility

require "lualibs"

function identity(x) return x end

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

function rmdir(t) os.spawn({"rm", "-rf", t[1]}) end
function mkdir(d)
	d, success = dir.makedirs(d)
	if not success then error("Could not create directory " .. d .. ".") end
	local t = {d}
	setmetatable(t, {__gc = rmdir})
	return t
end
function providedir(d)
	if not d then
		d = os.tmpname()
		os.remove(d)
	end
	return d, mkdir(d)
end

function embrace(s)
	if string.find(s, "[],=]") and not
		(string.sub(s, 1, 1) == "{" and string.sub(s, #s) == "}") then
		return "{" .. s .. "}"
	else return s
	end
end

function unbrace(s)
	if string.sub(s, 1, 1) == "{" and string.sub(s, #s) == "}" then
		return string.sub(s, 2, #s-1)
	else return s
	end
end

-- option parser

function getopt()
	for _, w in ipairs(arg) do
		if w == "--" then break
		elseif w == "--vanilla" then local vanilla = true break
		end
	end
	local options = define_options()
	local a, t
	if not vanilla then
		local p = ConfigParser:new({options = options})
		t = p:parse("")
	end
	parser = Parser:new({
		options = options,
		short_options = short_options,
		t = t,
	})
	a, t = parser:parse(arg)
	return Interpreter:new({a=a, t=t, options=options})
end


Parser = {}
function Parser:new(obj)
	local obj = obj or {}
	obj.options = obj.options or {}
	obj.short_options = obj.short_options or {}
	self.__index = self
	setmetatable(obj, self)
	return obj
end

function Parser:parse(args)
	self._args = args
	self.a = {}
	self.t = self.t or {}
	self.i = 1
	while self.i <= #args do
		self:parse_word(args[self.i])
		self.i = self.i + 1
	end
	return self.a, self.t
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
	if not self.short_options[s] then return false end
	while s ~= "" do
		local a = self.short_options[s]
		if a then
			self:set_option(a)
		else
			self:error("unknown option -" .. s)
		end
		self.j = self.j + 1
		s = string.sub(word, self.j, self.j)
	end
	self.j = nil
	return true
end

function Parser:set_option(a, v)
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
	if o.argument == false then
		if v then self:error("no argument allowed") end
	else
		v = v or self:argument(o.argument)
	end
	local value, err = o.func(v, a, self.t)
	self:error(err)
	self:set(a, value)
end

function Parser:parse_positional_argument(word)
	table.insert(self.a, word)
end

function Parser:get(a) return self.t[a] end
function Parser:set(a, value) if value ~= nil then self.t[a] = value end end
function Parser:unset(a) self.t[a] = nil end
function Parser:word(n) return self._args[self.i + (n or 0)] end

-- Read argument `w`.
-- If `options` is given, only read `w` if `options[w]` exists.
-- If `w` could be an option (starts with -), throw error.
function Parser:argument(options)
	assert(options==nil or type(options) == "table")
	local w
	if self.j then
		w = string.sub(self:word(), self.j+1)
		if options and not options[w] then return end
		if w ~= "" then self.j = #self:word() return w end
	end
	w = self:word(1)
	if options and not options[w] then return end
	if not w then
		self:error("argument required, but end of command line reached")
	elseif string.sub(w, 1, 2) == "--"
		or string.sub(w, 1, 1) == "-" and self.short_options[string.sub(w, 2, 2)] then
		self:error("argument required, but the following word '" .. w
			.. "' seems to be an option.\n\n\z
			Tip: For supplying an argument starting with '-' use " .. self.word()
			.. (string.sub(self.word(), 2, 2) == "-" and "=" or "") .. w .. " instead.")
	end
	self.i = self.i + 1
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

ConfigParser = Parser:new()

Interpreter = {}
function Interpreter:new(obj)
	local obj = obj or {}
	obj.t = obj.t or {}
	obj.options = obj.options or {}
	self.__index = self
	setmetatable(obj, self)
	return obj
end

function Interpreter:pop(a)
	local v = self.t[a]
	if v ~= nil then self.t[a] = nil return v end
end
function Interpreter:retrieve(a)
	local v = self:pop(a)
	if v then
		local f = self.options[a] and self.options[a].retrieve
		if f then return f(v, self.t) end
		return v == true and a or a .. "=" .. embrace(v)
	else return ""
	end
end

function Interpreter:list(...)
	local r
	for _, a in ipairs({...}) do
		local x = self:retrieve(a)
		if x and x ~= "" then
			r = r and r .. "," .. x or x
		end
	end
	return r or ""
end

function Interpreter:listall()
	local r = ""
	for a in pairs(self.t) do
		r = r .. "," .. self:retrieve(a)
	end
	return string.sub(r, 2)
end

-- pdfjam options

normalopt = {func = identity}

flagopt = {
	argument = false,
	func = function() return true end
}

paperopt = {
	argument = false,
	func = function(_, a, t) t.paper = a end
}

bool_prose = {["true"]="true", yes="true", on="true", ["false"]="false", no="false", off="false"}
boolopt = {
	argument = bool_prose,
	func = function(v)
		if not v then return true end
		local b = bool_prose[v]
		if b == nil then
			return nil, "Cannot interpret '" .. v .. "' as boolean value.\n\n\z
			Tip: Accepted values are 'true', 'yes' and 'on', respectively 'false', 'no' and 'off'"
		else
			return b
		end
	end
}

function define_options()
	local options = {}
	local bool_options = {
		"flip-other-edge", "frame", "column", "columnstrict",
		"openright", "openrighteach", "turn", "noautoscale", "fitpaper",
		"reflect", "booklet", "booklet*", "rotateoversize",
		"link", "thread", "keepaspectratio", "clip", "draft", "interpolate",
		"doublepages", "doublepagestwist", "doublepagestwistodd",
		"doublepagestwist*", "doublepagestwistodd*"
	}
	local flag_options = {"vanilla", "quiet", "tidy", "keepinfo",
		"landscape", "twoside", "otheredge"
	}
	local paper_options = {
		"a0paper","a1paper","a2paper","a3paper","a4paper","a5paper","a6paper",
		"b0paper","b1paper","b2paper","b3paper","b4paper","b5paper","b6paper",
		"c0paper","c1paper","c2paper","c3paper","c4paper","c5paper","c6paper",
		"ansiapaper","ansibpaper","ansicpaper","ansidpaper","ansiepaper",
		"letterpaper","legalpaper","executivepaper",
		"b0j","b1j","b2j","b3j","b4j","b5j","b6j"
	}
	local paper_hash = table.tohash(paper_options)
	local mode_options = {help = show_help, version = show_version,
		configpath = show_configpath
	}
	for _, o in ipairs(bool_options) do options[o] = boolopt end
	for _, o in ipairs(flag_options) do options[o] = flagopt end
	for _, o in ipairs(paper_options) do options[o] = paperopt end
	for o, f in pairs(mode_options) do options[o] = {argument = "forbidden", func = f} end
	options.paper = {
		func = function(v, _, t)
			t.papersize = nil
			v = string.lower(v)
			if paper_hash[v] then
				return v
			elseif paper_hash[v .. "paper"] then
				return v .. "paper"
			else
				return nil, "Unknown paper format '" .. v .. "'."
			end
		end,
		retrieve = identity
	}
	options.papersize = {
		func = function(v, _, t)
			t.paper = nil
			v = unbrace(v)
			h, h_unit, w, w_unit = string.match(v, "^(%d+)(%l*),(%d+)(%l*)$")
			if not h then return nil, "wrong syntax for papersize" end
			h_unit = h_unit ~= "" and h_unit or "bp"
			w_unit = w_unit ~= "" and w_unit or "bp"
			return {h .. h_unit, w .. w_unit}
		end,
		retrieve = function(v, t)
			if t.landscape then v = {v[2], v[1]} end
			return "papersize={" .. v[1] .. "," .. v[2] .. "}"
		end
	}
	options.preamble = {
		func = function(v, _, t)
			t.preamble = (t.preamble or "") .. "\n" .. v
		end,
		retrieve = identity
	}
	options.pagecolor = {
		func = identity,
		retrieve = function(v)
			return "\n\z
				\\usepackage{color}\n\z
				\\definecolor{bgclr}{RGB}{"..v.."}\n\z
				\\pagecolor{bgclr}"
		end
	}
	options.otheredge = table.fastcopy(flagopt)
	options.otheredge.retrieve = function(v)
		return "\n"..[[{\makeatletter\AddToHook{shipout/before}{\ifodd\c@page\pdfpageattr{/Rotate 180}\fi}}]]
	end
	options.longedge = "otheredge"
	options.shortedge = "no-otheredge"
	return options
end

-- Used: [Vhoq]. Used in pagespec: [-,0-9l].
short_options = {h="help", V="version", q="quiet", o="outfile"}

function exit(code) collectgarbage() os.exit(code, true) end
function show_help() print("This is how to use it.") exit() end
function show_version() print("pdfjam version "..version) exit() end
function show_configpath() print("configpath is ...") exit() end

-- pdfjam --

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
	local x = getopt()
	table.print(x.a)
	table.print(x.t)

	local d, gc_dummy = providedir(x:pop("builddir"))

	local filepagelist = {}
	local l = {}
	for i, a in ipairs(x.a) do
		if l and is_valid_pagespec(a) then
			table.append(filepagelist, with_pagespec(l, a))
			l = {}
		else
			if not io.exists(a) then error("File '"..a.."' does not exist.") end
			local s = file.join(d, "source-"..i..".pdf")
			file.copy(a, s)
			table.insert(l, s)
		end
	end
	table.append(filepagelist, with_pagespec(l, "-"))

	local pwd = lfs.currentdir()
	local outfile = file.join(pwd, "out.pdf")
	lfs.chdir(d)

	local t = {
		geometryoptions = x:retrieve("papersize"),
		documentoptions = x:list("paper", "landscape", "twoside"),
		colorcode = x:retrieve("pagecolor"),
		raw_pdfinfo = "", -- TODO
		otheredge = x:retrieve("otheredge"),
		preamble = x:retrieve("preamble"),
		options = x:listall(),
		filepagelist = table.concat(filepagelist, ","),
	}
	local content = template
	for k, v in pairs(t) do
		content = replace(content, "~"..k.."~", v)
	end

	print(content)
	local f = io.open("a.tex", "w")
	f:write(content)
	f:close()
	os.spawn({"pdflatex", "a.tex"})
	file.copy("a.pdf", outfile)
end

success, msg = xpcall(main, debug.traceback)
collectgarbage()
if not success then
	print(msg)
	exit(1)
end
