lock '3.3.5'
set :application, 'depot'
set :use_sudo, true
set :repo_url, 'git@github.com:Shruti2791/depot.git'

set :deploy_to, '/var/www/apps/depot'
set :deploy_via, :remote_cache
set :format, :pretty
set :keep_releases, 15

set :linked_files, %w{config/database.yml }
set :linked_dirs, %w{bin log tmp/pids tmp/cache tmp/sockets vendor/bundle public/system public/assets}

SSHKit.config.command_map[:rake]  = "bundle exec rake"
SSHKit.config.command_map[:rails] = "bundle exec rails"

namespace :deploy do

  desc 'Restart application'
  task :restart do
    on roles(:web), in: :parallel do
      within current_path do
        with rails_env: fetch(:rails_env) do
          Rake::Task[:'unicorn:hard_restart'].invoke
          Rake::Task[:'database:create'].invoke
        end
      end
    end
  end

  after :finishing, 'deploy:cleanup'
  after :publishing, 'deploy:restart'
end

namespace :database do
  desc 'create database'
  task :create do
    on roles(:db), in: :parallel do
      within current_path do
        with rails_env: fetch(:rails_env) do
          execute :bundle, :exec, :rake, 'db:create'
        end
      end
    end
  end

  desc 'migrate'
  task :migrate do
    on roles(:db), in: :parallel do
      within current_path do
        with rails_env: fetch(:rails_env) do
          execute :bundle, :exec, :rake, 'db:migrate'
        end
      end
    end
  end

  desc 'seed'
  task :seed do
    on roles(:db), in: :parallel do
      within current_path do
        with rails_env: fetch(:rails_env) do
          execute :bundle, :exec, :rake, 'db:seed'
        end
      end
    end
  end
end

namespace :unicorn do
  task :hard_restart do
    Rake::Task[:'unicorn:stop'].invoke
    Rake::Task[:'unicorn:start'].invoke
  end

  desc 'start unicorn'
  task :start do
    on roles(:app), in: :parallel do
      within current_path do
        execute :bundle, :exec, "unicorn_rails -c config/unicorn.rb -D -E #{ fetch(:rails_env) }"
      end
    end
  end

  desc 'stop unicorn'
  task :stop do
    on roles(:app), in: :parallel do
      within current_path do
        with rails_env: fetch(:rails_env) do
          execute :bundle, :exec, "kill -s QUIT `cat #{shared_path}/tmp/pids/unicorn.pid`"
        end
      end
    end
  end

  desc 'restart unicorn'
  task :restart do
    on roles(:app), in: :parallel do
      within current_path do
        execute "kill -s USR2 `cat #{shared_path}/tmp/pids/unicorn.pid`"
      end
    end
  end
end

