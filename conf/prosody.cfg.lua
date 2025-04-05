admins = { os.getenv("PROSODY_ADMIN") }
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

interfaces = { "0.0.0.0" };

Include "conf.d/*.cfg.lua"
