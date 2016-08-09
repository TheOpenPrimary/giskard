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
			return SUPPORTED_LOCALES.include?(user['settings']['locale']) ? user['settings']['locale'] : 'en'
		end

    # Gets a message and goes to next step if understood 
    # Call by an interface when a message is received
    # @msg is class Message. It is expected to give at least a user's id and a text
		def get(msg)
      if msg.user.nil?
        msg.user = @users.open_user_session(msg.id_user)
      end
      _user    = msg.user 
      
			# we check that this message has not already been answered (i.e. bot sending a msg we already processed)
			return nil,nil if _user.already_answered(msg) and not DEBUG
      
      ## What is bot_upgrade ??
			# session=user['session']
#       if user['bot_upgrade'].to_i==1 and not update_id==-1 then
#         Bot.log.warn "Bot upgrade detected"
#         update_id=-1
#         msg.text='api/bot_upgrade'
#       end
#       if update_id==-1 then
#         # msg comes from api and not from telegram
#         api_cb,api_payload=msg.text.split("\n",2).each {|x| x.strip!}
#         raise "no callback given" if api_cb.nil?
#         @users.next_answer(user[:id],'free_text',1,api_cb)
#         session=@users.update_session(user[:id],{'api _payload'=>api_payload}) if !api_payload.nil?
#       end
      
      # reset
      _reset               = self.is_reset(msg.text)
      if _reset? then
			  user.current  = "home/welcome"
        return ## TODO
      end

			_input               = user.expected_input

			# we expect the user to have used the proposed keyboard to answer    
			if _input == 'answer' then
				_screen = get_button_answer(msg, user)
  			return _screen
      # we expect the user to have answered by typing text manually
      elsif _input=='free_text' and self.respond_to?(_callback) and _session['expected_input_size']>0 then
						screen = get_text_answer(msg, user)
      			return _screen
        end
        
      # we didn't expect this message
			_user, _screen = self.dont_understand(_user,msg)
			return _user, _screen
      # WHY?? @users.close_user_session(user[:id])

		end

    def is_reset(text)
        return RESET_WORDS.include?(msg.text) ? true : false
    end
    
    def get_button_answer(msg,user)
      _callback          = self.to_callback(user.callback.to_s)
			_locale            = self.get_locale(_user)
			_screen            = self.find_by_answer(msg.text,self.context(user.current),_locale)
			if not screen.nil? then
				_user,_screen     = get_screen(_screen,_user,msg)
				_answer           = _screen[:text].nil? ? "" : _screen[:text]
				_user['session']  = @users.get_session(_user[:id])
				_current          = _user['session']['current']
				_screen           = self.find_by_name(_current,_locale) if _screen[:id]!= _current and !_current.nil?
				_jump_to          = _screen[:jump_to]
				while !jump_to.nil? do
					_next_screen       = find_by_name(_jump_to,_locale)
					_a,_b              = get_screen(next_screen,user,msg)
					_user['session']   = @users.get_session(_user[:id])
					_answer           += _b[:text] unless _b[:text].nil?
					_screen.merge!(b) unless _b.nil?
					_screen[:text]     = _answer unless _answer.nil?
					_jump_to           = _next_screen[:jump_to]
				end
			else
				if not _user['settings']['actions']['first_help_given'] and not IGNORE_CONTEXT.include?(self.context(_user['session']['current'])) then
					_screen            = self.find_by_name("help/first_help",_locale)
					_user,_screen      = self.format_answer(_screen, _user)
				else
					_res, _options     = self.dont_understand(_user, _msg)
				end
			end
    end  
    
    def get_text_answer(msg, user)
      _callback                 = self.to_callback(user.callback.to_s)
			_locale                   = self.get_locale(_user)
      user.expected_input_size -= 1
			user.buffer               = user.buffer + msg.text unless msg.text.nil?
			_screen                   = self.find_by_name(user.callback, _locale)
			user.callback             = nil if _input_size==0
			_user,_screen             = self.method(_callback).call(_msg,_user,_screen) if _input_size==0
			_answer                   = _screen[:text].nil? ? "":screen[:text]
			_jump_to                  = _screen[:jump_to]
			while !_jump_to.nil? do
				_next_screen              = self.find_by_name(_jump_to,_locale)
				_a,_b                     = self.get_screen(_next_screen,user,msg) #a=user b=screen
				_answer                  += b[:text] unless _b[:text].nil?
				_screen.merge!(b) unless _b.nil?
				_screen[:text]            = _answer unless _answer.nil?
				_current                  = user.current
				_next_screen              = self.find_by_name(_current, _locale) if _next_screen[:id]!= _current and !_current.nil?
				_jump_to                  = _next_screen[:jump_to]
			end
    end
    
		def dont_understand(user,msg,reset=false)
			# dedicated method to not affect user session
			Bot.log.info "#{__method__} #{msg}"
			locale=self.get_locale(user)
			if not user['settings']['actions']['first_help_given'] then
				screen=self.find_by_name("help/first_help",locale)
				user,screen=self.format_answer(screen,user)
				callback=self.to_callback(screen[:callback].to_s)
				self.method(callback).call(msg,user,screen) if self.respond_to?(callback)
			else
				screen=self.find_by_name("system/dont_understand",locale)
				user,screen=self.format_answer(screen,user)
			end
			return user,screen
		end

		def get_screen(screen,user,msg)
			Bot.log.info "#{__method__} #{screen[:id]}"
			res,options=nil
			return nil,nil if screen.nil?
			callback=self.to_callback(screen[:callback].to_s) unless screen[:callback].nil?
			previous=caller_locations(1,1)[0].label
			session_update={ 'current'=>screen[:id] }
			unless IGNORE_CONTEXT.include?(self.context(screen[:id])) then
				session_update['previous_screen']=screen
				backup_session=user['session'].clone
				backup_session.delete('previous_session')
				backup_session.delete('previous_screen')
				session_update['previous_session']=backup_session
			end
			@users.update_session(user[:id],session_update)
			if !callback.nil? && previous!=callback && self.respond_to?(callback)
				user,screen=self.method(callback).call(msg,user,screen.clone)
			else
				user,screen=self.format_answer(screen.clone,user)
			end
			return user,screen
		end

		def find_by_name(name,locale='en')
			Bot.log.info "#{__method__} #{name}"
			n1,n2=self.nodes(name)
			begin
				screen=@screens[n1][n2]
				if screen then
					screen[:id]=name 
					screen=screen.clone
					screen[:text]=Bot.getMessage(name,locale)
					screen[:answer]=Bot.getMessage(screen[:answer],locale) unless screen[:answer].nil?
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
				screen[:id]=self.path([ctx,screen_id])
				screen=screen.clone
				screen[:text]=Bot.getMessage(self.path([ctx,screen_id]),locale)
				screen[:answer]=Bot.getMessage(screen[:answer],locale) unless screen[:answer].nil?
			end
			return screen
		end

		def format_answer(screen,user)
			Bot.log.info "#{__method__}: #{screen[:id]}"
			screen[:text]=screen[:text] % {
				firstname: user['firstname'],
				lastname: user['lastname'],
				id: user[:id],
				username: user['username']
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
			return user,screen
		end
	end
end
