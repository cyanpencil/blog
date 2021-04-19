---
layout: default
title:  "Telegram notification on ssh login "
date:   2019-07-14 01:37:07 +0100
---

# Get notified on Telegram on every ssh login 

<center>
<img src="{{ site.baseurl }}/assets/images/telegram_login_alert.png" width="70%" align="middle"/>
</center>

## Step 1: Create a telegram bot

- Open up telegram, search `@botfather` and start a conversation with it
- Type `/newbot` and follow the instructions to choose a username for your bot
(with which you can search for your bot with @username) and a screen name 
(just the name that will appear at the top of the conversation with your bot.
- Save the **token** generated by `@botfather` somewhere
- Look up your bot in the Telegram search (@username) and start a conversation with
it, by sending a random message (*this step is important, you can't skip it. Telegram
  does not allow bots to send messages to anyone; a conversation must have been
started already*).
- Finally, you must know what is your telegram **chat ID** to receive messages. Start a conversation in Telegram with `@getmyid_bot`; you will receive your personal chat ID.


## Step 2: Test if the bot is working

You can send messages using the Telegram HTTP API; it's particularly useful because
we can call that from the command line using `curl`:
```bash
curl "https://api.telegram.org/bot$KEY/sendMessage" -d "chat_id=$USERID&text=hello world!"
```
where `$KEY` is your bot token and `$USERID` is your telegram chat id you got before.

You should receive on telegram a message from your newly created bot saying "hello world!"

## Step 3: Script to send messages to you from the bot

Now let's set up a script that gathers information on a ssh client and sends a message
to you giving various info such as the user, the IP, and sometimes even the location
of the client.
We will use the environment variable `$SSH_CONNECTION`, that contains the client IP and port.
This variable is set up each time by `sshd` for each tty it allocates (that means, for each
  different connection we will have a different variable in our environment).
We will also make a request to `https://ipinfo.io`, which will give us information such
as the AS number and (sometimes) the geolocation of a given IP.
The following script will send a message to you like the one in the screenshot above:
```bash
#!/bin/bash

USERID="<your-chat-id>"
KEY="<your-bot-token>"

URL="https://api.telegram.org/bot$KEY/sendMessage"
DATE_EXEC="$(date "+%d %b %Y %H:%M")" 
TMPFILE="$(mktemp)" 
if [ -n "$SSH_CONNECTION" ] && [ -z "$TMUX" ] && [[ ! $PAM_TYPE =~ "close_session" ]] ; then 
	IP=$(echo $SSH_CONNECTION | awk '{print $1}') # get client IP address.
	HOSTNAME=$(hostname -f) 
	IPADDR=$(hostname -i | awk '{print $1}') # get server IP address
	curl https://ipinfo.io/$IP -s -o $TMPFILE # info on client IP (json)
	CITY=$(cat $TMPFILE | sed -n 's/^  "city":[[:space:]]*//p' | tr "\"," "  ") 
	REGION=$(cat $TMPFILE | sed -n 's/^  "region":[[:space:]]*//p' | tr "\"," "  ")
	COUNTRY=$(cat $TMPFILE | sed -n 's/^  "country":[[:space:]]*//p' | tr "\"," "  ")
	ORG=$(cat $TMPFILE | sed -n 's/^  "org":[[:space:]]*//p' | tr "\"," "  ")
	TEXT="[$PAM_USER]\n$DATE_EXEC\n$PAM_USER logged in to $HOSTNAME ($IPADDR) \nip:$IP \ncountry: $COUNTRY\ncity: $CITY \nregion: $REGION \norg:$ORG"
	TEXT=$(echo $TEXT | sed "s/\\\n/%0a/g")
	curl -s --max-time 10 -d "chat_id=$USERID&disable_web_page_preview=1&text=$TEXT" $URL > /dev/null
	rm $TMPFILE #clean up after
fi
```

Substitute the values of USERID and KEY variables with your chat id and bot token you got before.
After saving, make sure that the script has the right permissions: `chmod 705 your_script.sh` (readable and executable by everyone).



## Step 4: Execute script on every ssh login

There are various ways we can call the script:

### 1. Use the pam\_exec module

Open the file `/etc/pam.d/sshd` and append the following line at the end:
```
session optional pam_exec.so /<path_to_yourscript.sh>
```

### 2. Inside sshd config

Open the file `/etc/ssh/sshd_config` and append the following line:
```
ForceCommand /<path_to_yourscript.sh>; bash -c ${SSH_ORIGINAL_COMMAND:-bash -il}
```
We force the execution of our alert script and then continue execution to the
given command if it was provided, or to the login shell (`bash -il`) if the variable
`$SSH_ORIGINAL_COMMAND` is not set.


You can set up more fine-grained checks on when sending the telegram alert this
way.  Suppose your server is inside a VPN, but it's also exposed to the
internet. Let's say you want to be alerted only when someone logs in from the
internet. Append the following lines to `/etc/ssh/sshd_config`:

```
Match Address *,!10.0.0.0/24
	PermitRootLogin no
	ForceCommand /<path_to_yourscript.sh>; bash -c ${SSH_ORIGINAL_COMMAND:-bash -il}
```

The line `Match Address *,!10.0.0.0/24` will catch every client that is *not*
connected through your VPN (10.0.0.0/24). We disable root logins from outside
our VPN, and ensure that the first command on every successful ssh
connection will be executing your script.

You can find much more information on how to set `Match` rules and other useful
commands inside `man sshd_config`.


### 3. Inside profile.d

If you're using a Debian-like system, you can just copy your script inside
the `/etc/profile.d` directory. It will be automatically executed on every login!

-----
Adapted and expanded from: [8192.one's blog](https://8192.one/post/ssh_login_notification_withtelegram/)