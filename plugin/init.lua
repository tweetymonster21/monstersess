local sess = require "monstersess"

if sess.sessionExists then
    sess:loadSession()
    sess:scheduleSaveSessionBeforeExit()
end
