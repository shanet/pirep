pirep
=====

## Development Setup

If Postgres is not already installed:

```
sudo su - postgres -c "initdb --locale en_US.UTF-8 -D '/var/lib/postgres/data'"
sudo systemctl start postgresql
```

```
bundle install
yarn install
sudo -u postgres createuser --createdb `whoami`
rails db:create
rails db:migrate
rails s
```

