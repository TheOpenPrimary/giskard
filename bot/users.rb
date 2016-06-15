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
			bot_session={
				'last_update_id'=>nil,
				'current'=>nil,
				'expected_input'=>"answer",
				'expected_input_size'=>-1,
				'buffer'=>""
			}
			user_settings={
				'blocked'=>{
					'abuse'=>false # the user has clearly done bad things 
				},
				'actions'=>{
					'first_help_given'=>false
				}
			}
			@users[user.id]={
				'firstname'=>user.first_name,
				'lastname'=>user.last_name,
				'username'=>user.last_name,
				'session'=>bot_session,
				'settings'=>user_settings
			}
			return @users[user.id] 
		end

		def reset(user)
			Bot.log.info "reset user #{user}"
			bot_session={
				'last_update_id'=>nil,
				'current'=>nil,
				'expected_input'=>"answer",
				'expected_input_size'=>-1,
				'buffer'=>""
			}
			user_settings={
				'blocked'=>{
					'abuse'=>false # the user has clearly done bad things 
				},
				'actions'=>{
					'first_help_given'=>false
				}
			}
			self.update_settings(user[:id],user_settings)
			@users[user[:id]]['session']={
				'last_update_id'=>nil,
				'current'=>nil,
				'expected_input'=>"answer",
				'expected_input_size'=>-1,
				'buffer'=>""
			}
			self.save_user_session(user[:id])
		end

		def get_session(user_id)
			return @users[user_id]['session']
		end

		def clear_session(user_id,key)
			@users[user_id]['session'].delete(key)
		end

		def update_session(user_id,data)
			data.each do |k,v|
				@users[user_id]['session'][k]=v
			end
			return self.get_session(user_id)
		end

		def update_settings(user_id,data)
			@users[user_id]['settings']=Bot.mergeHash(@users[user_id]['settings'],data)
			return @users[user_id]['settings']
		end

		def next_answer(user_id,type,size=-1,callback=nil,buffer="")
			@users[user_id]['session'].merge!({
				'buffer'=>buffer,
				'expected_input'=>type,
				'expected_input_size'=>size,
				'callback'=>callback
			})
		end

		def get(user_info,date)
			res=self.search({
				:by=>"user_id",
				:target=>user_info.id
			})
			if res.nil? then # new user
				Bot.log.debug("Nouveau participant : #{user_info.first_name} #{user_info.last_name} (<https://telegram.me/#{user_info.username}|@#{user_info.username}>)")
				user=self.add(user_info)
			else
				user=res
			end
			@users[user[:id]]=user
			return user
		end

		def save_user_session(user_id)
			return
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
	end
end
