# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random, 
# no regular words or you'll be exposed to dictionary attacks.
ActionController::Base.session = {
  :key         => '_MongoGlobe_session',
  :secret      => '2e08c969b59b884fd89b3b49fa5cdf908c06583950e43e729d0dc9d19bb964b9ec3daf379ad42e6f4e496140a7947fea865bcbb4228e8ecacd80351504813baf'
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
# ActionController::Base.session_store = :active_record_store
