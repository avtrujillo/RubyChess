module ChessDir
	public
	def chdir_or_mkdir(dir_arg)
		dir_arg = dir_arg[1..-1] if dir_arg [0] == "/"
		Dir.chdir(File.dirname(__dir__ + "/" + dir_arg))
		arg_basename = dir_arg.split("/").last
		begin
			Dir.chdir("./#{arg_basename}")
		rescue
			Dir.mkdir(arg_basename)
		end
	end
	def chdir_or_mkdir_all
		save_dirs = ["/SaveData", "/SaveData/Games", "/SaveData/Games/Unsaved",
		"/SaveData/Games/Unfinished", "/SaveData/Games/Finished", "/SaveData/Players"]
		save_dirs.each {|save_dir| self.chdir_or_mkdir(save_dir)}
	end
	def move_to_save_directory(save_dir)
		path_array = save_dir.split("/")
		if (path_array.last == "Players") || path_array.last == "Games"
			Dir.chdir(__dir__ + "/SaveData/" + path_array.last)
		elsif ["Unfinished", "Unsaved", "Finished"].include?(path_array.last)
			Dir.chdir(__dir__ + "/SaveData/Games/" + path_array.last)
		else
			raise "invalid save destination"
		end
	end
end
