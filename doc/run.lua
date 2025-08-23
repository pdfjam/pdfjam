#!/usr/bin/env texlua

---@diagnostic disable: lowercase-global

kpse.set_program_name("kpsewhich")
require "lualibs"

P = {
	space_to_hyphen = lpeg.Cs((lpeg.P" "/"-" + 1)^0),
	escape_asterisk = lpeg.Cs((lpeg.P"*"/"\\*" + 1)^0),
	escape_squote = lpeg.Cs((lpeg.P"'"/"\\'" + 1)^0),
	alternatives = lpeg.Ct("(" * lpeg.C((1 - lpeg.S" )")^1) * (" " * lpeg.C((1 - lpeg.S" )")^1))^0 * ")"),
}

function singlequote(s) return "'" .. P.escape_squote:match(s) .. "'" end
function escape_asterisk(s) return P.escape_asterisk:match(s) end

function serialize(t)
	if type(t) == "table" then
		io.write"{"
		local seen_sth = false
		for _,v in ipairs(t) do
			if seen_sth then io.write", " else seen_sth = true end
			serialize(v)
		end
		io.write"}"
	elseif type(t) == "string" then
		io.write(singlequote(t))
	else
		io.write(t)
	end
end

function space_to_hyphen(a) return P.space_to_hyphen:match(a) end

function lower_first(s) return string.lower(string.sub(s, 1, 1)) .. string.sub(s, 2) end

function imap(t, f)
	local a = {}
	for _, x in ipairs(t) do
		local y = f(x)
		if y then table.insert(a, y) end
	end
	return a
end

function map(t, f)
	local a = {}
	for k, v in pairs(t) do
		a[k] = f(v)
	end
	return a
end

function format_arguments(option, arg, alias)
	return "**--" .. escape_asterisk(option) .. "**" .. arg ..
		(alias and ", " .. format_arguments(alias, arg) or "")
end

function as_markdown_option(t)
	if type(t) ~= "table" then return string.sub(t, 1, 1) == "#" and "#" .. t or nil end
	local arguments = ""
	if t.completer and P.alternatives:match(t.completer) then
		arguments = t.completer
	elseif t.description then
		arguments = space_to_hyphen(t.description)
	elseif t.argnames then
		local argnames = map(t.argnames, space_to_hyphen)
		arguments = table.concat(argnames, t.argtype == "dims-comma" and "," or " ")
		if t.argtype == "dims-space" then arguments = "'" .. arguments .. "'" end
	elseif t.argtype then
		local lookup = {bool="bool", string="string", name="name", tex="tex", num="number",
			angle="angle", num4="multiple-of-4"}
		arguments = lookup[t.argtype] or error("Unknown argtype: "..t.argtype)
	end
	if arguments ~= "" then arguments = " " .. arguments end
	local header = t.short and "**-" .. t.short .. "**" .. arguments .. ", " or ""
	header = header .. format_arguments(t[1], arguments, t.alias)
	if t.flag == "+" then header = header .. " _respectively_ **--no-" .. t[1] .. "**" end
	return header .. "\n\n: " .. t.help
end

function build_markdown(opts, out)
	local options_md_table = imap(opts, as_markdown_option)
	local options_md = table.concat(options_md_table, "\n\n")

	local readme = loaddata("README.md")
	readme = string.gsub(readme, "!!!OPTIONS!!!", options_md, 1)
	io.savedata(out, readme)
end

COMPLETER = {bool=":bool:(true false)", string=":string: ", name=":name: ", tex=":tex: ",
	angle=":angle:compadd -o nosort $(seq 0 15 345)",
	num4=":signature size:compadd -o nosort $(seq 4 4 96)",
	dim=function(as) return ":"..as[1]..":_dimen "..as[1] end,
	num=function(as) local a=as and as[1] or "number"; return ":"..a..':_numbers -l 1 "'..a..'"' end,
	["dims-comma"]=function(as) local a=table.concat(as, ","); return ":"..a..":_dimens , "..a end,
	["dims-space"]=function(as) return ":"..table.concat(map(as, space_to_hyphen), " ")..':_dimens " " '..table.concat(as, ",") end,
}

function as_zsh_completion_group(t)
	local result = t[0] .. "\n\t\t+ '(" .. t[1][1] .. ")'"
	for i = 0, #t do
		result = result .. "\n\t\t\t" .. as_zsh_completion(t[i])
	end
	return result
end

