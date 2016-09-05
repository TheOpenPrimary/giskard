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
	class Navigation
		class << self
			attr_accessor :nav
		end

		# loads all screens
		def self.load_addons
			Dir[File.expand_path('../../bot/addons/*.rb', __FILE__)].sort.each do |f|
				require f
			end
		end

		def initialize
			@users = Bot::Users.new()
			@answers = {}
			@keyboards = {}
			@screens=Bot.screens
			@screens.each do |k,v|
				v.each do |k1,v1|
					if (!v1[:kbd].nil?) then
						SUPPORTED_LOCALES.each do |l|
							@keyboards[l]={} if @keyboards[l].nil?
							@keyboards[l][self.path([k,k1])]=[]
						end
					end
					if (!v1[:answer].nil?) then
						SUPPORTED_LOCALES.each do |l|
							answer=Bot.getMessage(v1[:answer],l)
							raise "Missing translation for message #{v1[:answer]} in locale #{l}" if answer.nil?
							@answers[l]={} if @answers[l].nil?
							@answers[l][answer]={} if @answers[l][answer].nil?
							raise "Conflict of answers detected in add-on \"#{k}\": \"#{answer}\" (locale #{l})" if not @answers[l][answer][k].nil?
							@answers[l][answer][k]=k1
						end
					end
				end
			end
			@keyboards.each do |l,kbd|
				kbd.each do |k,v|
					t=nil
					n1,n2=self.nodes(k).map &:to_sym
					size=@screens[n1][n2][:kbd].length
					@screens[n1][n2][:kbd].each_with_index do |u,i|
						m1,m2=self.nodes(u).map &:to_sym
						raise "Screen identifier #{m1}/#{m2} does not exist" if @screens[m1].nil? or @screens[m1][m2].nil?
						item=Bot.getMessage(@screens[m1][m2][:answer],l)
						@keyboards[l][k].push(item)
					end
				end
			end
			@answers.freeze
			@screens.freeze
			@keyboards.freeze
		end

		def path(nodes)
			nodes.join('/') unless nodes.nil?
		end

		def nodes(path)
			path.split('/',2).map &:to_sym unless path.nil?
		end

		def context(path)
			path.split('/',2)[0] unless path.nil?
		end

		def to_callback(path)
			path.split('/',2).join('_') unless path.nil?
		end

		def get_locale(user)
			return SUPPORTED_LOCALES.include?(user.settings['locale']) ? user.settings['locale'] : 'en'
		end

		# Reads a message and gets an answer to it
		# Call by an interface when a message is received
		# @msg is a class Message. It should have a bot, a text and a seq id.
		# @user is a class User. It is the sender. It should have an id
		# return the next screen
		def get(msg, user)
			Bot.log.debug "Read message from user #{user.id} to bot #{msg.bot} with seq #{msg.seq}: #{msg.text}"

			# load user if registered
			user = @users.open(user)
			_input       = user.state['expected_input']
			_callback    = user.state['callback']

			# we check that this message has not already been answered (i.e. bot sending a msg we already processed)
			return nil,nil if user.already_answered(msg) and not DEBUG

			# if user.seq == 1 and not msg.seq ==-1 then
			#   Bot.log.warn "Bot upgrade detected"
			#   msg.seq =-1
			#   msg.text  ='api/bot_upgrade'
			# end
			# if msg.seq == -1 then
			#   # msg comes from api and not from telegram
			#   api_cb,api_payload=msg.text.split("\n",2).each {|x| x.strip!}
			#   raise "no callback given" if api_cb.nil?
			#   user.next_answer('free_text',1,api_cb)
			#   user.state['api_payload'] = api_payload if !api_payload.nil?
			# end

			# reset
			return self.get_reset(msg, user) if self.is_reset(msg.text)

			# we expect the user to have used the proposed keyboard to answer    
			return self.get_button_answer(msg, user) if _input == 'answer'

			# we expect the user to have answered by typing text manually
			return self.get_text_answer(msg, user) if _input=='free_text' and self.respond_to?(_callback) and user.state['expected_size']>0

			# we didn't expect this message
			return self.dont_understand(msg, user)

			@users.close(user)
		end

		def is_reset(text)
			return RESET_WORDS.include?(text) ? true : false
		end

		def get_reset(msg, user)
			Bot.log.info "#{__method__} #{msg.text}"
			_locale                 = self.get_locale(user)
			user.state['current']   = "houston/welcome"
			_screen                 = self.find_by_name(user.state['current'], _locale)
			_screen                 = self.get_screen(_screen,user,msg)
		end

		def get_button_answer(msg,user)
			Bot.log.info "#{__method__} #{msg.text}"
			_callback          = self.to_callback(user.state['callback'].to_s)
			_locale            = self.get_locale(user)
			_screen            = self.find_by_answer(msg.text,self.context(user.state['current']),_locale)
			if not _screen.nil? then
				_screen           = get_screen(_screen,user,msg)
				_answer           = _screen[:text].nil? ? "" : _screen[:text]
				_current          = user.state['current']
				_screen           = self.find_by_name(_current,_locale) if _screen[:id]!= _current and !_current.nil?
				_jump_to          = _screen[:jump_to]
				while !_jump_to.nil? do
					_next_screen       = find_by_name(_jump_to,_locale)
					_b                 = get_screen(_next_screen,user,msg)
					_answer           += _b[:text] unless _b[:text].nil?
					_screen.merge!(_b) unless _b.nil?
					_screen[:text]     = _answer unless _answer.nil?
					_jump_to           = _next_screen[:jump_to]
				end
			else
				_screen     = self.dont_understand(msg, user)
			end
			return _screen
		end  

		def get_text_answer(msg, user)
			Bot.log.info "#{__method__} #{msg.text}"
			_callback                 	= self.to_callback(user.state['callback'].to_s)
			_locale                   	= self.get_locale(user)
			user.state['expected_size'] -= 1
			user.state['buffer']		= user.state['buffer'] + msg.text unless msg.text.nil?
			_screen                   	= self.find_by_name(user.state['callback'], _locale)
			_input_size					= msg.text.size
			user.state['callback']    	= nil if _input_size==0
			_screen                   	= self.method(_callback).call(msg,user,_screen) if _input_size==0
			_answer                   	= _screen[:text].nil? ? "":screen[:text]
			_jump_to                  	= _screen[:jump_to]
			while !_jump_to.nil? do
				_next_screen              = self.find_by_name(_jump_to,_locale)
				_b                        = self.get_screen(_next_screen,user,msg) # b=screen
				_answer                  += _b[:text] unless _b[:text].nil?
				_screen.merge!(b) unless _b.nil?
				_screen[:text]            = _answer unless _answer.nil?
				_current                  = user.state['current']
				_next_screen              = self.find_by_name(_current, _locale) if _next_screen[:id]!= _current and !_current.nil?
				_jump_to                  = _next_screen[:jump_to]
			end
			return _screen
		end

		# the message is not understood
		def dont_understand(msg,user)
			Bot.log.info "#{__method__} #{msg.text}"
			locale        = self.get_locale(user)
			first_help    = user.settings['actions']['first_help_given']
			if not first_help then
				user.settings['actions']['first_help_given']  = true
				screen      = self.find_by_name("help/first_help",locale)
				screen      = self.format_answer(screen,user)
				callback    = self.to_callback(screen[:callback].to_s) if not screen.nil?
				self.method(callback).call(msg,user,screen) if self.respond_to?(callback)
			elsif user.previous_state.nil? or user.previous_state['current'] != "system/dont_understand" then
				screen      = self.find_by_name("system/dont_understand",locale)
				screen      = self.format_answer(screen,user)
			end
			return screen
		end

		def get_screen(screen,user,msg)
			Bot.log.info "#{__method__} #{screen[:id]}"
			return nil,nil if screen.nil?
			callback=self.to_callback(screen[:callback].to_s) unless screen[:callback].nil?
			previous=caller_locations(1,1)[0].label
			user.state['current'] = screen[:id] 
			unless IGNORE_CONTEXT.include?(self.context(screen[:id])) then
				user.previous_screen = screen
				user.previous_state  = user.state.clone
			end
			if !callback.nil? && previous!=callback && self.respond_to?(callback)
				screen=self.method(callback).call(msg,user,screen.clone)
			else
				screen=self.format_answer(screen.clone,user)
			end
			return screen
		end

		def find_by_name(name,locale='en')
			Bot.log.info "#{__method__} #{name}"
			n1,n2=self.nodes(name)
			begin
				screen=@screens[n1][n2]
				if screen then
					screen[:id]     = name 
					screen          = screen.clone
					screen[:text]   = Bot.getMessage(name,locale)
					screen[:answer] = Bot.getMessage(screen[:answer],locale) unless screen[:answer].nil?
				end
			rescue
				screen=nil
			end
			return screen
		end

		def find_by_answer(answer,ctx=nil,locale='en')
			Bot.log.info "#{__method__} #{answer} context: #{ctx}"
			tmp=@answers[locale][answer]
			return nil if tmp.nil?
			if tmp.length==1
				ctx,screen_id=tmp.flatten
			else
				screen_id=tmp[ctx.to_sym]
			end
			Bot.log.error("find_by_answer: screen for #{answer} not found") if screen_id.nil?
			screen=@screens[ctx.to_sym][screen_id] 
			if screen then
				screen[:id]     = self.path([ctx,screen_id])
				screen          = screen.clone
				screen[:text]   = Bot.getMessage(self.path([ctx,screen_id]),locale)
				screen[:answer] = Bot.getMessage(screen[:answer],locale) unless screen[:answer].nil?
			end
			return screen
		end

		def format_answer(screen,user)
			Bot.log.info "#{__method__}: #{screen[:id]}"
			screen[:text]=screen[:text] % {
				firstname:  user.first_name,
				lastname:   user.last_name,
				id:         user.id,
				username:   user.username
			} unless screen.nil? or screen[:text].nil?
			locale=self.get_locale(user)
			kbd=@keyboards[locale][screen[:id]].clone if @keyboards[locale][screen[:id]]
			if screen[:kbd_del] then
				screen[:kbd_del].each do |k|
					n1,n2=self.nodes(k)
					kbd.delete(Bot.getMessage(@screens[n1][n2][:answer],locale))
				end
			end
			screen[:kbd_add].each { |k| kbd.unshift(k) } if screen[:kbd_add]
			screen[:kbd]=kbd
			return screen
		end
	end
end
