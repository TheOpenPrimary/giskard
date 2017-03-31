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
	class FBMessengerBot < Grape::API
		prefix FB_WEBHOOK_PREFIX.to_sym
		format :json

		def self.send(payload,type="messages",file_url=nil)
			Bot.log.debug "sending payload via #{type} :"
			Bot.log.debug payload
			if file_url.nil? then
				res = RestClient.post "https://graph.facebook.com/v2.6/me/#{type}?access_token=#{FB_PAGEACCTOKEN}", payload.to_json, :content_type => :json
			else # image upload 
				params={"recipient"=>payload['recipient'], "message"=>payload['message'], "filedata"=>File.new(file_url,'rb'),"multipart"=>true}
				res = RestClient.post "https://graph.facebook.com/v2.6/me/#{type}?access_token=#{FB_PAGEACCTOKEN}",params
			end
			Bot.log.debug "sending done (code: #{res.code})"
		end

		def self.init() 
			payload={ "greeting"=>[
				{ "locale":"default","text"=>"Bonjour {{user_first_name}}, merci pour votre intérêt pour le jugement majoritaire !" }
			]}
			Giskard::FBMessengerBot.send(payload,"messenger_profile")
		end

		helpers do
			def authorized # Used for API calls and to verify webhook
				headers['Secret-Key']==FB_SECRET
			end

			def send_msg(id,text,kbd=nil,attachment=nil)
				msg={"recipient"=>{"id"=>id}}
				if not kbd.nil? then
					msg["message"]={
						"text"=>text,
						"quick_replies"=>[]
					}
					kbd.each do |k|
						title=k['title'].nil? ? k['text'] : k['title']
						payload=k['payload'].nil? ? k['text'] : k['payload']
						image_url=k['image_url'].nil? ? nil : k['image_url']
						qr={
							"content_type"=>"text",
							"title"=>title,
							"payload"=>payload
						}
						qr["image_url"]=image_url unless image_url.nil?
						msg["message"]["quick_replies"].push(qr)
					end
				elsif not attachment.nil? then
					msg["message"]={ "attachment"=>attachment }
				else
					msg["message"]={ "text"=>text }
				end
				Giskard::FBMessengerBot.send(msg)
			end

			def send_typing(id)
				Giskard::FBMessengerBot.send({"recipient"=>{"id"=>id},"sender_action"=>"typing_on"})
			end

			def send_image(id,img_url)
				payload={"recipient"=>{"id"=>id},"message"=>{"attachment"=>{"type"=>"image","payload"=>{}}}}
				if not img_url.match(/http/).nil? then
					payload["message"]["attachment"]["payload"]={"url"=>img_url}
					Giskard::FBMessengerBot.send(payload)
				else
					Giskard::FBMessengerBot.send(payload,"messages",img_url)
				end
			end

			def process_msg(id,msg,options)
				lines=msg.split("\n")
				buffer=""
				max=lines.length
				idx=0
				image=false
				kbd=nil 
				attachment=nil 
				lines.each do |l|
					next if l.empty?
					idx+=1
					image=(l.start_with?("image:") && (['.jpg','.png','.gif','.jpeg'].include? File.extname(l)))
					if image && !buffer.empty? then # flush buffer before sending image
						writing_time=buffer.length/TYPINGSPEED
						send_typing(id)
						sleep(writing_time)
						send_msg(id,buffer)
						buffer=""
					end
					if image then # sending image
						send_typing(id)
						send_image(id,l.split(":",2)[1])
					else # sending 1 msg for every line
						writing_time=l.length/TYPINGSPEED
						writing_time=l.length/TYPINGSPEED_SLOW if max>1
						send_typing(id)
						sleep(writing_time)
						if l.start_with?("no_preview:") then
							l=l.split(':',2)[1]
						end
						if (idx==max)
							kbd=options[:kbd]
							attachment=options[:attachment]
						end
						send_msg(id,l,kbd,attachment)
					end
				end
			end
		end

		# challenge for creating a webhook
		get '/fbmessenger' do
			if params['hub.verify_token']==FB_SECRET then
				return params['hub.challenge'].to_i
			else
				return "nope"
			end
		end

		# we receive a new message
		post '/fbmessenger' do
			entries     = params['entry']
			entries.each do |entry|
				entry.messaging.each do |messaging|
					Bot.log.debug "#{messaging}"
					id_sender = messaging.sender.id
					id_receiv = messaging.recipient.id
					id        = messaging.message.nil? ? nil : messaging.message.mid
					seq       = messaging.message.nil? ? nil : messaging.message.seq
					timestamp = messaging.timestamp
					postback  = messaging.postback
					if not messaging.message.nil? then
						msg = Giskard::FB::Message.new(id, messaging.message.text, seq, FB_BOT_NAME)
					elsif not postback.nil? then
						msg = Giskard::FB::Message.new(id, postback.payload, seq, FB_BOT_NAME)
					end
					user     = Bot::User.new()
					user.id  = id_sender
					user.bot = FB_BOT_NAME
					if not msg.nil? then
						# read message
						msg.timestamp = timestamp
						screen        = Bot.nav.get(msg, user)
						# send answer
						process_msg(user.id,screen[:text],screen) unless screen[:text].nil?
					end
				end
			end   
		end
	end
end
