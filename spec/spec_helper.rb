require 'pathname'
require 'spec'
require 'dm-core'
require 'dm-mongo-adapter'
#require 'dm-annoing-modificators'

MONGO_SPEC_ROOT = Pathname(__FILE__).dirname.expand_path
$LOAD_PATH.unshift(MONGO_SPEC_ROOT.parent.join('lib').to_s)

Pathname.glob((MONGO_SPEC_ROOT + 'lib/**/*.rb').to_s).each { |file| require file }
Pathname.glob((MONGO_SPEC_ROOT + '**/shared/**/*.rb').to_s).each { |file| require file }

# Define the repositories used by the specs. Override the defaults by
# supplying ENV['DEFAULT_SPEC_URI'] or ENV['AUTH_SPEC_URI'].

module DataMapper::Model
  def create_or_raise(*args)
    resource = create(*args)
    unless resource
      raise("failed to create resource")
    end
    resource
  end
end


Spec::Runner.configure do |config|
  config.include DataMapper::Mongo::Spec::CleanupModels
  config.include DataMapper::Mongo::Spec::ResetHelper
  config.include DataMapper::Mongo::Spec::ProcessHelper
  config.include DataMapper::Mongo::Spec::ConnectionHelper
  config.include DataMapper::Mongo::Spec::ReplicaSetHelper
  config.include DataMapper::Mongo::Spec::MongodHelper
  config.extend  DataMapper::Mongo::Spec::ConnectionManagement
  config.extend  DataMapper::Mongo::Spec::ReplicaSetManagement

  config.before :all do
    cleanup_models *DataMapper::Model.descendants.to_a
  end
end
