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
    attr_accessor :settings
    attr_accessor :bot_upgrade
    
    # FSM
    attr_accessor :state
#    attr_accessor :callback
 #   attr_accessor :expected_size   # when typing a text
 #   attr_accessor :expected_input  # "answered" when keyboard, "free_text" when text
#    attr_accessor :current         # current state
#		attr_accessor :buffer
 #   attr_reader   :last_update_id
    attr_reader   :previous_state
    attr_reader   :previous_screen

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
			@state['last_update_id']  = nil
			@state['current']         = nil
			@state['expected_input']  = "answer"
			@state['expected_size']   = -1
			@state['buffer']          = ""
      @previous_state = @state.clone
    end
    
		def next_answer(type,size=-1,callback=nil,buffer="")
			@state['buffer']          = buffer
		  @state['expected_input']  = type
		  @state['expected__size']  = size
			@state['callback']        = callback
		end
    
		def already_answered(msg)
			return false if msg.id ==-1 # external command
			return true if not @last_update_id.nil? and @last_update_id.to_i>msg.to_i # FIXME what is to_i ?
			@last_update_id = update_id.to_i
			return false
		end

		def previous_state()
			screen=@session['previous_screen']
			return nil if screen.nil?
			screen=Hash[screen.map{|(k,v)| [k.to_sym,v]}] # pas recursif
			screen[:kbd_options]=Hash[screen[:kbd_options].map{|(k,v)| [k.to_sym,v]}] unless screen[:kbd_options].nil?
			@state = @previous_state.clone unless @previous_state.nil?
			return screen
		end
    
    # ___________________________________
    # loading - saving
    # -----------------------------------
		def save()
			return
		end

		def close()
			self.save()
			# @users.delete(user_id) # To be uncommented once a persistant storage is in place
		end


	end
end
