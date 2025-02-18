#!/usr/bin/env texlua
version="N.NN"
kpse.set_program_name("kpsewhich")
require "lualibs"

configpath = {"/etc", "/usr/share/etc", "/usr/local/share", "/usr/local/etc"}
home = os.getenv("HOME")

do
	local a = os.type == "windows" and os.getenv("AppData")
		or os.getenv("XDG_CONFIG_HOME")
		or home and file.join(home, ".config")
	if a then table.insert(configpath, a) end
end

-- utility

function identity(x) return x end

function coalesce(...) -- return first non-nil
	for i = 1, select("#", ...) do
		if select(i, ...) ~= nil then return (select(i, ...)) end
	end
end

function replace(s, a, b)
	local i, j = string.find(s, a, 1, true)
	assert(i~=nil)
	return string.sub(s, 1, i-1) .. b .. string.sub(s, j+1)
end

function startswith(s, a) return string.sub(s, 1, #a) == a end

function rmdir(t) os.spawn({"rm", "-rf", t[1]}) end
function mkdir(d)
	d, success = dir.makedirs(d)
	if not success then err("Could not create directory " .. d) end
	return d
end
function gcdir(d)
	local t = {d}
	setmetatable(t, {__gc = rmdir})
	return t
end
function providedir(d, tidy)
	if d then
		return mkdir(d)
	else
		d = os.tmpname()
		os.remove(d)
		return mkdir(d), tidy and gcdir(d) or nil
	end
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
	local options, t = define_options()
	local a
	if not vanilla then
		local p = ConfigParser:new({options = options, t = t})
		for _, d in ipairs(configpath) do p:parse(file.join(d, "pdfjam.conf")) end
		if home then p:parse(file.join(home, ".pdfjam.conf")) end
		t = p.t
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
	obj.t = obj.t or {}
	self.__index = self
	setmetatable(obj, self)
	return obj
end

function Parser:parse(args)
	self._args = args
	self.a = {}
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
	self:set_option(lpeg.match(lpeg.splitat("=", true), a))
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
		v = v or self:argument(o.argument) or self:error("argument required")
	end
	local value, err = o.func(v, a, self.t)
	self:error(err)
	self:set(a, value)
end

function Parser:parse_positional_argument(word)
	if self.last_positional_argument and self.last_positional_argument < self.i - 1 then
		table.insert(self.a, false)
	end
	table.insert(self.a, word)
	self.last_positional_argument = self.i
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

function err(s, ...)
	if not s then return end
	collectgarbage()
	error(string.format("Error: " .. s .. ".", ...))
end
function warn(s, ...)
	if not s then return end
	print(string.format("Warning: " .. s, ...))
end

ConfigParser = Parser:new()
do
	local spaces = lpeg.patterns.spacer^0
	local rest = lpeg.P(1)^0
	local key = lpeg.C((1 - lpeg.S(" \t\f\v="))^1)
	local value = lpeg.C(rest)
	local entry = key * spaces * ("=" * spaces * value)^-1
	local comment = "#" * rest * lpeg.Cc(false)
	local line = spaces * (comment + entry) * -1
	function ConfigParser:parse(file)
		local f = io.open(file)
		if f then
			self.file = file -- for error messages
			for l in f:lines() do
				self.current = l -- for error messages
				self:parse_word(lpeg.match(line, l))
			end
			f:close()
		end
		return self.t
	end
end
function ConfigParser:parse_word(k, v)
	if k == nil then self:error("illegal syntax")
	elseif k then return self:set_option(k, v) end
end
function ConfigParser:argument(optional)
	if optional then self:error("argument needed") end
end
function ConfigParser:error(s, ...)
	if not s then return end
	print(string.format("Problem while parsing %s in line '%s': " .. s .. ".", self.file, self.current, ...))
end

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
	func = function(_, a, t) t.paper = a t.papersize = nil end
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
	for o, f in pairs(mode_options) do options[o] = {argument = false, func = f} end
	options.paper = {
		func = function(v, _, t)
			t.papersize = nil
			v = string.lower(v)
			if paper_hash[v] then
				return v
			elseif paper_hash[v .. "paper"] then
				return v .. "paper"
			else
				return nil, "Unknown paper format '" .. v .. "'"
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

	local initial = {
		tidy = true,
		outfile = ".",
		suffix = "pdfjam",
		runs = 1,
		latex = "pdflatex",
		pdfinfo = "pdfinfo",
		iconv = "iconv",
		checkfiles = magic_file(arg[0]) == "a texlua script",
		pages = "-",
	}
	return options, initial
end

-- Used: [Vhoq]. Used in pagespec: [-,0-9l].
short_options = {h="help", V="version", q="quiet", o="outfile"}

function exit(code) collectgarbage() os.exit(code, true) end
function show_help() print("This is how to use it.") exit() end
function show_version() print("pdfjam version "..version) exit() end
function show_configpath() print("configpath is ...") exit() end

--- pdfinfo ---
do
local pdfkeys = {"Title", "Author", "Subject", "Keywords"}

local labels = {}
for _, a in ipairs(pdfkeys) do
	labels[string.format("%-17s", a..":")] = a
end

local function get_pdfinfo(pdfinfo, f)
	local info = {}
	-- Note: There does not seem to be the choice of UTF-16BE.
	for l in io.popen(pdfinfo .. " -enc UTF-8 -- " .. f):lines() do
		local k = labels[string.sub(l, 1, 17)]
		if k then info[k] = string.sub(l, 18) end
	end
	return info
end

local pdfinfo_template = "\n" .. [[
\ifdefined\luatexversion
	\protected\def\pdfinfo{\pdfextension info}
\fi
\ifdefined\XeTeXversion
	\protected\def\pdfinfo#1{\AddToHook{shipout/firstpage}{\special{pdf:docinfo << #1 >>}}}
\fi
\ifdefined\pdfinfo
	\pdfinfo{]]
local pdfinfo_template_end = "\n\t}\n\\fi"

function make_pdfinfo(x, last_in)
	local pdfinfo, iconv, enc = x:pop("pdfinfo"), x:pop("iconv"), x:pop("enc")
	local info = x:pop("keepinfo") and get_pdfinfo(pdfinfo, last_in) or {}
	local to_utf16_be = utf.utf8_to_utf16_be
	if not to_utf16_be and not enc then enc = "UTF-8" end
	if enc then
		local iconv = iconv .. " -f " .. enc .. " -t UTF-16BE -- iconv.txt"
		to_utf16_be = function(s)
			local f = io.savedata("iconv.txt", s)
			local p = io.popen(iconv)
			local result = p:read("a")
			return result
		end
	end

	for _, k in ipairs(pdfkeys) do
		info[k] = x:pop("pdf" .. string.lower(k)) or info[k]
	end

	local r = ""
	if next(info) then
		r = pdfinfo_template
		for _, k in ipairs(pdfkeys) do
			if info[k] then
				r = r .. "\n\t\t/" .. k .. " <feff" .. string.tohex(to_utf16_be(info[k])) .. ">"
			end
		end
		r = r .. pdfinfo_template_end
	end
	return r
end
end -- /pdfinfo

--- file utility ---

function magic_file(f)
	-- Note: 19 = #"PostScript document"
	local ans = io.popen("file -Lb " .. file.collapsepath(f, true)):read(19)
	return (string.split(ans, ","))
end

do
	local magic_names = {
		["PDF document"]="pdf", ["PostScript document"]="eps",
		["JPEG image data"]="jpg", ["PNG image data"]="png"
	}
	local ext_names = {pdf="pdf", eps="eps", jpg="jpg", png="png",
		ps="eps", jpeg="jpg"}

	function get_extension(f, check)
		if check then
			return magic_names[magic_file(f)]
		else
			return ext_names[string.lower(file.extname(f))]
		end
	end
end

--- page specs ---

do
	local page = lpeg.R"09" ^ 0 + "last" -- any or no page
	local range = page * ("-" * page) ^ -1 -- any or no page range (the latter being an implicit empty page)
	local part = range + "{}" -- page range or implicit or explicit empty page
	local spec = part * ("," * part) ^ 0 * -1 -- complete page spec
	function is_valid_pagespec(word)
		return lpeg.match(spec, word) ~= nil
	end
end

function with_pagespec(l, ps)
	local r = {}
	for _, a in ipairs(l) do
		table.insert(r, a)
		table.insert(r, ps)
	end
	return r
end

--- file and pagespec list ---

function outfile(out, last_in, suffix)
	out = out or "."
	if lfs.isdir(out) then
		local dir = file.collapsepath(out, true) -- bug when out contains :
		local name = file.nameonly(last_in) .. (suffix and "-" .. suffix or "")
		out = file.join(dir, name .. ".pdf")
	end
	return out
end

function make_filepagelist(args, d, checkfiles)
	local filepagelist = {}
	local l = {}
	local last_in, last_in_renamed
	local i = 0
	local function add_pagespec(a)
		table.append(filepagelist, with_pagespec(l, a))
		l = {}
	end
	local function add_file(a)
		i = i + 1
		last_in = a
		last_in_renamed = "source-"..i..".pdf"
		file.copy(last_in, file.join(d, last_in_renamed))
		table.insert(l, last_in_renamed)
	end
	local cases = { -- binary coded index
		"Input file expected, but '%s' not even exists in your file system",
		"Input file or pagespec expected, but '%s' neither exists in your file system nor is it a pagespec",
		"The argument '%s' is a valid pagespec but a valid PDF/EPS/JPG/PNG file was expected",
		add_pagespec,
		"The argument '%s' is a valid path but not a valid PDF/EPS/JPG/PNG file",
		"The argument '%s' is a valid path but not a valid PDF/EPS/JPG/PNG file or pagespec",
		"The argument '%s' is both a valid path and a pagespec but a valid PDF/EPS/JPG/PNG file was expected",
		add_pagespec,
		nil,
		nil,
		"Dubious argument '%s' interpreted as file due to its position.\n\nTip: Write './%s' for extra clarity",
		"Ambiguous argument '%s' interpreted as pagespec. If you meant the file, please write './%s' instead",
	}
	local function add_argument(a)
		local valid = io.exists(a) and (get_extension(a, check, checkfiles) and 8 or 4) or 0
		local pagespec = is_valid_pagespec(a) and 2 or 0
		local awaited = l[1] ~= nil and 1 or 0
		local c = cases[valid + pagespec + awaited + 1]
		if valid == 8 then
			add_file(a)
			warn(c, a, a)
		elseif type(c) == "function" then c(a)
		else err(c, a)
		end
	end
	for _, a in ipairs(args) do
		if a == false then table.append(filepagelist, l) l = {}
		else add_argument(a)
		end
	end
	table.append(filepagelist, l)
	if not last_in then
		last_in_renamed = "stdin.pdf"
		last_in = file.join(d, last_in_renamed)
		local s = io.read("a")
		if s and s ~= "" then
			local f = io.savedata(last_in, s)
		else err("Either an input file must be given or there must be input from stdin")
		end
		local ext = get_extension(last_in)
		if not ext then err("No input file given and stdin is no valid input")
		elseif ext ~= "pdf" then
			last_in_renamed = "stdin." .. ext
			file.copy(last_in, file.join(d, last_in_renamed))
			last_in = file.join(d, last_in_renamed)
		end
	end
	return filepagelist, last_in, last_in_renamed
end

--- main ---

template = [[
\documentclass[~documentoptions~]{article}~colorcode~
\usepackage[~geometryoptions~]{geometry}
\usepackage[utf8]{inputenc}~raw_pdfinfo~
\usepackage{pdfpages}~otheredge~~preamble~
\begin{document}
\includepdfmerge[~options~]{~filepagelist~}
\end{document}]]

function main()
	local x = getopt()
	local d, gc_dummy = providedir(x:pop("builddir"), x:pop("tidy"))
	local filepagelist, last_in, last_in_renamed = make_filepagelist(x.a, d, x:pop("checkfiles"))
	local outfile = outfile(x:pop("outfile"), last_in, x:pop("suffix"))
	local latex = x:pop("latex")
	local runs = tonumber(x:pop("runs"))
	if runs <= 0 then err("The number of runs must be at least 1") end

	lfs.chdir(d)

	local opts = {
		geometryoptions = x:retrieve("papersize"),
		documentoptions = x:list("paper", "landscape", "twoside"),
		colorcode = x:retrieve("pagecolor"),
		raw_pdfinfo = make_pdfinfo(x, last_in_renamed),
		otheredge = x:retrieve("otheredge"),
		preamble = x:retrieve("preamble"),
		options = x:listall(),
		filepagelist = table.concat(filepagelist, ","),
	}
	local content = template
	for k, v in pairs(opts) do
		content = replace(content, "~"..k.."~", v)
	end

	local f = io.savedata("a.tex", content)
	-- do return end -- for debugging
	for _ = 1, runs do os.spawn({latex, "a.tex"}) end
	file.copy("a.pdf", outfile)
end

success, msg = xpcall(main, debug.traceback)
collectgarbage()
if not success then
	print(msg)
	exit(1)
end