function as_zsh_completion(t)
	if type(t) ~= "table" then return t end
	if t[0] then table.insert(Z, as_zsh_completion_group(t)); return end
	local quote = t.quote or "'"
	local pre = quote
	local exclude = t.exclude and "(" .. surround_concat(imap(t.exclude, escape_asterisk), "--", " ") .. ")" or ""
	local flag_with_no = t.flag == "+"
	local flag = t.flag == "=" and "(- :)" or t.flag == "*" and "*" or ""
	local option = "--" .. escape_asterisk(t[1])
	if t.short or t.alias then
		option = "{" .. (t.short and "-" .. t.short .. "," or "") .. option .. (t.alias and ",--" .. escape_asterisk(t.alias) or "") .. "}" .. pre
		if flag == "" then pre = "" else flag = flag .. quote end
	end
	local completer = ""
	if t.description then
		completer = ":"..t.description..":" .. (t.completer and t.completer or "_"..t.description)
	elseif t.argtype then
		local compl = COMPLETER[t.argtype]
		completer = type(compl) == "function" and compl(t.argnames) or compl and compl or error("Unknown argtype: "..t.argtype)
	end
	if flag_with_no then
		local exclude1 = "--no-" .. t[1]
		local exclude2 = option
		if exclude ~= "" then
			local exclud = string.sub(exclude, 1, -2) .. " "
			exclude1 = exclud .. exclude1 .. ")"
			exclude2 = exclud .. exclude2 .. ")"
		else
			exclude1 = "(" .. exclude1 .. ")"
			exclude2 = "(" .. exclude2 .. ")"
		end
		return "'" .. exclude1 .. option .. "[" .. t.help .. "]'" ..
			"\n\t\t'" .. exclude2 .. "--no-" .. t[1] .. "[Do not " .. lower_first(t.help) .. "]'"
	end
	return pre .. flag .. exclude .. option .. "[" .. t.help .. "]" .. completer .. quote
end

function build_zsh_complete(opts)
	Z = {}
	opts = imap(opts, as_zsh_completion)
	local options_zsh = table.concat(opts, "\n\t\t") .. "\n\t\t# Completion groups\n\t\t" .. table.concat(Z, "\n\t\t")

	local zcmp = loaddata("zsh-completion.sh")
	zcmp = string.gsub(zcmp, "!!!OPTIONS!!!", options_zsh, 1)
	savedata("_pdfjam", zcmp)
end

function loaddata(f) return io.loaddata(f) or error("File not found: " .. f) end
function savedata(f, s)
	if io.loaddata(f) ~= s then io.savedata(f, s) end
end

function make_example(t)
	if not t.example then return end
	savedata("in/"..t[1], t.example)
end

function compile_example(out, l)
	out = "'" .. out .. ".pdf' "
	local success = os.execute("2>>out/pdfjam.log ../../pdfjam --outfile out/" .. out .. l ..
	" && 2>>small/pdfjam.log ../../pdfjam --a2paper --noautoscale true --scale .1 --nup 9x9 --delta '1mm 1mm' --frame true --outfile small/" .. out .. "out/" .. out ..
	" && >>cropped/pdfcrop.log pdfcrop small/" .. out .. "cropped/" .. out)
	print((success and "OK: " or "ERR ") .. out)
end

function surround_concat(t, pre, mid, post)
	return pre .. table.concat(t, (post or "") .. (mid or "") .. pre) .. (post or "")
end

function make_examples(opts)
	dir.makedirs("in")
	local targets = imap(opts, function(t) return t.example and t[1] end)
	local make = "PDFJAM = ./pdfjam\n\nall: " .. surround_concat(targets, "cropped/", " ", ".pdf") ..
		"\n\nout/%.pdf: in/% | out\n\t$(PDFJAM) --outfile '$@' $(file < $<) 2>>out/pdfjam.log " ..
		"\n\nsmall/%.pdf: out/%.pdf | small\n\t$(PDFJAM)  --a2paper --noautoscale true --scale .1 --nup 9x9 --delta '1mm 1mm' --frame true --outfile '$@' '$<' 2>>small/pdfjam.log" ..
		"\n\ncropped/%.pdf: small/%.pdf | cropped\n\tpdfcrop '$<' '$@' >>cropped/pdfcrop.log" ..
		"\n\nout: ; mkdir -p out" ..
		"\n\nsmall: ; mkdir -p small" ..
		"\n\ncropped: ; mkdir -p cropped" ..
		"\n\nclean: ; rm -r out small cropped" ..
		"\n\n.PHONY: all clean"
	imap(opts, make_example)
	savedata("Makefile", make)
end

function flatten_groups(opts)
	local result = {}
	for _, t in ipairs(opts) do
		if type(t) == "table" and t[0] then
			for i = 0, #t do
				table.insert(result, t[i])
			end
		else
			table.insert(result, t)
		end
	end
	return result
end

function main()
	local opts = require"opts"
	local flattened_opts = flatten_groups(opts)
	local build = string.find(dir.current(), "build/doc$")
	build_markdown(flattened_opts, build and "README.md" or "README-out.md")
	build_zsh_complete(opts)
	make_examples(flattened_opts)

	if build then
		os.execute("make -j8")
	else
		os.execute("mv Makefile examples")
		os.execute("make -C examples -j8")
	end
end

-- test()
main()
