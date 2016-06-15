# Giskard Bot Engine

Giskard is a bot engine to create advanced bots for modern messenging apps. It natively supports Telegram messenger bots. Facebook messenger bot support is around the corner. Giskard is written in ruby (not rails) using [telegram-bot-ruby](https://github.com/atipugin/telegram-bot-ruby) and the [Grape API framework](https://github.com/ruby-grape/grape).

## About Giskard

Giskard has been created to leverage [Telegram Bot API](https://core.telegram.org/bots/api) and, in particular, the possibility to interact with the user through custom keyboard actions. Giskard is a bot engine that enables you to easily create complex and customized user experience. To this date, Giskard does not implement any sort of AI (otherwise Giskard would have been named [R. Daneel Olivaw](https://en.wikipedia.org/wiki/R._Daneel_Olivaw)) although it could be "easily" added. Giskard enables you to easily implement flexible [Finite-state machine](https://en.wikipedia.org/wiki/Finite-state_machine) for your bot.

Giskard has been developed to provide [LaPrimaire.org](https://laprimaire.org) with a [telegram bot](https://www.youtube.com/watch?v=AUoArIkCECo) to enable french citizens to crowdsource their election candidates for the 2017 french presidential elections.

## How Giskard works

Giskard's logic is implemented using a combination of 3 different entities :

- *screens* a screen defines what is being displayed to the user at a given state. Here is an example of a screen:
```
:welcome=>{
	:answer=>"/start",
	:text=>messages[:fr][:home][:welcome],
	:disable_web_page_preview=>true,
	:callback=>"home/welcome",
	:jump_to=>"home/menu"
}
```
- *callbacks*
- *messages*
