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
	if not isprerelease then print("Already tagged") return end
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
	return io.open(name):read("a")
end

test_types = {
	jam = {
		test = ".jam",
		reference = ".jamref",
		generated = "", -- it gets an implicit .dryrun anyway
		rewrite = function(source, normalized, engine)
			local dir=source .. ".d/" .. engine .. "/"
			local f = io.open(normalized, "w")
			f:write("%%% a.tex\n", read_file(dir.."a.tex"),
				"\n%%% call.txt\n", rewrite_test_dir(read_file(dir.."call.txt")),
				"\n%%% messages.txt\n",
				rewrite_version(rewrite_test_dir(read_file(dir.."messages.txt"))))
			f:close()
		end
	},
	sh = {
		test = ".sh",
		reference = ".shref",
		generated = ".log",
		rewrite = function(source, normalized) cp(source, ".", normalized) end
	}
}

specialformats = { latex = {
	dryrun = { binary = "./engine dryrun" },
	pdftex = { binary = "./engine pdftex" },
	xetex = { binary = "./engine xetex" },
	luatex = { binary = "./engine luatex" },
} }

checkengines = {"dryrun"}
checkconfigs = {"build"}
lvtext = ".jam" -- Used in check_tex; cannot be overridden there (for whatever reason)
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
	os.remove("release", "pdfjam-ctan.zip")
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
	local f = io.open(builddir .. "/release/ANNOUNCEMENT.md", "w")
	local s = read_file("CHANGELOG.md")
	local i = string.find(s, '# Version ' .. next_version)
	if i then
		s = string.sub(s, i+2)
	else
		s = "Version " .. next_version .. "\n" .. s
		local c = io.open("CHANGELOG.md", 'w')
		c:write("# " .. s)
		c:close()
		if not options["dry-run"] then
			os.execute("git commit --message='Version " .. next_version .. "' CHANGELOG.md")
		end
	end
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

target_list.upload = { pre = function()
	uploadconfig.version = next_version
end }

---- Information for `l3build upload`
uploadconfig = {
	pkg = "pdfjam",
	version = version,
	announcement_file = builddir .. "/release/ANNOUNCEMENT.md",
	author = "David Firth; Reuben Thomas; Markus Kurtz",
	uploader = "Markus Kurtz",
	note = "Please note, that this package contains no PDF documentation, but a comprehensive man page and --help output instead.", -- Note necessary for automatic validation to accept package without PDF documentation.
	license = "lppl",
	summary = "Shell script interface to pdfpages",
	ctanPath = "/support/pdfjam",
	repository = "https://github.com/pdfjam/pdfjam",
	bugtracker = "https://github.com/pdfjam/pdfjam/issues",
	description = [[<p>The package makes available the <tt>pdfjam</tt> shell script that provides a simple interface to much of the functionality of the excellent <a href="/pkg/pdfpages">pdfpages</a> package (by Andreas Matthias) for LaTeX. The <tt>pdfjam</tt> script takes one or more PDF (and/or JPG/PNG) files as input, and produces one or more PDF files as output.</p>
<p>It is useful for joining files together, selecting pages, reducing several source pages onto one output page, etc., etc.</p>]],
	topic = {"pdfprocess"},
}
