default_storage = "sql"

sql = {
  driver = "SQLite3";
  database = "/app/data/prosody_db.sqlite";
}

archive_store = "archive2" -- Use the same data store as prosody-modules mod_mam

storage = {
  archive2 = "sql";
}

archive_expires_after = "1y"

http_max_content_size = 1024 * 1024 * 100