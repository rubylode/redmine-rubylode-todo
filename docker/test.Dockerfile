# Redmine 7 with its test gems, to run the plugin's tests. The stock image leaves them out.
# The Gemfile picks the database gem from config/database.yml, so the file has to exist before the install.
FROM redmine:7.0.2
RUN cd /usr/src/redmine \
 && printf 'test:\n  adapter: sqlite3\n  database: /tmp/redmine_test.sqlite3\n' > config/database.yml \
 && bundle config set --local without development \
 && bundle install
