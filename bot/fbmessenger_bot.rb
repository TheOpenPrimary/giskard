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
		prefix WEBHOOK_PREFIX.to_sym
		format :json
		class << self
			attr_accessor :client
		end

		helpers do
			def authorized # Used for API calls (/command below)
				headers['Secret-Key']==SECRET
			end

			def send_msg_fb(msg)
				uri = URI.parse('https://graph.facebook.com')
				http = Net::HTTP.new(uri.host, uri.port)
				http.use_ssl = true
				request = Net::HTTP::Post.new("/v2.6/me/messages?access_token=#{FBPAGEACCTOKEN}")
				request.add_field('Content-Type', 'application/json')
				request.body = JSON.dump(msg)
				a=http.request(request)
				puts a.inspect
			end
		end

		get '/fbmessenger' do
			if params['hub.verify_token']==SECRET then
				return params['hub.challenge'].to_i
			else
				return "nope"
			end
		end

		post '/fbmessenger' do
			messaging_events=params['entry'][0].messaging
			messaging_events.each do |e|
				sender=e.sender.id
				if !e.message.nil? and !e.message.text.nil? then
					puts "sending msg"
=begin
					msg={
						"recipient"=>{"id"=>sender},
						"message"=> {
							"attachment"=> {
								"type"=> "template",
								"payload"=> {
									"template_type"=> "generic",
									"elements"=> [{
										"title"=> "First card",
										"subtitle"=> "Element #1 of an hscroll",
										"image_url"=> "http://messengerdemo.parseapp.com/img/rift.png",
										"buttons"=> [{
											"type"=> "web_url",
											"url"=> "https://www.messenger.com/",
											"title"=> "Web url"
										}, {
											"type"=> "postback",
											"title"=> "Postback",
											"payload"=> "Payload for first element in a generic bubble",
										}],
									},{
											"title"=> "Second card",
											"subtitle"=> "Element #2 of an hscroll",
											"image_url"=> "http://messengerdemo.parseapp.com/img/gearvr.png",
											"buttons"=> [{
												"type"=> "postback",
												"title"=> "Postback",
												"payload"=> "Payload for second element in a generic bubble",
											}],
										}]
								}
							}
						}
					}
=end
=begin
					msg={
						"recipient"=>{"id"=>sender},
						"message"=>{"text"=>"https://laprimaire.org/candidat/178159928076"}
					}
=end
					msg={
						"recipient"=>{
							"id"=>sender
						},
						"message"=>{
							"attachment"=>{
								"type"=>"template",
								"payload"=>{
									"template_type"=>"button",
									"text"=>"What do you want to do next?",
									"buttons"=>[
										{
											"type"=>"web_url",
											"url"=>"https://petersapparel.parseapp.com",
											"title"=>"Show Website"
										},
										{
											"type"=>"postback",
											"title"=>"Start Chatting",
											"payload"=>"USER_DEFINED_PAYLOAD"
										}
									]
								}
							}
						}
					}
					send_msg_fb(msg)
				elsif !e.postback.nil? then
					puts e.postback.payload
					msg={
						"recipient"=>{"id"=>sender},
						"message"=>{"text"=>"postback received: "+e.postback.payload}
					}
					send_msg_fb(msg)
				end
			end
		end

		post '/command' do
			error!('401 Unauthorized', 401) unless authorized
			begin
				Bot::Db.init()
				update = Telegram::Bot::Types::Update.new(params)
				msg,options=Bot.nav.get(update.message,update.update_id)
				send_msg(update.message.chat.id,msg,options) unless msg.nil?
			rescue Exception=>e
				Bot.log.fatal "#{e.message}\n#{e.backtrace.inspect}"
				error! "Exception raised: #{e.message}", 200 # if you put an error code here, telegram will keep sending you the same msg until you die
			ensure
				Bot::Db.close()
			end
		end
	end
end
