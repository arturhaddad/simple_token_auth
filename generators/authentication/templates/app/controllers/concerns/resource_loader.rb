module ResourceLoader
	extend ActiveSupport::Concern
	# include CustomExceptions

	# This method expects that your controllers are all under /#{any_word}/v#{any_number}/path_to_resource
	def load_resource(query_params = "")

		query_array = parse_request_path

		#print "\n\nquery_array: #{query_array}\n\n"

		query_array_size = query_array.size

		if query_array_size.even?
			my_var, query_str = build_member_query(query_array, query_array_size)
		else
			my_var, query_str = build_collection_or_singleton_query(query_array, query_array_size)
		end

		unless query_params.blank?
			query_params = "." + query_params
		end
		#print "\n\nquery_string: #{query_str + query_params}\n\n"

		# begin
		print "\n\nQuery str: #{query_str}\n\n"
		print "\n\nQuery params: #{query_params}\n\n"
		print "\n\nQuery gen: #{query_str + query_params}\n\n"
		instance_variable_set("@#{my_var}", eval(query_str + query_params))
		# rescue NoMethodError => err
		# 	query_str = query_str.reverse.gsub(/^[^.]*/, "").reverse
		# 	instance_variable_set("@#{my_var}", eval(query_str.reverse.gsub(/^[^.]*/, "").reverse.chomp(".") + query_params))
		# end

	end

	private

		def parse_request_path
			#print "\n\nrequest fullpath: #{request.original_fullpath.gsub(/\/\w+\/v\d+\//, "")[/[^?]+/]}\n\n"
			query_string = request.original_fullpath.gsub(/\/\w+\/v\d+\//, "")[/[^?]+/]
			query_array = Array.new

			while query_string[0] == "/" do
				query_string[0] = ""
			end

			query_array[0] = query_string.match(/^[^[\/\z]]*/).to_s

			query_string.gsub!(/^[^\/\z]*/, "")

			count = 0

			while !query_string.blank? do

				if query_string[0] == "/"
					query_string[0] = ""
				end

				unless query_string.blank?
					count+= 1
					query_array[count] = query_string.match(/^[^[\/\z]]*/).to_s
					query_string.gsub!(/^[^[\/\z]]*/, "")
				end
			end

			if query_array.last == params[:action]
				query_array.pop # for custom actions
			end

			return query_array

		end

		def build_member_query(qa, qa_size)

			query_str = qa[0].singularize.camelize + ".find(" + qa[1].to_s + ")"

			if qa_size > 2
				for i in 1..((qa_size/2)-1)
					query_str+= "." + qa[i*2] + ".find(" + qa[(i*2)+1].to_s + ")"
					# Rails.logger.info("\n\nquery_str Iteration[#{i}]: " + query_str.to_s + "\n\n")
				end
			end

			my_var = params[:controller].gsub(/\w+\/v\d+\//, "").singularize

			return my_var, query_str
		end

		def build_collection_or_singleton_query(qa, qa_size)

			if qa_size == 1
				query_str = qa[0].singularize.camelize + ".all"
			else
				query_str = qa[0].singularize.camelize + ".find(" + qa[1].to_s + ")"
				# if qa[0] == "users"
				# 	query_str+= ".profile"
				# end
			end

			if qa_size > 1
				for i in 1..((qa_size/2))
					print "\n\nQuery str: #{query_str}\n\n"
					if ((i*2)+1) == qa_size
						query_str+= "." + qa.last
					else
						query_str+= "." + qa[i*2] + ".find(" + qa[(i*2)+1] + ")"
					end
				end
			end

			controller_resource = params[:controller].gsub(/\w+\/v\d+\//, "")

			if controller_resource == qa.last
				my_var = controller_resource
			else
				my_var = controller_resource.singularize
			end

			# instance_variable_set("@#{my_var}", query_str)
			return my_var, query_str
		end

end
