sshmanager
==========

Distribution of ssh keys on several hosts with one config file

The idea behind
===============

Some of you know this: You or a colleague has lost the private ssh key file. Now you have to log on on every server and every user, remove the old public key from the authorized_keys file and add the new one. After you finished you maybe can't login on some machines because a copy-paste-error happened. Thats annoying!
If you don't have a configuration helper lile puppet installed and configured this simple script can help you out.

It is a little perl application with two required parameters: and endpoint and a path to the config file. Currently there are two endpoings implemented: local and http. See more under Endpoints.
You can call it manually or via cron. I prefer the cron way because it is designed to run non-interactive with no output but error messages.

The configuration
=================

The configuration which key is distributed to which user account is done in a single XML file. The applications reads the xml file and do its job.
A productive XML file (which I use) can be found here: http://files.veloc1ty.de/sshKeys/config-sample.xml

Building the head:
------------------

The head is always the same. You can simply copy it:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<sshmanager>
```

Adding the public keys
----------------------

Add all the public keys you want to manage. The mapping which key belongs on which user account is not done here. I suggest not to use spaces, points or other symbols. Just use plain text and numbers.

```xml
<keys>
	<key alias="jan">ssh-rsa [...]</key>
	<key alias="michaelPC">ssh-rsa [...]</key>
	<key alias="michaelLaptop">
		ssh-rsa [...]
	</key>
	<!-- Add more here -->
</keys>
```

Leading or trending whitespaces are ok and will be removed. You also don't have to wrap them in a ``<![[CDATA]]>`` tag. Aplly a format you like.

Adding groups
-------------

You can combine one or more keys to groups. Of course one key can be in multiple groups. At runtime duplicates are filtered out and are written only once. You reference the key from now on just by the alias name.
Here is an example:

```xml
<groups>
	<group alias="superadmin">
		<keys>
			<key>michaelPC</key>
			<key>michaelLaptop</key>
		</keys>
	</group>
	<group alias="support">
		<keys>
			<key>jan</key>
			<key>michaelPC</key>
		</keys>
	</group>
</groups>
```

Combine as much as you can (even single keys if you pretend to grow) into groups.

Adding the hosts
----------------

Now comes the cool part. Each machine where the application run is searching for its entry in the file. This is done via the attribute "name".

```xml
<hosts>
	<host name="monitoring">
		<users>
			<user name="root">
				<groups>
					<group>superadmin</group>
				</groups>
			</user>
			<user name="supportaccount">
				<groups>
					<group>support</group>
					<!-- More groups if needed -->
				</groups>
				<keys>
					<key>otherkey</key>
					<!-- More keys if needed -->
				</keys>
			</user>
		</users>
	</host>
	<!-- Next host -->
</hosts>
```

To tell the truth: It' a little bit unreadable. But to follow standard XML schema you will get into it really quickly. Let's tear it down.

1) Find the correct part of the file
You can have unlimited hosts. Each distributor script fetches the while file and anlyze the keys and groups. Then it only analyzes the part of the hosts which the name equals the machines hostname (retrieved by the hostname command). Example: The application on host 'monitoring' only evaluates the host-part with the name 'monitoring'.

If the application didn't find any corresponding entry it will die with an appropriate error message. Cron will hopefully send you an E-Mail to inform you. Otherwise the application goes on.

2) Iterate over each user
You now tell them which UNIX users should be covered by the application. The first one is root:

2.1) Check if the current user has an .ssh directory in the home folder. The application reads the /etc/passwd file to get the information. If it exists -> go on.
2.2) If there is a group part, add every keys associated with the group. Die if no group is found or a key in the group is missing.
2.3) If there is a keys part, add every key. Die if no key is found by that name.
2.4) Sort out duplicates and write to the authorized_keys file.
2.5) Next user if any

3) Finish
The applications exits.

Finish
------

The last tag closes the rood node:

```xml
</sshmanager>
```

Endpoints and locations
=======================

You have to devine an endpoint and an location. Currently there are two endpoints available: local and http.

local
-----

A local endpoint can be used while developing the config file. The config file is then fetched from a local disk or mounted network share. A sample call would be this:

``perl distributor.pl --endpoint "local" --location "/path/to/config.xml"``

http
----

This is the type of endpoint you normally use in productive environments. The config file is fetched via http. A sample call would be this:

``perl distributor.pl --endpoint "http" --location "http://path/to/config.xml"``

Command line options
====================

The following command line options can be used:

- endpoint => What endpoint/retrieve method to use
- location => Where is the file located
- hostname => Manually set the hostname
- dry => Turn on dry mode. See "Dry-run"
- verbose => Turn on verbose output
- create-ssh-directory => Create the .ssh directory if it is nonexistent
- debug => Show variable values

Endpoint and location are mandatory.

Output
======

As mentioned above the application is designed to run quietly. Normally it only prints error messages which should be catched by CRON and mailed to the admins.
You can get information what the application does via the ``--verbose`` option.

Dry-run
=======

To test out config files you can do a dry run. The application behave exactly like on a normal run. Verbose output is turned on.
You can trigger a dry run by adding ``--dry``

Cron
====

The best way to trigger the application is via cron or a cron replacement. I added the following job in ``/etc/crontab``.

``*/30	*	*	*	*	root	( cd /home/veloc1ty/workspaces/perl/sshmanager; perl distributor.pl --endpoint "http" --location "http://files.veloc1ty.de/sshKeys/config.xml"``

It is necessary to ``cd`` first into the project location so the application find the required modules.

Dependencies
============

To run this script you need root rights. The application itself has the following (perl) depencendies:

- XML::LibXML
- Getopt::Long
- LWP::UserAgent
- Term::ANSIColor

You have to figure it out how to install them. I recommend the CPAN way. Hint: XML::LibXML should be installed via apt. The package name is ``libxml-libxml-perl``.