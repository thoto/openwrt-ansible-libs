#!/usr/bin/env lua
-- WANT_JSON
local nixio=require("nixio")
local json=require("json")

function die(msg)
	print(json.encode({failed=true, msg=msg}))
	os.exit(1)
end

function make_bool(arg,default) -- make boolean argument
	local BOOLEANS_TRUE = {'y', 'yes', 'on', '1', 'true', 1, true}
	local BOOLEANS_FALSE = {'n', 'no', 'off', '0', 'false', 0, false}

	if arg==nil then return default end
	for _,i in pairs(BOOLEANS_TRUE) do
		if arg==i then return true end
	end
	for _,i in pairs(BOOLEANS_FALSE) do
		if arg==i then return false end
	end
	return default
end

function make_arg(arg,default,options) -- fill in argument of any type
	for _,i in pairs(options) do
		if arg==i then return arg end
	end
	return default
end

function make_stat(path,follow)
	-- returns dict of stat data for path
	local function o(num) -- converts octal string to number
		return tonumber(num,8)
	end

	-- stat and respect follow.
	-- due to a bug in nixio shipped with OpenWRT 15.05.1 this does not work!
	local sr=(follow and nixio.fs.stat(path)) or nixio.fs.lstat(path)
	local output={}

	if sr then
		local modeoct=o(sr['modedec']) -- octal mode representation
		local mode=tostring(sr['modedec']) -- string representation of mode
		if string.len(mode)==3 then
			mode="0"..mode -- always use four digits
		end

		output={ exists=true, path=path,
				mode=mode,
				isdir=(sr["type"]=="dir"),
				ischr=(sr["type"]=="chr"),
				isblk=(sr["type"]=="blk"),
				isreg=(sr["type"]=="reg"),
				isfifo=(sr["type"]=="fifo"),
				islnk=(sr["type"]=="lnk"),
				issock=(sr["type"]=="sock"),
				lnk_source=((not(follow) and nixio.fs.readlink(path)) or nil),
				uid=sr["uid"],
				gid=sr["gid"],
				gr_name=nixio.getgr(sr["gid"])["name"],
				pw_name=nixio.getpw(sr["uid"])["name"],
				size=sr["size"],
				inode=sr["ino"],
				dev=sr["dev"],
				nlink=sr["nlink"],
				atime=sr["atime"],
				mtime=sr["mtime"],
				ctime=sr["ctime"],
				-- file permissions
				rusr=(nixio.bit.band(o(0400),modeoct)~=0),
				wusr=nixio.bit.band(o(0200),modeoct)~=0,
				xusr=nixio.bit.band(o(0100),modeoct)~=0,
				rgrp=nixio.bit.band(o(0040),modeoct)~=0,
				wgrp=nixio.bit.band(o(0020),modeoct)~=0,
				xgrp=nixio.bit.band(o(0010),modeoct)~=0,
				roth=nixio.bit.band(o(0004),modeoct)~=0,
				woth=nixio.bit.band(o(0002),modeoct)~=0,
				xoth=nixio.bit.band(o(0001),modeoct)~=0,
				-- setuid
				isuid=nixio.bit.band(o(4000),modeoct)~=0,
				isgid=nixio.bit.band(o(2000),modeoct)~=0,
				readable=nixio.fs.access(path,"r"),
				writeable=nixio.fs.access(path,"w"),
				excutable=nixio.fs.access(path,"x"), }
	else -- file not found
		output={ exists=false }
	end
	return output
end

-- read arguments
local args_file = arg[1]
local args_fd = io.open(args_file, "r")
local args_raw = json.decode(args_fd:read("*a"))
args_fd:close()

-- parse arguments
args={
	checksum_algorithm=make_arg( (args_raw["checksum_algorithm"] or 
		args_raw["checksum_algo"] or args_raw["checksum"]), "sha1",{"sha1"}),
	get_checksum=make_bool(args_raw["get_checksum"], true),
	get_md5=make_bool(args_raw["get_md5"], true),
	mime=make_bool(args_raw["mime"], false),
	follow=make_bool(args_raw["follow"], false),
	path=args_raw["path"],
}

-- validate arguments
if args['mime'] then  -- TODO not implemented yet
	die("not implemented yet: mime")
end

if args['path']==nil then  -- die if no path given 
	die("missing required arguments: path")
end

if args['get_checksum'] and args['checksum_algorithm']~="sha1" then
	die("no such checksum algorithm available.")
end

out=make_stat(args['path'],make_bool(args['follow'],false))
if out['exists']~=false then
	if args['get_md5'] then 
		local fd=io.popen('md5sum "'..args['path']..'"','r')
		local sum=fd:read("*l")
		fd:close()
		out['md5']=sum:match("%S+")
	end
	if args['get_checksum'] then
		local fd=io.popen('sha1sum "'..args['path']..'"','r')
		local sum=fd:read("*l")
		fd:close()
		out['checksum']=sum:match("%S+")
	end
end

print(json.encode({changed=false,stat=out}))
