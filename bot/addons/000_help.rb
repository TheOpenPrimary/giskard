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
			:fr=>{
				:help=>{
					:first_help_ok=><<-END,
Parfait, reprenons !
END
					:first_help=><<-END,
Désolé, je ne comprends pas ce que vous m'écrivez #{Bot.emoticons[:crying_face]}
Pour communiquer avec moi, il est plus simple d'utiliser les boutons qui s'affichent sur le clavier (en bas de l'écran) lorsque celui-ci apparaît.
De temps en temps, je vous demanderai d'écrire mais, le plus souvent, le clavier suffit #{Bot.emoticons[:smile]}
Si, par une fausse manipulation, vous faîtes disparaître les boutons du clavier, vous pouvez toujours le réafficher en cliquant sur l'icône suivante :
image:static/images/keyboard-button.png
Cliquez-sur le bouton "OK bien compris !" du clavier ci-dessous pour continuer.
END
				}
			}
		}
		screens={
			:help=>{
				:first_help_ok=>{
					:answer=>"Ok bien compris #{Bot.emoticons[:thumbs_up]}",
					:text=>messages[:fr][:help][:first_help_ok],
					:callback=>"help/first_help_cb",
				},
				:first_help=>{
					:text=>messages[:fr][:help][:first_help],
					:callback=>"help/first_help_cb",
					:save_session=>true,
					:kbd=>["help/first_help_ok"],
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
		if screen[:save_session] then
			@users.next_answer(user[:id],'answer')
		else
			screen=@users.previous_state(user[:id])
			screen=self.find_by_name("home/welcome") if screen.nil?
			if !screen[:text].nil? then
				screen[:text]="Parfait, reprenons !\n"+screen[:text]
			else
				screen[:text]="Parfait, reprenons !"
			end
			@users.update_settings(user[:id],{'actions'=>{'first_help_given'=> true}})
		end
		return self.get_screen(screen,user,msg)
	end
end

include Help
