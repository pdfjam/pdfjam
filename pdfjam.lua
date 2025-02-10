#!/usr/bin/env texlua
version="N.NN"

-- utility

function coalesce(...) -- return first non-nil
	for i = 1, select("#", ...) do
		if select(i, ...) ~= nil then return (select(i, ...)) end
	end
end

function append(t, a) t[#t+1] = a end

function split(s, d, plain)
	local r = {}
	local a, b = 0, string.find(s, d, 1, plain)
	while b do
		append(r, string.sub(s, a+1, b-1))
		a, b = b, string.find(s, d, b+1, plain)
	end
	append(r, string.sub(s, a+1))
	return r
end

-- option parser
Parser = {}

function Parser:new(obj)
	local obj = obj or {}
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
	return self.t, self.as
end

function Parser:parse_word(word)
	if dash_seen or string.sub(word, 1, 1) ~= "-" then
		self:parse_positional_argument(word)
	elseif string.sub(word, 1, 2) ~= "--" then
		self:parse_short_options(word)
	elseif word ~= "--" then
		self:parse_long_option(string.sub(word, 3))
	else
		self.dash_seen = true
	end
end

function Parser:parse_long_option(a)
	local v
	local p = string.find(a, "=", 2, true)
	if p then v = string.sub(a, p+1) a = string.sub(a, 1, p-1) end
	self:set_option(self.options[a], a, v)
end

function Parser:parse_short_options(word)
	assert(#word >= 2)
	self.j = 2
	local s = string.sub(word, 2, 2)
	while s ~= "" do
		a = self.short_options[s]
		if a then
			self:set_option(self.options[a], a)
		else
			self:warn("unknown option -" .. s)
		end
		self.j = self.j + 1
		s = string.sub(word, self.j, self.j)
	end
	self.j = nil
end

function Parser:set_option(o, a, v)
	self.positional_argument_read = nil
	if type(o) == "string" then -- alias
		return self:set_option(self.options[o], o, v)
	elseif string.sub(a, 1, 3) == "no-" then
		self:unset(string.sub(a, 4))
		if v then self:error("unsetting expects no value") end
		return
	end
	o = o or normalopt
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
	if self.positional_argument_read then
		append(self.as[#self.as], word)
	else
		self.positional_argument_read = true
		append(self.as, {word})
	end
end

function Parser:set(a, value) if value ~= nil then self.t[a] = value end end
function Parser:unset(a) self.t[a] = nil end
function Parser:word(j) return self._args[self.i + (j or 0)] end

function Parser:argument()
	local w
	if self.j then
		w = string.sub(self:word(), j+1)
		if w then return w end
	end
	w = self:word(1)
	if not w then
		self:error("argument required, but end of command line reached")
	elseif string.sub(w, 1, 1) == "-" then
		self:error("argument required, but the next word starts with '-'. \z
			Use --option=value syntax for values starting with '-'")
	end
	self.i = self.i+1
	return w
end

function Parser:error(s, ...)
	if not s then return end
	error(string.format("Error while parsing %s: " .. s .. ".", self:word(), ...))
end

function Parser:warn(s, ...)
	if not s then return end
	print(string.format("Warning while parsing %s: " .. s .. ".", self:word(), ...))
end

-- pdfjam specific

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
		append(t.preamble, v)
	end}
	options.longedge = "otheredge"
	options.shortedge = "no-otheredge"
	return options
end

short_options = {h="help", V="version", q="quiet", o="outfile"}

PdfjamParser = Parser:new()

function PdfjamParser:parse_short_options(word)
	if self:is_valid_pagespec(word) then return end
	return Parser.parse_short_options(self, word)
end

function PdfjamParser:is_valid_pagespec(word)
	for _, r in ipairs(split(word, ",", true)) do
		if r ~= "{}" then
			local pages = split(r, "-", true)
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

function exit(code) os.exit(code, true) end
function show_help() print("This is how to use it.") exit() end
function show_version() print("pdfjam version "..version) exit() end
function show_configpath() print("configpath is ...") exit() end
function quiet() end

function getopt()
	parser = PdfjamParser:new({options=define_options(), short_options=short_options})
	return parser:parse(arg)
end

function dump(t, indent)
	if type(t) == "table" and (not indent or #indent < 4) then
		if indent then print("...") else indent = "" end
		for k, v in pairs(t) do
			io.write(indent .. k .. " = ")
			dump(v == t and "(self)" or v, indent.."\t")
		end
		m = getmetatable(t)
		if m then
			io.write(indent .. "metatable -> ")
			dump(m, indent.."\t")
		end
	else
		print(t)
	end
end

t1, t2 = getopt()
print("options")
dump(t1)
print("arguments")
dump(t2)
