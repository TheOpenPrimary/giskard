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

module Api
	def self.included(base)
		Bot.log.info "loading Api add-on"
		messages={
			:en=>{
				:api=>{
					:access_granted=><<-END,
Good news %{firstname}, you can now access Giskard... here we go again ! #{Bot.emoticons[:face_sunglasses]}
END
					:allow_user=><<-END,
Good news %{firstname}, your access to Giskard has been reinitialized... you can talk to me again ! #{Bot.emoticons[:face_sunglasses]}
END
					:unblock_user=><<-END,
Good news %{firstname}, your access to Giskard has been re-activated... you can talk to me again ! #{Bot.emoticons[:face_sunglasses]}
END
					:ban_user=><<-END,
%{firstname}, your behavior is violating our code of conduct. This is why your account has been suspended #{Bot.emoticons[:crying_face]}
END
					:reset_user=><<-END,
%{firstname}, your account has been reinitialized. Type /start to continue.
END
					:broadcast=><<-END,
Sorry for interrupting but I just received the following message that I've been asked to forward to you :
"%{broadcast_msg}"
Click on the "#{Bot.emoticons[:back]} Back" button as soon as you want to get back where you were.
END
					:back=>"#{Bot.emoticons[:back]} Back"
				}
			},
			:fr=>{
				:api=>{
					:access_granted=><<-END,
Bonne nouvelle %{firstname}, vous avez désormais accès à LaPrimaire.org... c'est reparti ! #{Bot.emoticons[:face_sunglasses]}
END
					:allow_user=><<-END,
Bonne nouvelle %{firstname}, votre accès à LaPrimaire.org a été réinitialisé... c'est reparti ! #{Bot.emoticons[:face_sunglasses]}
END
					:unblock_user=><<-END,
Bonne nouvelle %{firstname}, votre accès à LaPrimaire.org a été rétabli... c'est reparti ! #{Bot.emoticons[:face_sunglasses]}
END
					:ban_user=><<-END,
%{firstname}, votre comportement sur LaPrimaire.org est en violation de la Charte que vous avez acceptée. En conséquence, je suis donc dans l'obligation de suspendre votre compte #{Bot.emoticons[:crying_face]}
END
					:reset_user=><<-END,
%{firstname}, votre compte vient d'être remis à zéro. Tapez /start pour continuer.
END
					:broadcast=><<-END,
Excusez-moi pour cette interruption mais je viens de recevoir le message suivant de la part de LaPrimaire.org qu'on m'a chargé de vous transmettre :
"%{broadcast_msg}"
Cliquez sur le bouton "#{Bot.emoticons[:back]} Retour" dès que vous souhaitez reprendre où vous en étiez.
END
					:back=>"#{Bot.emoticons[:back]} Retour"
				}
			}
		}
		screens={
			:api=>{
				:access_granted=>{
					:disable_web_page_preview=>true,
					:jump_to=>"welcome/start"
				},
				:allow_user=>{
					:disable_web_page_preview=>true,
					:jump_to=>"home/welcome"
				},
				:ban_user=>{
					:disable_web_page_preview=>true,
					:jump_to=>"home/welcome"
				},
				:reset_user=>{
					:disable_web_page_preview=>true,
					:jump_to=>"home/welcome"
				},
				:unblock_user=>{
					:disable_web_page_preview=>true,
					:jump_to=>"home/welcome"
				},
				:broadcast=>{
					:save_session=>true,
					:disable_web_page_preview=>true,
					:kbd=>[{"text"=>"api/back"}],
					:kbd_options=>{:resize_keyboard=>true,:one_time_keyboard=>false,:selective=>true},
					:callback=>"api/broadcast"
				},
				:back=>{
					:answer=>"api/back",
					:callback=>"api/broadcast"
				}
			}
		}
		Bot.updateScreens(screens)
		Bot.updateMessages(messages)
	end

	def api_access_granted(msg,user,screen)
		Bot.log.info "#{__method__}"
		#@users.remove_from_waiting_list(user)
		user.next_answer('answer')
		Bot.log.event(user.id,'api_grant_beta_access')
		return self.get_screen(screen,user,msg)
	end

	def api_allow_user(msg,user,screen)
		Bot.log.info "#{__method__}"
		user.settings['blocked']['not_allowed'] = false
		user.next_answer('answer')
		Bot.log.event(user.id,'api_reallow_user')
		return self.get_screen(screen,user,msg)
	end

	def api_ban_user(msg,user,screen)
		Bot.log.info "#{__method__}"
		user.settings['blocked']['abuse'] = true
		user.next_answer('answer')
		Bot.log.event(user.id,'api_ban_user')
		return self.get_screen(screen,user,msg)
	end

	def api_reset_user(msg,user,screen)
		Bot.log.info "#{__method__}"
		user.reset(user)
		user.next_answer('answer')
		Bot.log.event(user.id,'api_reset_user')
		return self.get_screen(screen,user,msg)
	end

	def api_unblock_user(msg,user,screen)
		Bot.log.info "#{__method__}"
		user.settings['blocked']['abuse'] = false
		user.next_answer('answer')
		Bot.log.event(user.id,'api_unblock_user')
		return self.get_screen(screen,user,msg)
	end

	def api_broadcast(msg,user,screen)
		Bot.log.info "#{__method__}"
		if screen[:save_session] then
			current         = user.state['current'].nil? ? "home/welcome" : user.state['current']
			broadcast_msg   = user.state['api_payload']
			previous_screen = self.find_by_name(current)
			user.next_answer('answer')
			user.reset('api_payload')
			screen[:text]=screen[:text] % {broadcast_msg: broadcast_msg}
		else
			screen=user.previous_state()
			screen=self.find_by_name("home/welcome") if screen.nil?
			if !screen[:text].nil? and !screen[:text].empty? then
				screen[:text]="Merci pour votre attention ! Reprenons...\n"+screen[:text]
			else
				screen[:text]="Merci pour votre attention ! Reprenons..."
			end
		end
		return self.get_screen(screen,user,msg)
	end
end

include Api
