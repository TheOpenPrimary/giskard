# Giskard Bot Engine

Giskard is a bot engine to create advanced bots for modern messenging apps. It natively supports Telegram messenger bots. Facebook messenger bot support is around the corner. Giskard is written in ruby (not rails) using [telegram-bot-ruby](https://github.com/atipugin/telegram-bot-ruby) and the [Grape API framework](https://github.com/ruby-grape/grape).

## About Giskard

Giskard has been created to leverage [Telegram Bot API](https://core.telegram.org/bots/api) and, in particular, the possibility to interact with the user through custom keyboard actions. Giskard is a bot engine that enables you to easily create complex and customized user experience. To this date, Giskard does not implement any sort of AI (otherwise Giskard would have been named [R. Daneel Olivaw](https://en.wikipedia.org/wiki/R._Daneel_Olivaw)) although it could be "easily" added. Giskard enables you to easily implement flexible [Finite-state machine](https://en.wikipedia.org/wiki/Finite-state_machine) for your bot.

Giskard has been developed to provide [LaPrimaire.org](https://laprimaire.org) with a [telegram bot](https://www.youtube.com/watch?v=AUoArIkCECo) to enable french citizens to crowdsource their election candidates for the 2017 french presidential elections.

## How Giskard works

Giskard's logic is implemented via *Add-ons*. When the bot is launched, it loads all its available add-ons. Each add-on provide Giskard with a specific feature set. An add-on is a combination of 3 different entities :

- *screens* define the user-experience and the workflow of an add-on.
- *callbacks* define the business logic of an add-on.
- *messages*  define the localized message strings of an add-on.

### screens

Giskard uses screens to determine what to display to the user at a given state. For a given module (add-on), screens are defined as a ruby hash. Here is an example with the screens of the Home add-on:
```
screens={
	:home=>{
		:welcome=>{
			:answer=>"/start",
			:text=>messages[:fr][:home][:welcome],
			:disable_web_page_preview=>true,
			:callback=>"home/welcome",
			:jump_to=>"home/menu"
		},
		:menu=>{
			:answer=>"#{Bot.emoticons[:home]} Accueil",
			:text=>messages[:fr][:home][:menu],
			:callback=>"home/menu",
			:parse_mode=>"HTML",
			:kbd=>["home/my_action_1","home/my_action_2"],
			:kbd_options=>{:resize_keyboard=>true,:one_time_keyboard=>false,:selective=>true}
		},
		:my_action_1=>{
			:answer=>"Action 1",
			:text=>messages[:fr][:home][:action_1],
			:jump_to=>"home/menu"
		},
		:my_action_2=>{
			:answer=>"Action 2",
			:text=>messages[:fr][:home][:action_2],
			:jump_to=>"home/menu"
		},
		:abuse=>{
			:text=>messages[:fr][:home][:abuse],
			:disable_web_page_preview=>true
		},
	}
}
```
The Home add-on defines 3 screens : *welcome*, *menu* and *abuse*, located in the namespace *home* (the namespace is called ```context``` in the code). A screen can have the following attributes :

- *text* defines the message that will be sent to the user. See the *messages* section below for more information about messages and their formatting options. 
- *answer* (optional) defines the text string (exact match) that the user should input to trigger the display of this screen. It is an exact match because, most of the time, the input will not be produced as 'free-text' input from the user but by the push of a pre-defined keyboard button. The *answer* value should be unique within an add-on (i.e. within a given namespace). If another add-on has a screen with the exact same *answer*, Giskard disambiguates by :
    * looking whether the current namespace matches the namespace of one of the conflicting screens, in this case, the screen from the current namespace is being displayed.
    * if the current namespace does not match any of the conflicting screens' namespaces, then the 1st *answer* found is being displayed. 
- *callback* (optional) references the callback that should be executed when this screen is called for display. In the example above, the *menu* screen will call the *home/menu* callback which is to be defined within the home add-on in the method ```home_menu```. Please refer to the *callbacks* section below for more information.
- *kbd* (optional) defines the buttons of the keyboard that should be displayed to the user once this screen has been displayed. The keyboard contains the follow-up screens (and actions) that the user can go to from this screen. The *kbd* attribute is an array containing as elements the identifiers of the screens the user can go to in the form ```<namespace>/<screen_name>```. Each valid screen identifier will be displayed as a button on the user keyboard. The text of the displayed button is equal to the *answer* attribute of the targeted screen. When Giskards is being started, it makes sure that every *kbd* attributes contain screen identifiers that actually exists (otherwise Giskard will throw an error an refuse to start).
- *kbd_options* (optional) maps the control options offered by the telegram API to control the keyboard behavior. See the [telegram bot api](https://core.telegram.org/bots/api#replykeyboardmarkup) for more information.
- *kbd_del* (optional) tells Giskard to remove a specific button (identified by its screen identifier) from the keyboard. It is mostly used to transform the keyboard **within callbacks**. Using *kbd_del* in a screen definition does not make much sense as you can specify the *kbd* you want.
- *jump_to* (optional) tells Giskard which screen to display right after the current screen has been displayed.
- *parse_mode* (optional) tells Giskard how to parse the message of the screen. By default, Giskard parses the screen's message as text. Telegram offering the ability to use basic html formatting in messages, you can tell Giskard to parse the message in "HTML" in case you used such formatting in your screen's message.
- *disable_web_page_preview* (optional) tells Giskard to **not** render a link preview of the urls included in the screen's message. By default, Telegram displays an url preview of the 1st url included in your screen's message.

### callbacks


### messages



