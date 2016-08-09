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
			if file_url.nil? then
				RestClient.post "https://graph.facebook.com/v2.6/me/#{type}?access_token=#{FB_PAGEACCTOKEN}", payload.to_json, :content_type => :json
			else # image upload # FIXME file upload does not work : 400 Bad Request
				params={"recipient"=>payload['recipient'], "message"=>payload['message'], "filedata"=>File.new(file_url,'rb'),"multipart"=>true}
				RestClient.post "https://graph.facebook.com/v2.6/me/#{type}?access_token=#{FB_PAGEACCTOKEN}",params
			end
		end

		def self.init() 
			payload={ "setting_type"=>"greeting", "greeting"=>{ "text"=>"Hello, ca fiouze ?" }}
			Giskard::FBMessengerBot.send(payload,"thread_settings")
		end

		helpers do
			def authorized # Used for API calls and to verify webhook
				headers['Secret-Key']==FB_SECRET
			end

			def send_msg(id,text,kbd=nil)
				msg={"recipient"=>{"id"=>id},"message"=>{"text"=>text}}
				if not kbd.nil? then
					msg["message"]["quick_replies"]=[]
					kbd.each do |k|
						msg["message"]["quick_replies"].push({
							"content_type"=>"text",
							"title"=>k,
							"payload"=>k
						})
					end
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
						end
						send_msg(id,l,kbd)
					end
				end
			end
		end

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
          id_sender = messaging.sender.id
          id_receiv = messaging.recipient.id
          id        = messaging.message.mid unless messaging.message.nil?
          text      = messaging.message.text unless messaging.message.nil? 
          timestamp = messaging.time
          msg     = Giskard::Message.new(id_sender, id, text, timestamp)
          if not text.nil? then
            
        end
      end
                         
			messaging_events.each do |update|
				sender=update.sender.id
				if !update.message.nil? and !update.message.text.nil? then
					Bot.log.info update.message.text
					object=JSON.parse({"from"=>update.sender.id,"text"=>update.message.text}.to_json, object_class: OpenStruct)
					user,screen=Bot.nav.get(object,update.message.seq,FB_BOT_NAME)
					process_msg(user[:id],screen[:text],screen) unless screen[:text].nil?
				elsif !update.postback.nil? then
					Bot.log.info update.postback.payload
					object=JSON.parse({"from"=>update.sender.id,"text"=>update.postback.payload}.to_json, object_class: OpenStruct)
					user,screen=Bot.nav.get(object,update.message.seq,FB_BOT_NAME)
					process_msg(user[:id],screen[:text],screen) unless screen[:text].nil?
				end
			end
		end
	end
end

