# Giskard Bot Engine

Giskard is a bot engine to create advanced bots for modern messenging apps. It natively supports Telegram messenger bots. Facebook messenger bot support is around the corner. Giskard is written in ruby (not rails) using [telegram-bot-ruby](https://github.com/atipugin/telegram-bot-ruby) and the [Grape API framework](https://github.com/ruby-grape/grape).


# Table of content

- [What is Giskard?](https://github.com/telegraph-ai/giskard#what-is-giskard)
- [how Giskard works](https://github.com/telegraph-ai/giskard#how-giskard-works)
   - [screens](https://github.com/telegraph-ai/giskard#screens)
   - [callbacks](https://github.com/telegraph-ai/giskard#callbacks)
   - [messages](https://github.com/telegraph-ai/giskard#messages)
   - [the user object](https://github.com/telegraph-ai/giskard#the-user-object)
- [Giskard setup](https://github.com/telegraph-ai/giskard#giskard-setup)
   - [Pre-requirements](https://github.com/telegraph-ai/giskard#pre-requirements)
   - [Installing Giskard](https://github.com/telegraph-ai/giskard#installing-giskard)
   - [Running Giskard](https://github.com/telegraph-ai/giskard#running-giskard)


## What is Giskard?

Giskard enables you to easily create complex Telegram bots (Facebook messenger bots support coming soon). Giskard has been created to leverage [Telegram Bot API](https://core.telegram.org/bots/api) and, in particular, the possibility to interact with the user through custom keyboard actions. Giskard is a bot engine that enables you to easily create complex and customized user experience. To this date, Giskard does not implement any sort of AI (otherwise Giskard would have been named [R. Daneel Olivaw](https://en.wikipedia.org/wiki/R._Daneel_Olivaw)) although it could be "easily" added. Giskard enables you to easily implement flexible [Finite-state machine](https://en.wikipedia.org/wiki/Finite-state_machine) for your bot.

Giskard has been developed to provide [LaPrimaire.org](https://laprimaire.org) with a [telegram bot](https://www.youtube.com/watch?v=AUoArIkCECo) to enable french citizens to crowdsource their election candidates for the 2017 french presidential elections.

## How Giskard works

Giskard's logic is implemented via *Add-ons*. When Giskard is launched, it loads all its available add-ons. Each add-on provide Giskard with a specific feature set. An add-on is a combination of 3 different entities :

- *screens* define the user-experience and the workflow of an add-on.
- *callbacks* define the business logic of an add-on.
- *messages*  define the localized message strings of an add-on.

### screens

Giskard uses screens to determine what to display to the user at a given state. For a given module (add-on), screens are defined as a ruby hash. Here is an example with the screens of the Home add-on:
```
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
			:kbd=>["home/ask_email","home/my_action_2"],
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
```
The Home add-on defines 6 screens : *welcome*, *menu*, *ask_email*, *email_saved*, *email_wrong* and *my_action_2*, located in the namespace *home* (the namespace is called ```context``` in the code). A screen can have the following optional attributes :

- **answer** (optional) is a message id of the form ```<namespace>/<screen_name>_answer``` that defines the text string (exact match) that the user should input to trigger the display of this screen. The message_id is rendered into the exact localized string at runtime so you need to make sure to have set a value for the message id in your add-on messages (see *messages* section below). Giskard expects an exact match with the user input because, most of the time, the input will not be produced as 'free-text' input from the user but by the push of a pre-defined keyboard button. The *answer* value should be unique within an add-on (i.e. within a given namespace). If another add-on has a screen with the exact same *answer*, Giskard disambiguates by :
    * looking whether the current namespace matches the namespace of one of the conflicting screens, in this case, the screen from the current namespace is being displayed.
    * if the current namespace does not match any of the conflicting screens' namespaces, then the 1st *answer* found is being displayed. 
- **callback** (optional) references the callback that should be executed when this screen is called for display. In the example above, the *menu* screen will call the *home/menu* callback which is to be defined within the home add-on in the method ```home_menu```. Please refer to the *callbacks* section below for more information.
- **kbd** (optional) defines the buttons of the keyboard that should be displayed to the user once this screen has been displayed. The keyboard contains the follow-up screens (and actions) that the user can go to from this screen. The *kbd* attribute is an array containing as elements the identifiers of the screens the user can go to in the form ```<namespace>/<screen_name>```. Each valid screen identifier will be displayed as a button on the user keyboard. The text of the displayed button is equal to the *answer* attribute of the targeted screen. When Giskards is being started, it makes sure that every *kbd* attributes contain screen identifiers that actually exists (otherwise Giskard will throw an error an refuse to start).
- **kbd_options** (optional) maps the control options offered by the telegram API to control the keyboard behavior. See the [telegram bot api](https://core.telegram.org/bots/api#replykeyboardmarkup) for more information.
- **kbd_del** (optional) tells Giskard to remove a specific button (identified by its screen identifier) from the keyboard. It is mostly used to transform the keyboard **within callbacks**. Using *kbd_del* in a screen definition does not make much sense as you can specify the *kbd* you want.
- **jump_to** (optional) tells Giskard which screen to display right after the current screen has been displayed.
- **parse_mode** (optional) tells Giskard how to parse the message of the screen. By default, Giskard parses the screen's message as text. Telegram offering the ability to use basic html formatting in messages, you can tell Giskard to parse the message in "HTML" in case you used such formatting in your screen's message.
- **disable_web_page_preview** (optional) tells Giskard to **not** render a link preview of the urls included in the screen's message. By default, Telegram displays an url preview of the 1st url included in your screen's message.

Each screen displays a message to the user. For a given screen, Giskard displays the message ```<namespace>/<screen_name>``` in the current locale. See the *messages* section below for more information about messages and their formatting options. 

### callbacks

A screen can have a callback as an attribute. Callbacks are method where the business logic is being executed.
Example for the above code example :
```
:ask_email=>{
	:answer=>"home/ask_email_answer",
	:callback=>"home/ask_email",
},
```

For this to work, you need to define the method ```home_ask_email``` in the add-on. Here is the code of the callback :
```
def home_ask_email(msg,user,screen)
	Bot.log.info "#{__method__}"
	@users.next_answer(user[:id],'free_text',1,"home/save_email_cb")
	return self.get_screen(screen,user,msg)
end

def home_save_email_cb(msg,user,screen)
	email=user['session']['buffer']
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
```

In the above example, ```home_ask_email()``` is being called whenever the screen ```home/ask_email``` is being displayed. The only thing done by the callback is to tell Giskard, through the ```self.next_answer()``` method, that he should expect 1 "free text" entry from the user as the next input and that he should pass this input to the ```home/save_email_cb``` callback.

The ```home/save_email_cb``` callback is defined in the above code snippet :
* It reads the email entered by the user from the session buffer. "free text" input are always stored in the ```user['session']['buffer']``` variable.
* It checks the validity of the email entered.
* If the email is not valid, it renders the ```home/email_wrong``` screen
* If the email is valid, it renders the ```home/email_saved``` screen

Note that the message of both ```home/email_wrong``` and ```home/email_saved``` contain a variable ```email``` that needs to be renderd before returning.

#### input

Every callback gets 3 arguments as an input :

* **msg** the message received from Telegram (see [available-types](https://core.telegram.org/bots/api#available-types))
* **user** the user object representing the current user (see [bot/user.rb](https://github.com/telegraph-ai/giskard/blob/master/bot/users.rb))
* **screen** the current screen (a ruby hash like the ones defined above) to be displayed.

#### output

A callback *must* return the output of the ```get_screen(msg,user,screen)``` method.

### messages




### the user object

The user object is defined in [bot/user.rb](https://github.com/telegraph-ai/giskard/blob/master/bot/users.rb). You can extend it as you wish but it should at least have the following structure:
```
{
	'firstname'=>user.first_name,
	'lastname'=>user.last_name,
	'username'=>user.username,
	'session'=>bot_session,
	'settings'=>user_settings
}
```
With ```bot_session``` a ruby hash that defines the current user session :
```
bot_session={
	'last_update_id'=>nil,
	'current'=>nil,
	'expected_input'=>"answer",
	'expected_input_size'=>-1,
	'buffer'=>""
}
```

And ```user_settings``` a ruby hash that stores the current user settings :
```
user_settings={
	'locale'=>'fr', #mandatory
	'blocked'=>{ 'abuse'=>false }, # optional
	'actions'=>{ 'first_help_given'=>false }, # optional
}
```

## Giskard Setup

For maximum performance, Giskard does not use the polling mode for the Telegram bot but instead uses the [webhook method](https://core.telegram.org/bots/api#setwebhook). By default, Giskard uses the [unicorn web server](http://unicorn.bogomips.org/) to serve requests. Please be aware that unicorn uses system processes which means that if you are spawning your Giskard bot on more than 1 processes, memory between these processes **is not shared** so you will need to use a database or some shared memory techniques if you want to share data between your processes.

### Pre-requirements

* **Create your bot**. Prior to use Giskard, you need to create your Telegram Bot by following [these instructions](https://core.telegram.org/bots#3-how-do-i-create-a-bot) provided by Telegram.
* **Create your keys.local.rb**. Copy ```config/keys.rb``` into ```config/keys.local.rb``` and fill-in the 3 constants :
    - **TGTOKEN** Your bot token as provided by Telegram's BotFather (it looks like: "907662123:HJLyuyHF86xcvw_KJoO5jhgsRKK92adByDC")
    - **WEBHOOK_PREFIX** A random string to hide your webhook endpoint (example: "FDFdfdfEGFDGedqqeq")
    - **SECRET** A secret (random) string for to authenticate custom Giskard API calls. This is not required for Giskard to work.
* **Setup your webhook development environment**. Developing with webhooks can be tricky because it requires Telegram to be able to send queries to your Giskard instance. If, like 99% developers, you develop on your local PC, Telegram will not be able to send you requests. You should consider using [ngrok](https://ngrok.com/), a true life-saving tool, to easily create secure tunnels to your localhost, thus allowing Telegram to contact your localhost. You should consider purchasing a licence because it is cheap yet super powerful but, for testing purposes, the free version will do : ```ngrok http 8080```
* **Declare your webhook endpoint to your Telegram bot**. You can use ```curl``` to do it in a straightforward manner :
```
curl -s -X POST https://api.telegram.org/bot<TGTOKEN>/setWebhook?url=<yoursubdomain>.ngrok.io/<WEBHOOK_PREFIX>
```

### Installing Giskard

Installing Giskard is pretty straightforward. On Ubuntu 14.04, you only need to have Ruby 2.0 installed on your system. Beware, even though Ruby 2.0 is technically available on Ubuntu 14.04, for some obscure reason, Debian (and Ubuntu) don't make it the default ruby interpreter after installation. You can follow [these instructions](http://blog.costan.us/2014/04/restoring-ruby-20-on-ubuntu-1404.html) to make it so. Once Ruby 2 is installed on your system, installing Giskard is easy :
```
$ git clone git@github.com:telegraph-ai/giskard.git giskard
$ cd giskard
$ sudo bundle install
```

### Running Giskard

Giskard is a rake application. To run Giskard on your machine, you can use :
```
$ bundle exec unicorn -c config/unicorn.conf
```
To run Giskard in production, you can use :
```
$ bundle exec unicorn -E production -c config/unicorn.conf
```
```
