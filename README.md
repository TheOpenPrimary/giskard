[![Telegram Chat](https://img.shields.io/badge/telegram-chat-blue.svg)](https://telegram.me/joinchat/BVqq1gjMxoWJJv9oEC_7YQ) ![license](https://img.shields.io/badge/license-Apache%202.0-green.svg)

# Giskard Bot Engine 

![Giskard logo](https://s3.eu-central-1.amazonaws.com/laprimaire/giskard_logo_400x285.jpg "Giskard")

Giskard is a lightweight bot engine to create advanced bots for modern messenging apps, especially keyboard-based bots (see [Why Giskard?](https://github.com/telegraph-ai/giskard#why-giskard)). It natively supports Telegram messenger and FB messenger bots (actually you can even run a Telegram bot and an FB messenger bot in parallel with the same shared business logic). Slack bots support are not yet supported but Giskard has been architected to allow the support of other platforms easily. Giskard is written in ruby (not rails) using the [telegram-bot-ruby](https://github.com/atipugin/telegram-bot-ruby) framework and the [Grape API framework](https://github.com/ruby-grape/grape), it is made to be used in *webhook* mode (vs polling) and serves request through the unicorn web server by default.

# Table of content

- [What is Giskard?](#what-is-giskard)
- [Why Giskard?](#why-giskard)
- [How Giskard works](#how-giskard-works)
   - [Screens](#screens)
   - [Callbacks](#callbacks)
   - [Messages](#messages)
   - [User object](#user-object)
- [Giskard setup](#giskard-setup)
   - [Pre-requirements](#pre-requirements)
   - [Installing Giskard](#installing-giskard)
   - [Running Giskard](#running-giskard)
   - [Performance notes](#performance-notes)
- [Compatibility notes](#compatibility-notes)
   - [Telegram support](#telegram-support)
   - [FBMessenger support](#fbmessenger-support)

## What is Giskard?

Giskard enables you to easily create complex Telegram bots (Facebook messenger bots support coming soon). Giskard has been created to leverage [Telegram Bot API](https://core.telegram.org/bots/api) and, in particular, the possibility to interact with the user through custom keyboard actions. Giskard is a bot engine that enables you to easily create complex and customized user experience. Giskard does not implement AI support natively (otherwise Giskard would have been named [R. Daneel Olivaw](https://en.wikipedia.org/wiki/R._Daneel_Olivaw)) but AI support can easily be added into the business logic of your bot by leveraging the [Wit.ai API](https://wit.ai/docs) for example. Giskard enables you to easily implement platform agnostic flexible [Finite-state machine](https://en.wikipedia.org/wiki/Finite-state_machine) for your bot.

Here is a dummy example (actually this is what you'll get if you run this code without modifications) of a telegram bot and a messenger bot run by Giskard. Note that these 2 bots are being served by Giskard within 1 single server instance, by the same process.

Telegram Bot | FB Messenger Bot
------------ | ----------------
![Telegram Bot](https://s3.eu-central-1.amazonaws.com/laprimaire/screenshots/telegram_v1_bot.png) | ![FB Messenger Bot](https://s3.eu-central-1.amazonaws.com/laprimaire/screenshots/fbmessenger_bot.png)


## Why Giskard?

Giskard has been developed for several reasons, among which :

* **Keyboard-based bots > AI-based bots**. While most people today relate bots to some kind of AI, it is still very complicated to create complex bots using pure free text interaction, especially when you are not a machine learning or deep learning expert. To address this issue, today's messenging platforms (especially [Telegram](https://telegram.org) and now Facebook messenger) now provide extremely powerful bot APIs that allow bots to interact with users through customized buttons and/or keyboards. Using buttons and customized keyboards makes it particularly straightforward for users to interact with the bot has they have a limited, pre-defined choice of answers. For developers, using customized buttons and/or keyboards is also a great news because it removes the need to develop a powerful AI engine to achieve basic functionalities. It does not means that AI should not be used of course but at least it is not a requirement anymore.
* **Implementing complex finite-state machines is not easy**. If an AI engine is now optional, it does not make developing a complex bot a lot easier. Indeed, as a developer, you now need to implement finite-state machine like behavior for your bot to interact with the user. If this is easy to do when your bot has very few states, it can become quite messy if your bot starts being more complex.

This is why we developped Giskard. Giskard aims at making it easy to develop complex keyboard-based bots. Giskard has been developed for a real world project with real users (60.000 as this is written). Giskard has been developed to provide [LaPrimaire.org](https://laprimaire.org) with a [telegram bot](https://www.youtube.com/watch?v=AUoArIkCECo) to enable french citizens to crowdsource their election candidates for the 2017 french presidential elections. Due to the nature of the project, it was clear to us that Giskard had to be open-source.

Last but not least, Giskard is AI compatible. If you want AI in your bot to be able to answer to "unspecified" actions, you can still do it by integrating with the understanding module of [Wit.ai](https://wit.ai) which is accessible through their API.

The name *Giskard* comes from [R. Giskard Reventlov](http://asimov.wikia.com/wiki/R._Giskard_Reventlov) from the Asimov Robot series. In Asimov's novels, Giskard is not supposed to be a very advanced robot (like R. Daneel Olivaw) but a very strong a reliable one. However, throughout the story, Giskard will prove to be a robot more advanced than expected... I stop here to avoid any spoiler :)

## How Giskard works

Giskard's logic is implemented via *Add-ons*. When Giskard is launched, it loads all its available add-ons. Each add-on provide Giskard with a specific feature set. An add-on is a combination of 3 different entities :

- *Screens* define the user-experience and the workflow of an add-on.
- *Callbacks* define the business logic of an add-on.
- *Messages*  define the localized message strings of an add-on.

The add-ons should be located in the ```bot/add-ons/``` directory. They are loaded automatically by Giskard at startup.

### Screens

Giskard uses screens to determine what to display to the user at a given state. For a given module (add-on), screens are defined as a ruby hash. Here is an example with the screens of the Home add-on:
```ruby
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

- **answer** (optional) is a message id of the form ```<namespace>/<screen_name>_answer``` that defines the text string (exact match) that the user should input to trigger the display of this screen. The message_id is rendered into the exact localized string at runtime so you need to make sure to have set a value for the message id in your add-on messages (see *messages* section below). Giskard expects an exact match with the user input because, most of the time, the input will not be produced as 'free-text' input from the user but by the push of a pre-defined keyboard button. It is important to note that at least one screen should have */start* as an answer because this is the 1st message that Telegram will send to a bot when a user starts using a bot. The *answer* value should be unique within an add-on (i.e. within a given namespace). If another add-on has a screen with the exact same *answer*, Giskard disambiguates by :
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

The add-on registers its screens to Giskard by calling the ```Bot.updateScreens()``` method in the ```self.included()``` method. It is important to note also that the add-on can register a menu in the bot main menu by calling the ```Bot.addMenu()``` method.
```ruby
Bot.updateScreens(screens)
Bot.addMenu({:home=>{:menu=>{:kbd=>"home/menu"}}})
```

### Callbacks

A screen can have a callback as an attribute. Callbacks are method where the business logic is being executed.

Example for the above ```ask_email``` screen example :
```ruby
:ask_email=>{
	:answer=>"home/ask_email_answer",
	:callback=>"home/ask_email",
},
```

For this to work, you need to define the method ```home_ask_email``` in the add-on. Here is the code of the callback :
```ruby
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

### Messages

Giskard messages for a specific add-on are defined as a ruby hash inside the given add-on. Messages id are in the form ```<namespace>/<screen_name>``` and must match the name of the related screen ids. Messages can have 1 or several lines. Each line is being sent as a separate message from Giskard. Here is an example with the Home add-on :
```ruby
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
			:menu=>"What do you want to do ? Please use below buttons to tell me what you would like to do.",
			:ask_email_answer=>"My email",
			:ask_email=>"What is your email ?",
			:email_saved=>"Your email is %{email} !",
			:email_wrong=>"Hmmm... %{email} doesn't look like a valid email #{Bot.emoticons[:confused]}"
			:my_action_2_answer=>"Action 2",
			:my_action_2=>"Texte for action 2"
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
			:menu=>"Que voulez-vous faire ? Utilisez les boutons du menu ci-dessous pour m'indiquer ce que vous souhaitez faire.",
			:ask_email_answer=>"Mon email",
			:ask_email=>"Quel est votre email ?",
			:email_saved=>"Votre email est %{email} !",
			:email_wrong=>"Hmmm... %{email} n'est pas un email valide #{Bot.emoticons[:confused]}",
			:my_action_2_answer=>"Action 2",
			:my_action_2=>"Texte pour l'action 2"
		}
	}
}
```

#### localization
As you can see, the messages are localized. The supported locales are to be defined in the ```SUPPORTED_LOCALES`` constant in ```config/application.rb```.  Messages can have variables in the form of ```%{variable}```. If one or more variable(s) are present in a screen's message, the screen must have a callback defined to render the variable(s).

### images

If a message starts with ```image:<relative_image_url>``` (example: ```image:static/images/keyboard-button.png```), Giskard will send the image to the user and the image will render in the user chat. Remote image URL is also supported (example: ```image:https://myserver.com/images/keyboard-button.png```)

#### url previews

If a message line contain a web url, by default, Telegram displays a web preview of the first url found. This behavior can be disabled by specifying the attribute ```:disable_web_page_preview=>true``` in the screen.

### parse mode

By default, Telegram renders messages as pure text. Telegram also supports basic html formatting in message. To use this feature, you need to specify ```:parse_mode=>"HTML"``` in the screen.

#### variables

The add-on registers its messages to Giskard by calling the ```Bot.updateMessages()``` method in the ```self.included()``` method. It is important to note also that the add-on can register a menu in the bot main menu by calling the ```Bot.addMenu()``` method.
```ruby
Bot.updateMessages(messages)
```

### User object

The user object is defined in [bot/user.rb](https://github.com/telegraph-ai/giskard/blob/master/bot/users.rb). You can extend it as you wish but it should at least have the following structure:
```ruby
{
	'firstname'=>user.first_name,
	'lastname'=>user.last_name,
	'username'=>user.username,
	'session'=>bot_session,
	'settings'=>user_settings
}
```
With ```bot_session``` a ruby hash that defines the current user session :
```ruby
bot_session={
	'last_update_id'=>nil,
	'current'=>nil,
	'expected_input'=>"answer",
	'expected_input_size'=>-1,
	'buffer'=>""
}
```

And ```user_settings``` a ruby hash that stores the current user settings :
```ruby
user_settings={
	'locale'=>'fr', #mandatory
	'blocked'=>{ 'abuse'=>false }, # optional
	'actions'=>{ 'first_help_given'=>false }, # optional
}
```
## Giskard Setup

For maximum performance, Giskard does not use the polling mode for the Telegram bot but instead uses the [webhook method](https://core.telegram.org/bots/api#setwebhook). By default, Giskard uses the [unicorn web server](http://unicorn.bogomips.org/) to serve requests. Please be aware that unicorn uses system processes which means that if you are spawning your Giskard bot on more than 1 processes, memory between these processes **is not shared** so you will need to use a database or some shared memory techniques if you want to share data between your processes.

### Pre-requirements

* **Create your bot**. Prior to use Giskard, you need to create your Telegram Bot by following [these instructions](https://core.telegram.org/bots#3-how-do-i-create-a-bot) provided by Telegram. For FB Messenger, please refer to Facebook Messenger platform's [Getting Started](https://developers.facebook.com/docs/messenger-platform/quickstart).
* **Create your keys.local.rb**. Copy ```config/keys.rb``` into ```config/keys.local.rb``` and fill-in the constants :
    - **TG_TOKEN** Your bot token as provided by Telegram's BotFather (it looks like: "907662123:HJLyuyHF86xcvw_KJoO5jhgsRKK92adByDC"). Required if you are developing a Telegram bot.
    - **TG_WEBHOOK_PREFIX** A random string to hide your Telegram webhook endpoint (example: "FDFdfdfEGFDGedqqeq")
    - **TG_SECRET** A secret (random) string for to authenticate custom Giskard API calls. This is not required for Giskard to work.
    - **FB_PAGEACCTOKEN** Your facebook page access token. Required if you are developing a FB Messenger bot. Required if you are developing a Facebook messenger bot.
    - **FB_WEBHOOK_PREFIX** A random string to hide your FB Messenger webhook endpoint (example: "FDFweiouisFGdGFG")
    - **FB_SECRET** A secret (random) string for to verify your FB Messenger webhook.
* **Setup your webhook development environment**. Developing with webhooks can be tricky because it requires Telegram to be able to send queries to your Giskard instance. If, like 99% developers, you develop on your local PC, Telegram will not be able to send you requests. You should consider using [ngrok](https://ngrok.com/), a true life-saving tool, to easily create secure tunnels to your localhost, thus allowing Telegram and/or Facebook to contact your localhost. You should consider purchasing a licence because it is cheap yet super powerful but, for testing purposes, the free version will do : ```ngrok http 8080```
* **Declare your webhook endpoint to your bot**. For a FB Messenger bot, you need to register it from your App's webhook settings page. For a telegram bot, you can use ```curl``` to do it in a straightforward manner :
```
curl -s -X POST https://api.telegram.org/bot<TGTOKEN>/setWebhook?url=<yoursubdomain>.ngrok.io/<TG_WEBHOOK_PREFIX>
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

### Performance notes

Giskard has been developed with performance in mind. Ruby haters will say it is surprising given the choice of Ruby but when it comes to bots, raw execution performance should not be regarded as the most important performance factor. Indeed, memory usage is much more important for 2 reasons :

* as bots try to mimic normal users behavior, they do not send their answer as fast as possible as it would not look natural. This means that a request can take up to several seconds to be completed. Not because there are heavy computations behind but because Giskard purposedly "sleeps" between messages to emulate a normal user behavior. Note that Giskard can be configured to never sleep in case you want Giskard to answer as fast as possible.
* to handle large loads, you will need to spawn a lot of Giskard instances (in the form of unicorn processes) to be able to handle parallel requests. This is why minimizing memory usage of a Giskard process was very important.

Giskard has been architected to use as little memory as possible. To give you an example, in our complex Giskard bot (using ruby gems for mandrill, postgresql, algolia, aws, google cs etc..) every Giskard instance uses less than 1MB of memory. Plus Giskard can serve both Telegram AND FB Messenger bots from 1 single instance which is quite helpful performance wise if you happen to run your bot on different platforms.

## Compatibility notes

### Telegram support

Giskard now supports Telegram API v1.* and the its feature coverage of the Telegram API is not yet 100% (inline bots are not supported yet for example). Support for [Telegram API v2.*](https://core.telegram.org/bots/2-0-intro) should be pretty straightforward, we just need to take the time to do it :)

### FB Messenger support

FB Messenger support is still pretty early so it does not cover the full spectrum of the FB Messenger API but, in case you need FB Messenger API features that are not yet covered by Giskard, just ask (or even better : send us your PR), adding support for more API features in Giskard is really easy to do.

It is also important to note that, at this stage, Giskard does not implement [message_echoes, message_deliveries or message_reads](https://developers.facebook.com/docs/messenger-platform/webhook-reference) subscriptions so make sure to disable them in the settings of your webhook unless you want your bot to be spammed with requests it does not know how to handle (yet).
