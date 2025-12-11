local domain = Lua.os.getenv("PROSODY_DOMAIN")
local domain_http_upload = "upload." .. domain
local domain_muc = "muc." .. domain
local domain_proxy = "proxy." .. domain
local domain_pubsub = "pubsub." .. domain

-- XEP-0368: SRV records for XMPP over TLS
-- https://compliance.conversations.im/test/xep0368/
c2s_direct_tls_ssl = {
	certificate = "/app/certs/" .. domain .. "/fullchain.pem";
	key = "/app/certs/" .. domain .. "/privkey.pem";
}
c2s_direct_tls_ports = { 5223 }

-- https://prosody.im/doc/certificates#service_certificates
-- https://prosody.im/doc/ports#ssl_configuration
https_ssl = {
	certificate = "/app/certs/" .. domain_http_upload .. "/fullchain.pem";
	key = "/app/certs/" .. domain_http_upload .. "/privkey.pem";
}

VirtualHost (domain)
disco_items = {
    { domain_http_upload },
}

-- Set up a http file upload because proxy65 is not working in muc
Component (domain_http_upload) "http_file_share"
	http_file_share_expires_after = 60 * 60 * 24 * 30 -- a month in seconds
	local size_limit = 100 * 1024 * 1024
	http_file_share_size_limit = size_limit
	http_file_share_daily_quota = 10 * size_limit

Component (domain_muc) "muc"
	name = domain_muc
	restrict_room_creation = false
	max_history_messages = 20
	modules_enabled = {
		"muc_mam"
	}

-- Set up a SOCKS5 bytestream proxy for server-proxied file transfers
Component (domain_proxy) "proxy65"
	proxy65_address = domain_proxy
	proxy65_acl = { domain }

-- Implements a XEP-0060 pubsub service.
Component (domain_pubsub) "pubsub"