module ForgeHelper

  def has_content?(name)
  (@has_content && @has_content[name]) || false
  end
  # Display a link to user's account page with IMAGE
  def link_to_user_with_image(user, size=0)
    if user
      completeLink = output_user_image user, size
      completeLink << link_to(user, :controller => 'users', :action => 'show', :id => user)
      if size == 1
        completeLink << " (#{user.login})"
      end
      completeLink  # return it
    else
      'Anonymous'
    end
  end

# output the user image
 def output_user_image(user, size=0)
   imageSizeHash = {0 => 18, 1 => 30, 2 => 140}
   avatar(user, :size => imageSizeHash[size]).to_s
 end

  def create_repository package_key, force_review, git_base_path
    # Add Repository to project
    @repository = Repository.factory(:Git)
    @repository.project = @project

    repo_path = Setting.plugin_forger_typo3['own_projects_version4_base_directory'] + package_key + ".git"
    @repository.url = 'file://' + repo_path
    @repository.save

    logger.info "Setting up Git repository in #{repo_path}"
    custom_system 'git init --bare ' + repo_path
    git_server_url = Setting.plugin_forger_typo3['own_projects_git_base_url'] + Setting.plugin_forger_typo3['own_projects_version4_git_base_path'] + package_key + '.git'

    # Write into MQ
    amqp_config = YAML.load_file("config/amqp.yml")["amqp"]

    logger.info "Read AMQP config, connecting to amqp://#{amqp_config["username"]}@#{amqp_config["host"]}:#{amqp_config["port"]}/#{amqp_config["vhost"]}"

    bunny = Bunny.new(:host  => amqp_config["host"],
                      :port  => amqp_config["port"],
                      :user  => amqp_config["username"],
                      :pass  => amqp_config["password"],
                      :vhost => amqp_config["vhost"])
    bunny.start

    logger.info "Connected to #{amqp_config["host"]}"

    channel_name = "org.typo3.forge.repo.git.create"

    logger.info "Creating channel #{channel_name}"
    channel = bunny.create_channel

    logger.info "Connecting to exchange #{channel_name}"
    exchange = channel.fanout(channel_name, :durable => true)

    message_data = {
        :event  =>  "project_created",
        :project => package_key,
        :project_path => git_base_path,
        :force_review => force_review
    }

    message_metadata = {
        :routing_key => channel_name,
        :persistent => true,
        :mandatory => true,
        :content_type => "application/json",
        :user_id => amqp_config["username"],
        :app_id => "redmine on #{request.host}"
    }

    logger.info "Trying to publish message: #{message_data.to_json} with metadata: #{message_metadata.to_json}"

    exchange.publish(message_data.to_json, message_metadata)

    logger.info "Message published"

    bunny.stop
  end
end
