module UserPrompt
	def yesno_prompt(message)
		loop do
			puts message
			response = gets.chomp.downcase
			if response == "yes"
				return true
			elsif response == "no"
				return false
			else
				puts "Sorry, I didn't understand that."
				redo
			end
		end
	end
	def open_ended_prompt(prompt_message)
		raise "message must be a string" unless prompt_message.is_a?(String)
		puts prompt_message
		response = gets.chomp
	end
	def prompt_until_valid(prompt_message, lam, err_message, *args)
		err_message = "Sorry, I didn't understand that" if err_message.nil?
		loop do
			response = open_ended_prompt(prompt_message)
			lam_hash = lam.call(response, *args)
			if lam_hash && (lam_hash[:return] || lam_hash[:valid?])
				return (lam_hash[:return])
			else
				puts (lam_hash.nil? ? err_message : lam_hash[:error])
			end
		end
	end
end
