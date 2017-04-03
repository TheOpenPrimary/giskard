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
		attr_accessor :first_name
		attr_accessor :last_name
		attr_accessor :settings
		attr_accessor :bot_upgrade
		attr_accessor :messenger

		# FSM
		attr_accessor :state
		attr_accessor :state_id
		# attr_accessor :previous_state
		# attr_accessor :previous_state_id


		def initialize()
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
			# current state
			params = [
				@id,
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
				@id,
				@messenger
		    ]
		    Bot.db.query("user_update_state", params)
		end

		# load the state
		def load
			# current state
			params = [
				@id,
				@messenger
			]
			res = Bot.db.query("user_select_state", params)

			if res.num_tuples.zero? then
		        return false
		    end
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
		        "user_select_state" => "SELECT * FROM states where user_id=$1 and messenger=$2",
		        "user_insert_state"  => "INSERT INTO states (user_id, messenger) VALUES ($1, $2) RETURNING id;",
		        "user_update_state"  => "UPDATE states SET
						last_msg_id=$1,
						current=$2,
						expected_input=$3,
						expected_size=$4,
						buffer=$5,
						callback=$6,
						previous_screen=$7
						WHERE user_id=$8 and messenger=$9"
		    }
		    queries.each { |k,v| Bot.db.prepare(k,v) }
		end



	end # User
end # Core
end #Giskard
