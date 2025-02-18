module = "pdfjam"

-- For testing, run `l3build check`.
-- For testing tex outputs, run `l3build check -ccheck-tex`.
-- For installing in TEXMFHOME/scripts/pdfjam/, run `l3build install`.
-- For releasing, run `l3build release`, for major releases `l3build release major`.

---- Version information from git tag
version = io.popen("git describe --tags --match 'v?.*' 2>/dev/null"):read()
if version then
	version = string.sub(version, 2)
	isprerelease = string.match(version, "-") ~= nil
else -- As for shallow clones, e.g. in GitHub workflow
	version = "N.NN"
end
-- Step version in tag target etc.
step_version = function(version, part)
	principal_version = string.match(version, '[%d%.]+')
	local major, minor, patch = string.match(principal_version .. '..', '(%d+)%.(%d+)%.(%d*)')
	if part == 'major' then
		return tonumber(major)+1 .. '.0'
	elseif part == 'patch' then
		return major .. '.' .. minor .. '.' .. tonumber('0'..patch)+1
	else
		return major .. '.' .. tonumber(minor)+1
	end
end
make_next_version = function(a)
	if version == 'N.NN' then print('Version information unavailable') return end
	if not isprerelease then
		print("Already tagged")
		next_version = version
		return version
	end
	local part = 'minor'
	if a then part = a[1] end
	next_version = step_version(version, part)
	return next_version
end

---- Constants
-- Defaults are set later. Hence define all values we explicitly use here.
builddir = "build"
testdir = builddir .. "/test"

-- used for l3build install
installfiles = {"pdfjam"} -- also used by l3build check
scriptfiles = {"pdfjam"}
scriptmanfiles = {"build/pdfjam/man/pdfjam.1"}
textfiles = {"COPYING", "README.md"}

---- Test setup
local escape_pattern = function(s)
	return string.gsub(s,"[][^$()%%.*+?-]", "%%%0")
end
local rewrite_test_dir = function(s)
	return (string.gsub(s, escape_pattern(abspath(testdir)), "<TESTDIR>"))
end
local rewrite_version = function(s)
	return (string.gsub(s, "pdfjam version [%x.gN-]+", "pdfjam version N.NN."))
end

read_file = function(name)
	f = io.open(name) or error("Could not open " .. name)
	s = f:read("a")
	f:close()
	return s
end

function compare_completions(difffile, reffile, genfile, cleanup, name, engine)
	s = read_file(reffile)
	ref = io.open(reffile .. ".multi", "w")
	gen = io.open(genfile)
	for l in gen:lines() do
		if string.match(l, "^>>> .*%.%.%.$") then
			ref:write(l .. "\n" .. s)
		end
	end
	gen:close()
	ref:close()
	local errorlevel = os.execute("diff --unified=0 --show-function-line='^>>> .*\\.\\.\\.$' "
		.. normalize_path(reffile .. ".multi " .. genfile .. " > " .. difffile))
	if errorlevel == 0 or cleanup then
		os.remove(difffile)
	end
	return errorlevel
end

function rewrite_multi_to_single_ref(reffile)
	s = read_file(reffile)
	_, begin_first_ref = string.find(s, "^>>> [^\n]*%.%.%.\n")
	if not begin_first_ref then
		print("Reference file " .. reffile .. " must start with >>> before rewriting.")
		return 1
	end
	header_second_ref = string.find(s, "\n>>> .*%.%.%.\n", begin_first_ref) or -1
	mref = io.open(reffile, "w")
	mref:write(string.sub(s, begin_first_ref+1, header_second_ref))
	mref:close()
end

target_list.save.func = function(a)
	if stdengine == "zsh" then
		local errorlevel = 0
		errorlevel = save(a)
		for i,name in ipairs(a) do
			reffile = testfiledir .. "/" .. name .. ".ref"
			if fileexists(reffile) then
				rewrite_multi_to_single_ref(reffile)
			end
		end
		return errorlevel
	else
		save(a)
	end
end

test_types = {
	jam = {
		test = ".jam",
		reference = ".jamref",
		generated = "", -- it gets an implicit .dryrun anyway
		rewrite = function(source, normalized, engine)
			local dir=source .. ".d/" .. engine .. "/"
			local f = io.open(normalized, "w")
			f:write("%%% a.tex\n", read_file(dir.."a.tex"))
			f:close()
		end
	},
	sh = {
		test = ".sh",
		reference = ".shref",
		generated = ".log",
		rewrite = function(source, normalized) cp(source, ".", normalized) end
	},
	zsh = { -- for completion tests
		test = ".in",
		reference = ".ref",
		generated = ".out",
		rewrite = function(source, normalized) cp(source, ".", normalized) end,
		compare = compare_completions
	},
}

