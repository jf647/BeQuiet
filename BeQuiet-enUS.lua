--
-- $Id$
--

local L = AceLibrary("AceLocale-2.2"):new("BeQuiet")
L:RegisterTranslations("enUS", function() return {
    ["AceConsole-Commands"] = {"/bequiet", "/bq" },
    ["dateformat"] = "%m/%d/%y %H:%M:%S",
    ["BeQuiet"] = true,
    ["ignoretime"] = true,
    ["set default ignore time"] = true,
    ["[#M#w#d#h#m#s]"] = true,
    ["checktime"] = true,
    ["set time in between checks for expired entries"] = true,
    ["add"] = true,
    ["add entry to BQ list"] = true,
    ["<user> [#M#w#d#h#m#s]"] = true,
    ["del"] = true,
    ["remove entry from BQ list"] = true,
    ["<user>"] = true,
    ["show"] = true,
    ["show BQ list"] = true,
    ["added %s until %s (in %s)"] = true,
    ["removed %s"] = true,
    ["%s is not on the BQ list"] = true,
    ["   %s - %s (in %s)"] = true,
    ["   %s - %s (expired)"] = true,
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
    ["current BQ queued adds:"] = true,
    ["   %s - %s (in %s) - %d attempts"] = true,
    ["   %s - %s (expired) - %d attempts"] = true,
    ["giving up trying to add %s (expire time exceeded)"] = true,
    ["list"] = true,
    ["scan BQ list for queued adds or expired entries"] = true,
    ["scan"] = true,
    ["invalid duration '%s'"] = true,
    ["removing %s from add queue"] = true,
    ["invalid checktime '%s' - regular scans are disabled"] = true,
    ["Clear List"] = true,
    ["Scan List"] = true,
    ["Default Ignore Time"] = true,
    ["Check Time"] = true,
    ["Add/Delete Delay"] = true,
    ["Max Add Attempts"] = true,
    ["On BQ List"] = true,
    ["(expired)"] = true,
    ["Name"] = true,
    ["Until"] = true,
    ["In"] = true,
    ["In Queue to be Added"] = true,
    ["Attempts"] = true,
    ["no entries"] = true,
    ["Click to add or remove your current target. Shift-Click to re-scan for expired or queued entries"] = true,
    ["'%s' is not a player"] = true,
    ["Config"] = true,
    ["Add Target"] = true,
    ["Ignore Time"] = true,
    ["Add current target to BQ list with default time"] = true,
    ["Configuration Parameters"] = true,
    ["scanning BQ list"] = true,
    ["Delete from BQ List"] = true,
    ["Delete Ignored Names"] = true,
    ["Delete Queued Names"] = true,
    ["Remove %s from BQ list"] = true,
    ["Remove %s from BQ queue"] = true,
    ["List"] = true,
    ["Queue"] = true,
    ["Delete"] = true,
    ["UNITPOPUP_BEQUIET"] = "Be Quiet!",
    ["making yourself BeQuiet is outside the scope of this addon"] = true,
    ["upgrading profile SV from v%d to v%d"] = true,
    ["Add to Pop-up menu"] = true,
    ["Add BeQuiet to right-click pop-up menu"] = true,
    ["adding BeQuiet to right-click popup menu"] = true,
    ["removing BeQuiet from right-click popup menu"] = true,
} end)

--
-- EOF
