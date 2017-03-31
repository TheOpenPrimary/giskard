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

module Home
	def self.included(base)
		Bot.log.info "loading Home add-on"
		messages={
			:en=>{
				:home=>{
					:welcome_answer=>"/start",
					:welcome=><<-END,
Hello %{firstname} !
My name is Giskard, I am an intelligent bot.. or at least as intelligent as you make me #{Bot.emoticons[:smile]}
This is an example program for you to get acustomed to how I work.
But enough talking, let's begin !
END
					:menu_answer=>"#{Bot.emoticons[:home]} Home",
					:menu=><<-END,
What do you want to do ? Please use below buttons to tell me what you would like to do.
END
					:ask_email_answer=>"My email",
					:ask_email=><<-END,
What is your email ?
END
					:email_saved=><<-END,
Your email is %{email} !
END
					:email_wrong=><<-END,
Hmmm... %{email} doesn't look like a valid email #{Bot.emoticons[:confused]}
END
					:my_action_2_answer=>"Action 2",
					:my_action_2=><<-END,
Texte for action 2
END
				}
			},
			:fr=>{
				:home=>{
					:welcome_answer=>"/start",
					:welcome=><<-END,
Bonjour %{firstname} !
Je suis Victoire, votre guide pour LaPrimaire #{Bot.emoticons[:blush]}
Mon rôle est de vous accompagner et de vous informer tout au long du déroulement de La Primaire.
Mais assez discuté, commençons !
END
					:menu_answer=>"#{Bot.emoticons[:home]} Accueil",
					:menu=><<-END,
Que voulez-vous faire ? Utilisez les boutons du menu ci-dessous pour m'indiquer ce que vous souhaitez faire.
END
					:ask_email_answer=>"Mon email",
					:ask_email=><<-END,
Quel est votre email ?
END
					:email_saved=><<-END,
Votre email est %{email} !
END
					:email_wrong=><<-END,
Hmmm... %{email} n'est pas un email valide #{Bot.emoticons[:confused]}
END
					:my_action_2_answer=>"Action 2",
					:my_action_2=><<-END,
Texte pour l'action 2
END
				}
			}
		}
		screens={
			:home=>{
				:welcome=>{
					:answer=>"home/welcome_answer",
					:disable_web_page_preview=>true,
					:callback=>"home/welcome",
					:jump_to=>"home/menu"
				},
				:menu=>{
					:answer=>"home/menu_answer",
					:callback=>"home/menu",
					:parse_mode=>"HTML",
					:kbd=>[{"text"=>"home/ask_email"},{"text"=>"home/my_action_2"}],
					:kbd_options=>{:resize_keyboard=>true,:one_time_keyboard=>false,:selective=>true}
				},
				:ask_email=>{
					:answer=>"home/ask_email_answer",
					:callback=>"home/ask_email",
				},
				:email_saved=>{
					:jump_to=>"home/menu"
				},
				:email_wrong=>{
					:jump_to=>"home/menu"
				},
				:my_action_2=>{
					:answer=>"home/my_action_2_answer",
					:jump_to=>"home/menu"
				}
			}
		}
		Bot.updateScreens(screens)
		Bot.updateMessages(messages)
		Bot.addMenu({:home=>{:menu=>{:kbd=>{"text"=>"home/menu"}}}})
	end

	def home_welcome(msg,user,screen)
		Bot.log.info "#{__method__}"
		screen=self.find_by_name("home/menu",self.get_locale(user))
		return self.get_screen(screen,user,msg)
	end

	def home_menu(msg,user,screen)
		Bot.log.info "#{__method__}"
		screen[:kbd_del]=["home/menu"] #comment if you want the home button to be displayed on the home menu
		user.next_answer('answer')
		return self.get_screen(screen,user,msg)
	end

	def home_ask_email(msg,user,screen)
		Bot.log.info "#{__method__}"
		user.next_answer('free_text',1,"home/save_email_cb")
		return self.get_screen(screen,user,msg)
	end

	def home_save_email_cb(msg,user,screen)
		email=user.state['buffer']
		Bot.log.info "#{__method__}: #{email}"
		if email.match(/\A[^@\s]+@([^@\s]+\.)+[^@\s]+\z/).nil? then
			screen=self.find_by_name("home/email_wrong",self.get_locale(user))
			screen[:text]=screen[:text] % {:email=>email}
			return self.get_screen(screen,user,msg)
		end
		screen=self.find_by_name("home/email_saved",self.get_locale(user))
		screen[:text]=screen[:text] % {:email=>email}
		return self.get_screen(screen,user,msg)
	end
end

include Home
