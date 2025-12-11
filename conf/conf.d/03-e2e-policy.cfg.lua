e2e_policy_chat = Lua.os.getenv("PROSODY_E2E_ENCRYPTION_REQUIRED") == "true" and "required" or "optional"
e2e_policy_muc = Lua.os.getenv("PROSODY_E2E_ENCRYPTION_REQUIRED") == "true" and "required" or "optional"

e2e_policy_whitelist = Lua.os.getenv("PROSODY_E2E_ENCRYPTION_WHITELIST")

e2e_policy_message_optional_chat = "For security reasons, OMEMO, OTR or PGP encryption is STRONGLY recommended for conversations on this server."
e2e_policy_message_required_chat = "For security reasons, OMEMO, OTR or PGP encryption is required for conversations on this server."
e2e_policy_message_optional_muc = "For security reasons, OMEMO, OTR or PGP encryption is STRONGLY recommended for MUC on this server."
e2e_policy_message_required_muc = "For security reasons, OMEMO, OTR or PGP encryption is required for MUC on this server."