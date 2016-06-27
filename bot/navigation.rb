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

		def get(msg,update_id)
			res,options=nil
			user=@users.get(msg.from,msg.date)
			# we check that this message has not already been answered (i.e. telegram sending a msg we already processed)
			return nil,nil if @users.already_answered(user[:id],update_id) and not DEBUG
			session=user['session']
			if user['bot_upgrade'].to_i==1 and not update_id==-1 then
				Bot.log.warn "Bot upgrade detected" 
				update_id=-1
				msg.text='api/bot_upgrade'
			end
			if update_id==-1 then
				# msg comes from api and not from telegram
				api_cb,api_payload=msg.text.split("\n",2).each {|x| x.strip!}
				raise "no callback given" if api_cb.nil?
				@users.next_answer(user[:id],'free_text',1,api_cb)
				session=@users.update_session(user[:id],{'api_payload'=>api_payload}) if !api_payload.nil?
			end
			input=session['expected_input']
			locale=self.get_locale(user)
			session['current']="home/welcome" if RESET_WORDS.include?(msg.text)
			if (input=='answer' or RESET_WORDS.include?(msg.text)) then
				# we expect the user to have used the proposed keyboard to answer
				screen=self.find_by_answer(msg.text,self.context(session['current']),locale)
				if not screen.nil? then
					res,options=get_screen(screen,user,msg)
					user['session']=@users.get_session(user[:id])
					current=user['session']['current']
					screen=self.find_by_name(current,locale) if screen[:id]!=current and !current.nil?
					jump_to=screen[:jump_to]
					while !jump_to.nil? do
						next_screen=find_by_name(jump_to,locale)
						a,b=get_screen(next_screen,user,msg)
						user['session']=@users.get_session(user[:id])
						res="" unless res
						res+=a unless a.nil?
						options.merge!(b) unless b.nil?
						jump_to=next_screen[:jump_to]
					end
				else
					if not user['settings']['actions']['first_help_given'] and not IGNORE_CONTEXT.include?(self.context(user['session']['current'])) then
						screen=self.find_by_name("help/first_help",locale)
					else
						res,options=self.dont_understand(user,msg)
					end
				end
			else # we expect the user to have answered by typing text manually
				callback=self.to_callback(session['callback'].to_s)
			        if input=='free_text' and self.respond_to?(callback) then
					if session['expected_input_size']>0 then
						input_size=session['expected_input_size']-1
						buffer= msg.text.nil? ? session['buffer'] : session['buffer']+msg.text
						session=@users.update_session(user[:id],{'buffer'=>buffer})
						screen=self.find_by_name(session['callback'],locale)
						session_update={'expected_input_size'=>input_size}
						session_update['callback']=nil if input_size==0
						session=@users.update_session(user[:id],session_update)
						user['session']=session
						res,options=self.method(callback).call(msg,user,screen) if input_size==0
						screen=self.find_by_name(session['current'],locale) if session['current']
						jump_to=screen[:jump_to]
						while !jump_to.nil? do
							next_screen=find_by_name(jump_to,locale)
							user['session']=@users.get_session(user[:id])
							a,b=get_screen(next_screen,user,msg)
							res+=a unless a.nil?
							options.merge!(b) unless b.nil?
							user['session']=@users.get_session(user[:id])
							current=user['session']['current']
							next_screen=self.find_by_name(current,locale) if next_screen[:id]!=current and !current.nil?
							jump_to=next_screen[:jump_to]
						end

					end
				end
			end
			res,options=self.dont_understand(user,msg) if res.nil? # if res.nil? then something is fishy
			@users.close_user_session(user[:id])
			return res,options
		end

		def dont_understand(user,msg,reset=false)
			# dedicated method to not affect user session
			Bot.log.info "#{__method__} #{msg}"
			locale=self.get_locale(user)
			if not user['settings']['actions']['first_help_given'] then
				screen=self.find_by_name("help/first_help",locale)
				res,options=self.format_answer(screen,user)
				callback=self.to_callback(screen[:callback].to_s)
				self.method(callback).call(msg,user,screen) if self.respond_to?(callback)
			else
				screen=self.find_by_name("system/dont_understand",locale)
				res,options=self.format_answer(screen,user)
			end
			return res,options
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
				res,options=self.method(callback).call(msg,user,screen.clone)
			else
				res,options=self.format_answer(screen.clone,user)
			end
			return res,options
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
			res=screen[:text] % {
				firstname: user['firstname'],
				lastname: user['lastname'],
				id: user[:id],
				username: user['username']
			} unless screen.nil? or screen[:text].nil?
			locale=self.get_locale(user)
			options={}
			kbd=@keyboards[locale][screen[:id]].clone if @keyboards[locale][screen[:id]]
			if screen[:kbd_del] then
				screen[:kbd_del].each do |k|
					n1,n2=self.nodes(k)
					kbd.delete(Bot.getMessage(@screens[n1][n2][:answer],locale))
				end
			end
			screen[:kbd_add].each { |k| kbd.unshift(k) } if screen[:kbd_add]
			if not kbd.nil? then
				if kbd.length>1 and not screen[:kbd_vertical] then
					# display keyboard on several rows
					newkbd=[]
					row=[]
					kbd.each_with_index do |r,i|
						idx=i+1
						row.push(r)
						if (idx%2)==0 then
							newkbd.push(row)
							row=[]
						end
					end
					newkbd.push(row) if row
					kbd=newkbd
				end
				options[:kbd]=Telegram::Bot::Types::ReplyKeyboardMarkup.new(
					keyboard:kbd,
					resize_keyboard:screen[:kbd_options][:resize_keyboard],
					one_time_keyboard:screen[:kbd_options][:one_time_keyboard],
					selective:screen[:kbd_options][:selective]
				)

			end
			options[:disable_web_page_preview]=true if screen[:disable_web_page_preview]
			options[:groupsend]=true if screen[:groupsend]
			options[:parse_mode]=screen[:parse_mode] if screen[:parse_mode]
			options[:keep_kbd]=true if screen[:keep_kbd]
			return res,options
		end
	end
end
