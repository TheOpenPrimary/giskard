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

require_relative 'navigation.rb'

module Giskard
	class TelegramBot < Grape::API
		prefix TG_WEBHOOK_PREFIX.to_sym
		format :json
		class << self
			attr_accessor :client
		end

		helpers do
			def authorized
				headers['Secret-Key']==TG_SECRET
			end

			def format_answer(screen)
				options={}
				if (not screen[:kbd].nil?) then
					kbd=screen[:kbd]
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
						newkbd.push(row) if not row.empty?
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
				return screen,options
			end

			def send_msg(id,msg,options)
				if options[:keep_kbd] then
					options.delete(:keep_kbd)
				else
					kbd = options[:kbd].nil? ? Telegram::Bot::Types::ReplyKeyboardHide.new(hide_keyboard: true) : options[:kbd] 
				end
				lines=msg[:text].split("\n")
				buffer=""
				max=lines.length
				idx=0
				image=false
				kbd_hidden=false
				lines.each do |l|
					next if l.empty?
					idx+=1
					image=(l.start_with?("image:") && (['.jpg','.png','.gif','.jpeg'].include? File.extname(l)))
					if image && !buffer.empty? then # flush buffer before sending image
						writing_time=buffer.length/TYPINGSPEED
						TelegramBot.client.api.send_chat_action(chat_id: id, action: "typing")
						sleep(writing_time)
						TelegramBot.client.api.sendMessage(chat_id: id, text: buffer)
						buffer=""
					end
					if image then # sending image
						img_url=l.split(":",2)[1]
						if not img_url.match(/http/).nil? then
							img='static/tmp/image'+File.extname(img_url)
							File.open(img, 'wb') do |fo|
								  fo.write open(img_url).read 
							end
							img_url=img
						end
						img=File.new(img_url)
						TelegramBot.client.api.send_chat_action(chat_id: id, action: "upload_photo")
						TelegramBot.client.api.send_photo(chat_id: id, photo: img)
					elsif options[:groupsend] # grouping lines into 1 single message # buggy
						buffer+=l
						if (idx==max) then # flush buffer
							writing_time=l.length/TYPINGSPEED
							TelegramBot.client.api.sendChatAction(chat_id: id, action: "typing")
							sleep(writing_time)
							TelegramBot.client.api.sendMessage(chat_id: id, text: buffer, reply_markup:kbd)
							buffer=""
						end
					else # sending 1 msg for every line
						writing_time=l.length/TYPINGSPEED
						writing_time=l.length/TYPINGSPEED_SLOW if max>1
						TelegramBot.client.api.sendChatAction(chat_id: id, action: "typing")
						sleep(writing_time)
						options[:chat_id]=id
						temp_web_page_preview_disabling=false
						if l.start_with?("no_preview:") then
							temp_web_page_preview_disabling=true
							l=l.split(':',2)[1]
							options[:disable_web_page_preview]=true
						end
						options[:text]=l
						if idx<max and not kbd_hidden then
							options[:reply_markup]=Telegram::Bot::Types::ReplyKeyboardHide.new(hide_keyboard: true)
							kbd_hidden=true
						elsif (idx==max)
							options[:reply_markup]=kbd
						end
						TelegramBot.client.api.sendMessage(options)
						options.delete(:disable_web_page_preview) if temp_web_page_preview_disabling
					end
				end
			end
		end

		post '/command' do
			error!('401 Unauthorized', 401) unless authorized
			begin
				Bot::Db.init()
				update = Telegram::Bot::Types::Update.new(params)
        text            = update.message.text
        id              = update.message.chat.id
        id_receiv       = update.message.from.id
        user            = Bot::User.new(id_receiv, TG_BOT_NAME)
        user.username   = update.message.from.username
        user.last_name  = update.message.from.last_name
        user.first_name = update.message.from.first_name
        msg             = Giskard::Message.new(id, text, user, 0, TG_BOT_NAME)
				user,screen=Bot.nav.get(msg, user)
				msg,options=format_answer(screen)
				send_msg(update.message.chat.id,msg,options) unless msg.nil?
			rescue Exception=>e
				Bot.log.fatal "#{e.message}\n#{e.backtrace.inspect}"
				error! "Exception raised: #{e.message}", 200 # if you put an error code here, telegram will keep sending you the same msg until you die
			ensure
				Bot::Db.close()
			end
		end

		post '/' do
			begin
				Bot::Db.init() ## FIXME not good for perf to start the db each time
				update          = Telegram::Bot::Types::Update.new(params)
				if update.message.chat.type=="group" then
					Bot.log.error "Message from group chat not supported:\n#{update.inspect}"
					error! "Msg from group chat not supported: #{update.inspect}", 200 # if you put an error code here, telegram will keep sending you the same msg until you die
				end
        text            = update.message.text
        id              = update.message.chat.id
        id_receiv       = update.message.from.id
        user            = Bot::User.new(id_receiv, TG_BOT_NAME)
        user.username   = update.message.from.username
        user.last_name  = update.message.from.last_name
        user.first_name = update.message.from.first_name
        msg             = Giskard::Message.new(id, text, id, TG_BOT_NAME) # FIXME what is the seq id ?
        
        # handle new message
				user,screen     = Bot.nav.get(msg, user)
        
        # send answer
				answer,options  = format_answer(screen)
				send_msg(msg.chat.id,answer,options) unless answer.nil?
			rescue Exception=>e
				# Having external services called here was a VERY bad idea as exceptions would not be rescued, it would make the worker crash... good job stupid !
				Bot.log.fatal "#{e.message}\n#{e.backtrace.inspect}\n#{update.inspect}"
				if e.message.match(/blocked/).nil? and e.message.match(/kicked/).nil? then
					Giskard::TelegramBot.client.api.sendChatAction(chat_id: id, action: "typing")
					Giskard::TelegramBot.client.api.sendMessage({
						:chat_id=>id,
						:text=>"Oops... an unexpected error occurred #{Bot.emoticons[:confused]} Please type /start to reinitialize our discussion.",
						:reply_markup=>Telegram::Bot::Types::ReplyKeyboardHide.new(hide_keyboard: true)
					})
				end
				error! "Exception raised: #{e.message}", 200 # if you put an error code here, telegram will keep sending you the same msg until you die
			ensure
				Bot::Db.close()
			end
		end
	end
end
