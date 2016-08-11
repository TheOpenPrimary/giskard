# encoding: utf-8

=begin
   Copyright 2016 Telegraph-ai

   Licensed under the Apache License, Version 2.0 (the "License");
   you may not use this file except in compliance with the License.
   You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.
=end

# define a class for managing several users


module Bot
	class Users
		def self.load_queries
			queries={}
			queries.each { |k,v| Bot::Db.prepare(k,v) }
		end

		def initialize()
			@users={}
		end

		def add(user)
			## WARNING ## 
			# This is for example purpose only and will work with only 1 unicorn process.
			# If you use more than 1 unicorn process, you should save users in shared memory or a database to ensure data consistency between unicorn processes.
			return 
		end

    # given a User instance with a Bot name and an ID, we look into the database to load missing informations, or to create it in the database
		def open(user)
			res=self.search({
				:by=>"user_id",
				:target=> user.id
			})
			if res.nil? then # new user
				case user.bot #FIXME: this should be inside bot
				when TG_BOT_NAME then
					Bot.log.debug("Nouveau participant : #{user.first_name} #{user.last_name} (<https://telegram.me/#{user.username}|@#{user.username}>)")
				when FB_BOT_NAME then
					res              = URI.parse("https://graph.facebook.com/v2.6/#{user.id}?fields=first_name,last_name,profile_pic,locale,timezone,gender&access_token=#{FB_PAGEACCTOKEN}").read
					r_user           = JSON.parse(res)
					r_user           = JSON.parse(JSON.dump(r_user), object_class: OpenStruct)
          user.first_name  = r_user.first_name
          user.last_name   = r_user.last_name
					Bot.log.debug("Nouveau participant : #{user.first_name} #{user.last_name}")
				end
				self.add(user)
			else
				user = res.clone
			end
			@users[user.id]=user
      return user # we have to return the user because Ruby has no native deep copy
		end
    
    def close(user)
      user.close()
    end
    
		def search(query)
			return @users[query[:target]]
		end
 
	end
end
