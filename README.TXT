--
-- $Id$
--

BeQuiet
=======

BeQuiet is an addon for World of Warcraft that adds people to your ignore
list temporarily.

This is helpful for adding someone who is annoying right this minute without
having to worry about them staying on your ignore list forever taking up a
spot, or (if the person is someone you know) you making the mistake of
whispering them while they are still on the /ignore list.

Overview
--------

When someone is added to the BQ list, the addon will attempt to ignore them.
If successful, it will add them to the BQ list, otherwise it will add them
to the BQ queue for later addition.  This means that you can add people who
are not online using the slash command.  If someone is added to the queue,
the expiration time is set relative to when you first asked for them to be
ignored, not when they finally get ignored.  It is possible to have someone
get added to the queue but then expire before they are actually ignored. 

At an interval defined by "checktime" (see below), BeQuiet will scan the BQ
list for any entries which are expired.  Expired entries on the BQ list
will be unignored.  Expired entries from the BQ queue will simply be
removed.
7
BeQuiet will not attempt to add someone from the queue indefinately.  There
is a configuration setting "max_add_attempts" that controls the maximum
number of times that BQ will try to add someone, after which they will be
removed from the queue.

Normally, BQ will try to add someone for max_add_attempts * checktime, though
this presumes a continuous login session.  BQ also performs a scan of the
list when you first log on and before you log off, so this can decrease the
actualy time spent trying to add someone (but not the number of attempts)

Configuration
-------------

BeQuiet may be configured using standard Ace2 slash commands or via a
dropdown menu available by right-clicking on the minimap icon.

In case another addon uses /bq, the longer form /bequiet is also available.

The ignore list and add queue are stored on a per-realm basis.  All other
configuration values are shared across all characters.

The configuration settings are as follows.  Defaults are in brackets.

ignoretime [6h]

The default duration to ignore someone if they are added by
clicking on the minimap icon, using the "Add Target" option in the
dropdown menu, or if no duration is supplied to the slash command.

checktime [30m]

The duration to wait in between scans of the list and queue for
expired or queued entries.

max_add_attempts [10]

The number of times BQ will attempt to add someone to the list before giving
up. 

add_del_wait [3s]

When you /ignore someone, you receive no immediate feedback as to whether it
worked or not - you have to check the ignore list after a small delay.  This
configuration setting is that delay.  If you are on a connection with very
high latency, you may wish to increase this to 5s or even 10s to ensure that
you aren't constantly adding entries to the queue for one cycle.

add_popup_menu [true]

toggles on/off adding "Be Quiet!" as an option to the popup menu that appears
when you right click on a player name in chat, the friends pane, etc.

Usage
-----

To add someone to the list, target them and left-click on the minimap icon,
or type "/bq add name", where name is the name of the person you wish to
add.

If you would like to use a non-default ignore time, you must use the slash
command.  Follow the name with a duration, as in "/bq add name 1d".

You can also add someone from the right-click dropdown menu after targeting
them.

To remove someone from the list (or queue), hover over the minimap icon to
see the list, then hover over the person's name and left click.  Or, use
the slash command "/bq del name".

You can also delete someone from the right-click dropdown menu.  The menu
options for deletion are dynamically generated, so you will only see the
option and sub-options for list and/or queue if there are entries of that
type.

You can show the current list by hovering your mouse over the minimap icon,
or using the slash commands "/bq show" or "/bq list".  The tooltip can also
be detached so it stays on your screen even when you are not hovering over
the minimap icon.  Select "Detach Tooltip" from the right-click dropdown
menu.

You can force a scan of the list and queue by shift-left-clicking on the
minimap icon, choosing "Scan list" from the right-click dropdown menu, or
using the slash command "/bq scan".

You can completely clear the list by selecting "Clear List" from the
right-click dropdown menu, or the slash command "/bq clear".

Durations
---------

The ignoretime, checktime, add_delay_wait and individual ignore times for
new additions use a duration syntax consisting of one or more unit values.
Internally, everything uses seconds.

Units are M for months (30 days), w for weeks, d for days, h for hours, m
for minutes and s for seconds. Order does not matter, and unit types can be
repeated.

Here are some example legal durations:

  2w = 604800 seconds
  1h = 3600 seconds
  1d = 86400 seconds
  5m = 300 seconds
  1d1h1m1s = 90061 seconds
  1s5s10s6s = 22 seconds
  1M1w = 3196800 seconds

And here are some invalid durations:

  2h 30m (invalid due to spaces - would parse as 2h)
  2.5h   (invalid due to the decimal - would not parse)
  1y     (invalid due to an unknown unit 'y' - would not parse)
  3600   (invalid due to lack of units - would not parse)

FuBar Plugin
------------

BeQuiet has a built in plugin for FuBar.  If you have FuBar, the icon
described as being attached to the minimap will instead be on your panel.
If enabled, the text on the panel will consist of two numbers separated by
a slash; this is the number of people on your BeQuiet list and the number
of people queued for later addition.

Compatibility
-------------

BeQuiet is compatible with WoW 2.0.1 and TBC 2.0.3, though you will have to
enable "load out of date addons" for use in beta due to the TOC version
being different.

Localization
------------

BeQuiet is localized using the AceLocale library, but only has enUS
translations right now.  If you are interested in performing localization,
please contact me at kynan@hukdonfonex.com

--
Kynan (Eitrigg US)

