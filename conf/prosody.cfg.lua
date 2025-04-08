local adminJid = os.getenv("PROSODY_ADMIN");
if (adminJid ~= nil) then
    admins = { adminJid }
end

pidfile = "/app/prosody.pid";
allow_registration = os.getenv("PROSODY_ALLOW_REGISTRATION") == "true";
c2s_require_encryption = true;
s2s_require_encryption = true;
s2s_secure_auth = true
authentication = "internal_hashed"
data_path = "/app/data"
certificates = "/app/certs"
log = {
    {levels = {min = "info"}, to = "console"};
};
-- limits = {
--     c2s = {
--         rate = "3kb/s";
--         burst = "2s";
--     };
--     s2sin = {
--         rate = "30kb/s";
--         burst = "3s";
--     };
-- }

interfaces = { "0.0.0.0" };

Include "conf.d/*.cfg.lua"