specialformats = { latex = {
	dryrun = { binary = "./engine dryrun" },
	pdftex = { binary = "./engine pdftex" },
	xetex = { binary = "./engine xetex" },
	luatex = { binary = "./engine luatex" },
	zsh = { binary = "./complete zsh" },
} }

checkengines = {"dryrun"}
checkconfigs = {"build"}
lvtext = ".jam" -- Used in check-tex; cannot be overridden there (for whatever reason)
test_order = {"jam", "sh"}

-- Symlink all binaries needed by pdfjam to allow resetting PATH
checkinit_hook = function(_)
	return os.execute("utils/sandbox.sh") and 0 or 1
end

---- Overwrite unpacking (used by most targets)
bundleunpack = function()
	if not version then return 1 end
	return os.execute("utils/build.sh " .. version)
end

---- Self-made targets
ctanzip = "build/release/pdfjam-ctan"
target_list.ctan.func = function(a)
	if not make_next_version(a) then return 1 end
	os.execute("utils/build.sh " .. next_version)
	os.remove(ctanzip .. '.zip')
	return runcmd("zip -r release/pdfjam-ctan.zip pdfjam", builddir)
end

target_list.release = { func = function(a)
	if not make_next_version(a) then return 1 end
	if isprerelease then target_list.tag.func(a) end
	target_list.ctan.func()
	if options["dry-run"] then
		return 0
	else
		os.execute("utils/github.sh " .. next_version)
		uploadconfig.version = next_version
		return target_list.upload.func()
	end
end }

target_list.tag = { func = function(a)
	if not make_next_version(a) then return 1 end
	if not isprerelease then print("Already tagged") return 1 end
	if io.popen('git status --porcelain --untracked-files=no'):read() then
		print('Uncommited files found. Using dry-run.')
		options["dry-run"] = true
	end
	mkdir(builddir .. "/release")
	local s = read_file("CHANGELOG.md")
	local _, i = string.find(s, '# Version ' .. next_version .. "\n")
	if i then
		s = string.sub(s, i+1)
	else
		local c = io.open("CHANGELOG.md", 'w')
		c:write("# Version " .. next_version .. "\n" .. s)
		c:close()
		if not options["dry-run"] then
			os.execute("git commit --message='Version " .. next_version .. "' CHANGELOG.md")
		end
	end
	local f = io.open(builddir .. "/release/ANNOUNCEMENT.md", "w")
	f:write(string.sub(s, 1, string.find(s, "\n# Version ")-1))
	f:close()
	if options["dry-run"] then
		os.execute('git diff CHANGELOG.md')
		os.execute('pager ' .. builddir .. '/release/ANNOUNCEMENT.md')
		print("git tag --sign --file="..builddir.."/release/ANNOUNCEMENT.md v" .. next_version)
		return 0
	else
		return os.execute("git tag --sign --file="..builddir.."/release/ANNOUNCEMENT.md v" .. next_version) and 0 or 1
	end
end }

---- Information for `l3build upload`
uploadconfig = {
	pkg = "pdfjam",
	version = version,
	announcement_file = builddir .. "/release/ANNOUNCEMENT.md",
	author = "David Firth; Reuben Thomas; Markus Kurtz",
	uploader = "Markus Kurtz",
	note = "Please note, that this package contains no PDF documentation, but a comprehensive man page and --help output instead.", -- Note necessary for automatic validation to accept package without PDF documentation.
	license = "gpl2+",
	summary = "Shell script interface to pdfpages",
	ctanPath = "/support/pdfjam",
	repository = "https://github.com/pdfjam/pdfjam",
	bugtracker = "https://github.com/pdfjam/pdfjam/issues",
	description = [[<p>The package makes available the <tt>pdfjam</tt> shell script that provides a simple interface to much of the functionality of the excellent <a href="/pkg/pdfpages">pdfpages</a> package (by Andreas Matthias) for LaTeX. The <tt>pdfjam</tt> script takes one or more PDF (and/or JPG/PNG) files as input, and produces one or more PDF files as output.</p>
<p>It is useful for joining files together, selecting pages, reducing several source pages onto one output page, etc., etc.</p>]],
	topic = {"pdfprocess"},
}
