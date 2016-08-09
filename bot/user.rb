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

# define a class for 1 user


module Giskard
	class User
    # general attr
    attr_accessor :id                # id of the user
    attr_accessor :first_name          
    attr_accessor :last_name         
    attr_accessor :username          
    attr_accessor :session
    attr_accessor :settings
    
    # FSM
    attr_accessor :callback
    attr_accessor :expected_size   # when typing a text
    attr_accessor :expected_input  # "answered" when keyboard, "free_text" when text
    attr_accessor :current         # current state
		attr_accessor :buffer

		def initialize()
      self.initialize_fsm()
			user_settings={
				'blocked'=>{ 'abuse'=>false }, # the user has clearly done bad things 
				'actions'=>{ 'first_help_given'=>false },
				'locale'=>'fr'
			}
		end

		def reset()
			Bot.log.info "reset user #{@username}"
      self.initialize()
		end
    
    # ___________________________________
    # fsm
    # -----------------------------------
    def initialize_fsm()
			@last_update_id=>nil,
			@current=>nil,
			@expected_input=>"answer",
			@expected_size=>-1,
			@buffer=>""
    end
    
		def next_answer(type,size=-1,callback=nil,buffer="")
			@buffer               = buffer,
		  @expected_input       = type,
		  @expected_input_size  = size,
			@callback             = callback
		end
		def already_answered(user_id,update_id)
			return false if update_id==-1 # external command
			session=@users[user_id]['session']
			return true if not session['last_update_id'].nil? and session['last_update_id'].to_i>update_id.to_i
			self.update_session(user_id,{'last_update_id'=>update_id.to_i})
			return false
		end

		def search(query)
			return @users[query[:target]]
		end

		def previous_state(user_id)
			user=@users[user_id]
			screen=user['session']['previous_screen']
			return nil if screen.nil?
			screen=Hash[screen.map{|(k,v)| [k.to_sym,v]}] # pas recursif
			screen[:kbd_options]=Hash[screen[:kbd_options].map{|(k,v)| [k.to_sym,v]}] unless screen[:kbd_options].nil?
			@users[user_id]['session']=user['session']['previous_session'].clone unless user['session']['previous_session'].nil?
			return screen
		end
    
    # ___________________________________
    # loading - saving
    # -----------------------------------
		def open_user_session(user_info,bot)
			res=self.search({
				:by=>"user_id",
				:target=>user_info['id']
			})
			if res.nil? then # new user
				case bot
				when TG_BOT_NAME then
					Bot.log.debug("Nouveau participant : #{user_info['first_name']} #{user_info['last_name']} (<https://telegram.me/#{user_info['username']}|@#{user_info['username']}>)")
					user=self.add(user_info)
				when FB_BOT_NAME then
					res = URI.parse("https://graph.facebook.com/v2.6/#{user_info['id']}?fields=first_name,last_name,profile_pic,locale,timezone,gender&access_token=#{FB_PAGEACCTOKEN}").read
					user=JSON.parse(res)
					user['id']=user_info['id']
					user=JSON.parse(JSON.dump(user), object_class: OpenStruct)
					Bot.log.debug("Nouveau participant : #{user_info['first_name']} #{user_info['last_name']}")
				end
				user=self.add(user)
			else
				user=res
			end
			user[:id]=user['user_id']
			@users[user[:id]]=user
			return user
		end

		def save_user_session()
			return
		end

		def close_user_session()
			self.save_user_session(user_id)
			# @users.delete(user_id) # To be uncommented once a persistant storage is in place
		end


	end
end
