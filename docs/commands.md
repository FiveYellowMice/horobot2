# Commands of HoroBot2

Commands are special messages that control the behavior of HoroBot2. On different chat platforms, the format of a command may be different.

On Telegram, command format follows the general format of Telegram bot API. That is, a message starts with a slash `/` and followed by the name of the command. Optionally, an `@username` can be added to avoid conflict with other bots. For example, `/status` and `/status@yoitsuhorobot` both triggers the "status" command. Arguments are passed after these and a space.

On IRC, commands starts with `horo/` or reply of the bot's nick and a slash. For example, `horo/status` and `HoroBot: /status` both triggers the "status" command. Arguments are passed after these and a space.

## List of available commands

| Command                | Arguments | Description                                             |
| ---------------------- | --------- | ------------------------------------------------------- |
| status                 | 0         | Show the status of this group.                          |
| help                   | 0         | Show a help message.                                    |
| temperature            | 0         | Show the temperature of this group.                     |
| force_send             | 0         | Send an Emoji right now.                                |
| set_threshold          | 1         | Set the threshold of this group.                        |
| set_cooling_speed      | 1         | Set the cooling speed of this group.                    |
| add_emoji              | 1         | Add an Emoji to the list of Emojis of this group.       |
| rem_emoji              | 1         | Remove an Emoji from the list of Emojis of this group.  |
| telegram_set_quiet     | 1         | Set if it should suppress sending messages to Telegram. |
| telegram_is_quiet      | 0         | Show if it is suppressing sending messages to Telegram. |
| irc_show_ignored_users | 0         | Show ignored users on IRC.                              |
| irc_add_ignored_user   | 1         | Add a user to ignore on IRC.                            |
| irc_rem_ignored_user   | 1         | Stop ignoring a user on IRC.                            |
