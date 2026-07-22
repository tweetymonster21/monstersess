--- @class M
--- @field pattern string Pattern to listen in autocmds
--- @field sessionExists boolean True if a session exists. Is set when a session is found on startup or if the user created a new session
--- @field shouldSaveOnExit boolean Controls whether the session will be saved when exitting nvim
--- @field runBeforeExit fun()[] Array of function that are run before saving the session and
--- exitting
---
local M = {
    pattern = "",
    sessionExists = false,
    shouldSaveOnExit = false,
    runBeforeExit = {}
}
M.__index = M

--- @class defaults
--- @field sessionBasePath string
--- @field sessionDir string
--- @field sessionPath string The full path to Session.vim
local config = {
    sessionBasePath = vim.fn.expand('~/.local/share/nvim/sessions'),
    sessionDir = '',
    sessionPath = '',
}

function M:setup(opts)
    vim.tbl_deep_extend("force", config, opts or {})
    config.sessionDir = vim.fs.joinpath(config.sessionBasePath, vim.fn.getcwd())
    config.sessionPath = vim.fs.joinpath(config.sessionDir, "Session.vim")

    self.sessionExists = vim.fn.filereadable(config.sessionPath) == 1
    self.shouldSaveOnExit = self.sessionExists
    self.pattern = 'Monstersession'

    if M.sessionExists then
        M:loadSession()
        M:scheduleSaveSessionBeforeExit()
    end
end

function M:notify()
    vim.api.nvim_exec_autocmds('User', { pattern = self.pattern })
end

function M:createSessionDir()
    vim.fn.mkdir(config.sessionDir, "p")
end

--- Creates and save a new session for the opened project
function M:createSession()
    self:createSessionDir()
    self:scheduleSaveSessionBeforeExit()
    self.shouldSaveOnExit = true
    self:saveSession()
    print("Session created")
end

function M:saveSession()
    vim.cmd("mksession! " .. config.sessionPath)
    self.sessionExists = true
    self:notify()
    print("Session saved")
end

function M:saveOrCreateSession()
    if not self.sessionExists then
        self:createSession()
    else
        self:saveSession()
    end
end

function M:loadSession()
    vim.cmd("so " .. config.sessionPath)
    print("Session loaded")
end

function M:deleteSession()
    if self.sessionExists then
        vim.fs.rm(config.sessionDir, { force = true, recursive = true })
        self.sessionExists = false
        self.shouldSaveOnExit = false
        self:notify()
        print("Session deleted")
    else
        print("No session found")
    end
end

--- Add a function to run before the session saves when exitting vim
--- @param f fun()
function M:addBeforeExit(f)
    table.insert(self.runBeforeExit, f)
end

--- Register an autocmd to save the current state of the session before exiting vim
function M:scheduleSaveSessionBeforeExit()
    vim.api.nvim_create_autocmd("ExitPre", {
        group = vim.api.nvim_create_augroup('monsterpoon/session/save_before_exit', { clear = true }),
        desc = "Save the session before quitting neovim",
        callback = function()
            if self.shouldSaveOnExit then
                M:saveSession()
            end
        end
    })
end

return M
