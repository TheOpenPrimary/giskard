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
	class << self
		attr_accessor :nav, :log
	end

	@@emoticons={ # see http://unicode.org/emoji/charts/full-emoji-list.html
		:blush=>"\u{1F60A}",
		:bust=>"\u{1F464}",
		:envelope=>"\u{2709}",
		:busts=>"\u{1F465}",
		:grinning=>"\u{1F600}",
		:frowning=>"\u{2639}",
		:info=>"\u{2139}",
		:halo=>"\u{1F607}",
		:tongue=>"\u{1F60B}",
		:crying_face=>"\u{1F622}",
		:face_sunglasses=>"\u{1F60E}",
		:megaphone=>"\u{1F4E3}",
		:memo=>"\u{1F4DD}",
		:speech_balloon=>"\u{1F4AC}",
		:finger_up=>"\u{261D}",
		:french_flag=>"\u{1F1EB}",
		:finger_right=>"\u{1F449}",
		:finger_up=>"\u{261D}",
		:raising_hand=>"\u{1F64B}",
		:home=>"\u{1F3E0}",
		:thumbs_up=>"\u{1F44D}",
		:thumbs_down=>"\u{1F44E}",
		:search=>"\u{1F50D}",
		:very_disappointed=>"\u{1F629}",
		:disappointed=>"\u{1F61E}",
		:rocket=>"\u{1F680}",
		:little_smile=>"\u{1F642}",
		:smile=>"\u{1F603}",
		:confused=>"\u{1F615}",
		:rolling_eyes=>"\u{1F644}",
		:thinking_face=>"\u{1F914}",
		:head_bandage_face=>"\u{1F915}",
		:bomb=>"\u{1F4A3}",
		:earth=>"\u{1F30D}",
		:house=>"\u{1F3E0}",
		:plus_sign=>"\u{2795}",
		:cross_mark=>"\u{274C}",
		:nb_0=>"\u{0030}",
		:nb_1=>"\u{0031}",
		:nb_2=>"\u{0032}",
		:nb_3=>"\u{0033}",
		:nb_4=>"\u{0034}",
		:nb_5=>"\u{0035}",
		:woman=>"\u{1F469}",
		:man=>"\u{1F468}",
		:inbox=>"\u{1F4E5}",
		:trash=>"\u{1F5D1}",
		:back=>"\u{21A9}",
		:loupe=>"\u{1F50E}",
		:scroll=>"\u{1F4DC}",
		:speaker=>"\u{1F4E2}"
	}
	@@messages={
		:en=>{
			:system=>{
				:default=><<-END,
I do not have any program loaded so far so my powers might be pretty limited... but you can still try me anyway :)
END
				:dont_understand=><<-END,
Oops, sorry %{firstname} I am afraid I did not understand what you told me #{@@emoticons[:crying_face]} Please use the buttons on the keyboard below to communicate with me please. If you don't see any keyboard, please type /start to return to the main menu.
END
				:something_wrong=><<-END,
It looks like a problem occurred #{@@emoticons[:head_bandage_face]} We'll have to start all over again, sorry about that #{@@emoticons[:confused]}
END
			}
		},
		:fr=>{
			:system=>{
				:default=><<-END,
Aucun programme n'est actuellement chargé dans ce bot, ses capacités sont donc très limitées... mais vous pouvez toujours essayer :)
END
				:dont_understand=><<-END,
Aïe, désolé %{firstname} j'ai peur de ne pas avoir compris ce que vous me demandez #{@@emoticons[:crying_face]} Utilisez les boutons du clavier ci-dessous pour communiquer avec moi s'il vous plait. Et si vous ne voyez pas de clavier, tapez "/start" pour revenir au menu principal.
END
				:something_wrong=><<-END,
Apparemment, un petit souci informatique est survenu #{@@emoticons[:head_bandage_face]} il va nous falloir reprendre depuis le début, désolé #{@@emoticons[:confused]}
END
			}
		}
	}
	@@screens={
		:system=>{
			:default=>{
				#:text=>@@messages[:fr][:system][:default],
			},
			:dont_understand=>{
				#:text=>@@messages[:fr][:system][:dont_understand],
				:keep_kbd=>true
			},
			:something_wrong=>{
				#:text=>@@messages[:fr][:system][:something_wrong]
			}
		}
	}

	def self.mergeHash(old_path,new_path)
		return old_path.merge(new_path) do |key,oldval,newval| 
			if oldval.class.to_s=="Hash" then
				self.mergeHash(oldval,newval)
			else
				newval
			end
		end
	end

	def self.mergeMenu(old_path,new_path)
		return old_path.merge(new_path) do |key,oldval,newval| 
			if key==:kbd then
				oldval.push(newval) 
			else
				self.mergeMenu(oldval,newval)
			end
		end
	end

	def self.addMenu(path)
		@@screens=self.mergeMenu(@@screens,path) 
	end

	def self.updateScreens(new_screens)
		@@screens=self.mergeHash(@@screens,new_screens)
	end

	def self.updateMessages(new_messages)
		@@messages=self.mergeHash(@@messages,new_messages)
	end

	def self.updateEmoticons(new_emoticons)
		@@emoticons=self.mergeHash(@@emoticons,new_emoticons)
	end

	def self.screens
		@@screens
	end

	def self.messages
		@@messages
	end

	def self.emoticons
		@@emoticons
	end

	def self.getMessage(msg_id,locale='en')
		ctx,name=msg_id.split('/')
		return @@messages[locale.to_sym][ctx.to_sym][name.to_sym]
	end
end
