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

		def self.send(payload,type="messages")
			uri = URI.parse('https://graph.facebook.com')
			http = Net::HTTP.new(uri.host, uri.port)
			http.use_ssl = true
			request = Net::HTTP::Post.new("/v2.6/me/#{type}?access_token=#{FBPAGEACCTOKEN}")
			request.add_field('Content-Type', 'application/json')
			request.body = JSON.dump(payload)
			a=http.request(request)
		end

		def self.init() # BUG : ca ne semble pas fonctionner
			payload={
				"setting_type"=>"greeting",
				"greeting"=>{ "text"=>"Hello, ca fiouze ?" }
			}
			Giskard::FBMessengerBot.send(payload,"thread_settings")
		end

		helpers do
			def authorized # Used for API calls and to verify webhook
				headers['Secret-Key']==SECRET
			end

			def format_answer(user,screen)
				options={}
				msg={
					"recipient"=>{"id"=>user[:id].to_i},
					"message"=>{"text"=>screen[:text]}
				}
				return msg,options
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
			messaging_events.each do |update|
				sender=update.sender.id
				if !update.message.nil? and !update.message.text.nil? then
					Bot.log.info "sending msg"
					object=JSON.parse({"from"=>update.sender.id,"text"=>update.message.text}.to_json, object_class: OpenStruct)
					user,screen=Bot.nav.get(object,update.message.seq)
					msg,options=format_answer(user,screen)
					Giskard::FBMessengerBot.send(msg) unless msg.nil?
				elsif !update.postback.nil? then
					Bot.log.info update.postback.payload
					user,screen=Bot.nav.get(update.postback.payload,update.message.seq)
					msg,options=format_answer(user,screen)
					Giskard::FBMessengerBot.send(msg) unless msg.nil?
				end
			end
		end
	end
end

### MESSAGES EXAMPLES ###

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
					msg={
						"recipient"=>{"id"=>sender},
						"message"=>{"text"=>"https://laprimaire.org/candidat/178159928076"}
					}
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
=end
