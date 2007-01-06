--
-- $Id: ClubDead-enUS.lua 4162 2006-11-16 19:05:44Z james $
--

local L = AceLibrary("AceLocale-2.2"):new("BeQuiet")
L:RegisterTranslations("enUS", function() return {
    ["AceConsole-Commands"] = {"/bequiet", "/bq", "/stfu"},
    ["dateformat"] = "%m/%d/%y %H:%M:%S",
    ["BeQuiet"] = true,
    ["announce"] = true,
    ["announce periodic purges in the chat frame"] = true,
    ["ignoretime"] = true,
    ["set default ignore time in seconds"] = true,
    ["[#d#h#m#s]"] = true,
    ["checktime"] = true,
    ["set time in between checks for expired entries in seconds"] = true,
    ["add"] = true,
    ["add entry to BQ list"] = true,
    ["<user> [#d#h#m#s]"] = true,
    ["del"] = true,
    ["remove entry from BQ list"] = true,
    ["<user>"] = true,
    ["show"] = true,
    ["show BQ list"] = true,
    ["added %s until %s (in %s)"] = true,
    ["removed %s"] = true,
    ["%s is not on the BQ list"] = true,
    ["%s - %s (in %s)"] = true,
    ["%s - %s (expired)"] = true,
    ["BQ entry for %s has expired"] = true,
    ["clear"] = true,
    ["clear BQ list"] = true,
    ["current BQ list:"] = true,
    ["clearing BQ list"] = true,
    ["no entries on BQ list"] = true,
    ["%s is already on the BQ list until %s (in %s)"] = true,
    ["%s was already on the BQ list; extended until %s (in %s)"] = true,
    ["could not add %s to BQ list (possibly offline?)"] = true,
    ["could not remove %s from BQ list - will try again later"] = true,
    ["attempting to ignore %s"] = true,
    ["add_del_wait"] = true,
    ["set time to wait after adding or deleting to check if it worked"] = true,
    ["queueing %s for later addition"] = true,
    ["attempting to unignore %s"] = true,
    ["attempting to ignore %s (queued from previous failure)"] = true,
    ["giving up trying to add %s (max attempts exceeded)"] = true,
    ["upgrading config from SV %d to %d"] = true,
    ["<attempts>"] = true,
    ["max_add_attempts"] = true,
    ["set number of times to try to add someone who is offline"] = true,
} end)

--
-- EOF
