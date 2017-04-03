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

module Help
	def self.included(base)
		Bot.log.info "loading Help add-on"
		messages={
			:en=>{
				:help=>{
					:first_help_ok_answer=>"Ok understood #{Bot.emoticons[:thumbs_up]}",
					:first_help_ok=><<-END,
Great, let's get back to it !
END
					:first_help=><<-END,
Sorry I did not understand what you told me #{Bot.emoticons[:crying_face]}
Please use the keyboard to communicate with me
image:https://s3.eu-central-1.amazonaws.com/laprimaire/images/keyboard-button.png
Click on the "Ok understood" button of the keyboard below to continue.
END
				}
			},
			:fr=>{
				:help=>{
					:first_help_ok_answer=>"Ok bien compris #{Bot.emoticons[:thumbs_up]}",
					:first_help_ok=><<-END,
Parfait, reprenons !
END
					:first_help=><<-END,
Désolé, je ne comprends pas ce que vous m'écrivez #{Bot.emoticons[:crying_face]}
Merci d'utiliser le clavier pour communiquer avec moi
image:https://s3.eu-central-1.amazonaws.com/laprimaire/images/keyboard-button.png
Cliquez sur le bouton "Ok bien compris" du clavier ci-dessous pour continuer.
END
				}
			}
		}
		screens={
			:help=>{
				:first_help_ok=>{
					:answer=>"help/first_help_ok_answer",
					:callback=>"help/first_help_cb",
				},
				:first_help=>{
					:callback=>"help/first_help_cb",
					:save_session=>true,
					:kbd=>[{"text"=>"help/first_help_ok"}],
					:kbd_options=>{:resize_keyboard=>true,:one_time_keyboard=>false,:selective=>true},
					:disable_web_page_preview=>true
				}
			}
		}
		Bot.updateScreens(screens)
		Bot.updateMessages(messages)
	end

	def help_first_help_cb(msg,user,screen)
		Bot.log.info "help_first_help_cb"
		locale=self.get_locale(user)
		if screen[:save_session] then
			user.next_answer('answer')
		else
			screen=self.find_by_name("home/welcome",locale) if screen.nil?
			if !screen[:text].nil? then
				screen[:text] = Bot.getMessage("help/first_help_ok",locale)+"\n"+screen[:text]
			else
				screen[:text]=Bot.getMessage("help/first_help_ok",locale)
			end
			user.settings['actions']['first_help_given'] = true
		end
		return self.get_screen(screen,user,msg)
	end
end

include Help
