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

# parent class for User. Contains what is used by the core Bot


module Giskard
	module Core
	class User
		# general attr
		attr_accessor :uid
		attr_accessor :email
		attr_accessor :first_name
		attr_accessor :last_name
		attr_accessor :settings
		attr_accessor :bot_upgrade
		attr_accessor :messenger

		# FSM
		attr_accessor :state
		attr_accessor :state_id

		def initialize()
			@first_name = ""
			@last_name = ""
			@email = ""
			self.initialize_fsm()
			@settings={
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
			@state = {
				'last_msg_id'     => 0,
				'current'         => nil,
				'expected_input'  => "answer",
				'expected_size'   => -1,
				'buffer'          => "",
				'callback'        => ""
			}
			@previous_state = @state.clone
		end

		def next_answer(type,size=-1,callback=nil,buffer="")
			@state['buffer']          = buffer
			@state['expected_input']  = type
			@state['expected_size']   = size
			@state['callback']        = callback
		end


		def previous_state()
			screen=@state['previous_screen']
			return nil if screen.nil?
			screen=Hash[screen.map{|(k,v)| [k.to_sym,v]}] # pas recursif
			screen[:kbd_options]=Hash[screen[:kbd_options].map{|(k,v)| [k.to_sym,v]}] unless screen[:kbd_options].nil?
			@state = @previous_state.clone unless @previous_state.nil?
			return screen
		end


		def create
			params = [
				@first_name,
				@last_name,
				@email
			]
			res = Bot.db.query("user_insert", params)
			@uid = res[0]['id'];


			# current state
			params = [
				@uid,
				@messenger
			]
			res = Bot.db.query("user_insert_state", params)
			@state_id = res[0]['id'];
		end


		# save the state
		def save

			# current state
			params = [
		        @state['last_msg_id'],
		        YAML::dump(@state['current']),
		        @state['expected_input'],
		        @state['expected_size'],
				@state['buffer'],
				@state['callback'],
				YAML::dump(@state['previous_screen']),
				@uid
		    ]
		    Bot.db.query("user_update_state", params)

			params = [
				@uid,
				@first_name,
				@last_name,
				@email,
				Time.now()
			]
			Bot.db.query("user_update", params)
		end

		# load the user
		def load
			params = [
				@uid
			]
			res = Bot.db.query("user_select", params)
			puts "Loading users... "
			if res.num_tuples.zero? then
		        return false
		    end
			puts res[0]
			@first_name = res[0]['first_name']
			@last_name = res[0]['last_name']
			@email = res[0]['email']
		    @state['last_msg_id'] = res[0]['last_msg_id'].to_i
			@state['current'] = YAML::dump(res[0]['current'])
			@state['expected_input'] = res[0]['expected_input']
			@state['expected_size']= res[0]['expected_size'].to_i
			@state['buffer'] = res[0]['buffer']
			@state['callback']= res[0]['callback']
			@state['previous_screen'] = YAML::dump(res[0]['previous_screen'])
		    return true
		end


		# database queries to prepare
		def self.load_queries
		    queries={
				"user_select" => "SELECT * FROM users, states where users.id=$1 and states.uid=$1",
		        "user_insert"  => "INSERT INTO users (first_name, last_name, email) VALUES ($1, $2, $3) RETURNING id;",
		        "user_update"  => "UPDATE users SET
						first_name=$2,
						last_name=$3,
		                email=$4,
						last_date=$5
		                WHERE id=$1",
		        "user_insert_state"  => "INSERT INTO states (uid, messenger) VALUES ($1, $2) RETURNING id;",
		        "user_update_state"  => "UPDATE states SET
						last_msg_id=$1,
						current=$2,
						expected_input=$3,
						expected_size=$4,
						buffer=$5,
						callback=$6,
						previous_screen=$7
						WHERE uid=$8"
		    }
		    queries.each { |k,v| Bot.db.prepare(k,v) }
		end



	end # User
end # Core
end #Giskard
