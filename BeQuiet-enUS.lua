--
-- $Id: ClubDead-enUS.lua 4162 2006-11-16 19:05:44Z james $
--

local L = AceLibrary("AceLocale-2.2"):new("BeQuiet")
L:RegisterTranslations("enUS", function() return {
    ["AceConsole-Commands"] = {"/bequiet", "/bq"},
    ["dateformat"] = "%m/%d/%y %H:%M:%S",
    ["BeQuiet"] = true,
    ["announce"] = true,
    ["announce periodic purges in the chat frame"] = true,
    ["ignoretime"] = true,
    ["set default ignore time in seconds"] = true,
    ["<seconds>"] = true,
    ["checktime"] = true,
    ["set time in between checks for expired entries in seconds"] = true,
    ["add"] = true,
    ["add entry to BQ list"] = true,
    ["<user> [seconds]"] = true,
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
} end)

--
-- EOF
