---
layout: default
title:  "Whatsapp smali injection for n00bz"
date:   Mar 19 May 2020 03:38:29 PM CET
---

# Whatsapp smali injection for n00bz

I made this to solve a challenge while interviewing for a security IT company, here is a short writeup:

## Introduction 

The task of the project was about finding an obfuscated app on the play store, modifying it such that it would notify another app whenever it was opened.

I did not really have a quick way to check wheter an app on the play store was obfuscated or not, so I decided to choose an app that I knew for sure had at least some kind of obfuscation, and that app is _Whatsapp Messenger_.

The apk for "Whatsapp Messenger" I got is version 2.20.123, **x86** architecture (because that's the architecture of the emulator I am currently running)

## Finding an injection spot

I started by decompiling the apk down to the smali code using `apktool`:
```
apktool d -r -f com.whatsapp...
```

Then, I started inspecting the decompiled smali.
Unfortunately, _Whatsapp_ is not a small app by any means, with more than 13k smali classes:
```
$ find . -name "*.smali" | wc -l
13666
```
Furthermore, as you may see from the screenshot below, many of the classes and methods names were obfuscated. Some were implemented in native libraries, too.

![](https://i.imgur.com/YjZezrF.png)

It was not easy for me to find a good spot to inject code in. Ideally, I would have needed a function that would be executed every time the app is opened, but the mangled names were making this difficult. 

For some time I tried tracing all the functions executed by Whatsapp by installing `frida-server` on the emulator and starting Whatsapp with `frida-trace`, but I did not get very far with that.

After a while though I realized that _not all_ methods can be obfuscated, as there are some which are required to have a special name by Java or Android, such as `toString()`, `constructor()`, etc.  So, I started looking for methods like this that could indicate the start of an Activity, and soon I found out that `onCreate()` was not obfuscated too!

So, after running
```
grep -R ".method.*onCreate"
```
I found out about `com/whatsapp/Main.smali`, and decided to test if that was a suitable spot for injection.
I am not comfortable in smali, so I decided to look online and found out on a stackoverflow question that the best way was to display a Toast with the following smali:
```
const-string v0, "Hack the plan3t!"
const/4 v1, 0x1
invoke-static {p0, v0, v1}, Landroid/widget/Toast;->makeText(Landroid/content/Context;Ljava/lang/CharSequence;I)Landroid/widget/Toast;
move-result-object v0
invoke-virtual {v0}, Landroid/widget/Toast;->show()V
```
I inserted the code and recompiled the apk with:
```
apktool b com.whatsapp
keytool -genkey -v -keystore my-release-key.keystore -alias test -keyalg RSA -validity 10000
jarsigner -verbose -sigalg MD5withRSA -digestalg SHA1 -keystore my-release-key.keystore com.whatsapp.apk test
```
I had to read about smali registers and how do they work because I kept getting crashes, but after a few small adjustments to avoid using any registers the original `onCreate()` was using I got it to work!

![](https://i.imgur.com/zVHVfzn.png)

## The receiver app

Now, I had to code the app that kept the counter. I used one of the examples from [](https://github.com/android/user-interface-samples) to get started and I modified it to display a simple TextView.

I then studied a bit about available IPC methods in Android, and decided that the fastest one to implement was a `BroadcastReceiver` that listens on Intents from _Whatsapp_. 

Here is the code of the app that I properly named _Whatsapp Stalker_:
```
class MyReceiver extends BroadcastReceiver {
	int counter;
	TextView t;

	public MyReceiver(TextView t) {
		counter = 0;
		this.t = t;
	}

	@Override
	public void onReceive(Context context, Intent intent) {
		counter ++;
		t.setText("Number of times Whatsapp was opened: " + counter);
	}
}

public class MainActivity extends Activity {

	@Override
	protected void onCreate(Bundle savedInstanceState) {
		super.onCreate(savedInstanceState);
		setContentView(R.layout.sample_main);
		TextView textViewResource = (TextView) findViewById(R.id.text_html_resource);
		textViewResource.setText( "Number of times Whatsapp was opened: " + 0); 

		IntentFilter filter = new IntentFilter();
		filter.addAction("com.stalker.WHATSAPP_OPENED");
		MyReceiver myReceiver = new MyReceiver(textViewResource);
		registerReceiver(myReceiver, filter);
	}
}
```
The app is really spartan, but it does its job.

## The injection

Now I had to come up with the smali code to send an intent to the _Whatsapp Stalker_.
Again, I am not very knowleadgeable on smali, and I really wanted to get it to work
without too much trial and error, so I decided to cheat a little bit: I just wrote the normal
Java code to send an intent in an empty app, then compiled it, decompiled my own app with apktool, and 
just _copy pasted_ the relevant smali code:

```
new-instance v8, Landroid/content/Intent;
invoke-direct {v8}, Landroid/content/Intent;-><init>()V

const-string v7, "com.stalker.WHATSAPP_OPENED"

invoke-virtual {v8, v7}, Landroid/content/Intent;->setAction(Ljava/lang/String;)Landroid/content/Intent;


const-string v7, "com.example.whatsappstalker"

invoke-virtual {v8, v7}, Landroid/content/Intent;->setPackage(Ljava/lang/String;)Landroid/content/Intent;

invoke-virtual {p0, v8}, Lcom/example/whatsappstalker/MainActivity;->sendBroadcast(Landroid/content/Intent;)V
```


I know this is not the most elegant solution, but it works!

I just had to adjust some register names and package paths, but in the end I got what I wanted:

![](https://i.imgur.com/L9IK4p2.png)

## Conclusion

Since I was already very late with the submission, I did not put much effort into making the injection discreet or the receiver app fancy, I just wanted to get a proof of concept.

Some limitations of my current approach, that I could have fixed with more time:
- The receiver app only increases the counter while it is open in the background. It would have been a better solution to implement it as a Service that is always on in the background.
- The receiver app reset the counter everytime it is closed. This could be fixed by saving it to `Preferences` or something similar.
- The count only get increased when _Whatsapp_ is created - that means that if it is open in the background you need to close it and open it again to increase the counter; perhaps it would have been more interesting if it increased the counter every time the user switched to _Whatsapp_?
- The `sendBroadcast(Intent)` is not the most discreet way to talk to another application - I restricted the listening of such Intent only to applications that have the package "com.example.whatsappstalker", but it could still be improved a lot


Thanks for taking the time to read this!
_Luca Di Bartolomeo_

