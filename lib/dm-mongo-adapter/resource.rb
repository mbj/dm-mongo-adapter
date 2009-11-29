module DataMapper
  module Mongo
    module Resource
      def self.included(base)
        DataMapper::Model.append_extensions(ModelMethods)
        
        base.send(:include, DataMapper::Resource) unless base.kind_of?(DataMapper::Resource)
        base.send(:include, DataMapper::Mongo::Types)
      end

      private
      
      # @api private
      def embedments
        model.embedments
      end

      module ModelMethods
        # @overrides DataMapper::Model#load
        def load(records, query)
          repository      = query.repository
          repository_name = repository.name
          fields          = query.fields
          discriminator   = properties(repository_name).discriminator
          no_reload       = !query.reload?

          field_map = fields.map { |property| [ property, property.field ] }.to_hash

          records.map do |record|
            identity_map = nil
            key_values   = nil
            resource     = nil

            case record
            when Hash
              # remap fields to use the Property object
              record = record.dup
              field_map.each { |property, field| record[property] = record.delete(field) if record.key?(field) }

              model     = discriminator && record[discriminator] || self
              model_key = model.key(repository_name)

              resource = if model_key.valid?(key_values = record.values_at(*model_key))
                identity_map = repository.identity_map(model)
                identity_map[key_values]
              end

              resource ||= model.allocate

              # Load embedded resources
              model.embedments.each do |name, relationship|
                relationship.set(resource, relationship.child_model.new(record[name.to_s]))
              end

              fields.each do |property|
                next if no_reload && property.loaded?(resource)

                value = record[property]

                # TODO: typecasting should happen inside the Adapter
                # and all values should come back as expected objects
                if property.custom?
                  value = property.type.load(value, property)
                end

                property.set!(resource, value)
              end

            when Resource
              model     = record.model
              model_key = model.key(repository_name)

              resource = if model_key.valid?(key_values = record.key)
                identity_map = repository.identity_map(model)
                identity_map[key_values]
              end

              resource ||= model.allocate

              fields.each do |property|
                next if no_reload && property.loaded?(resource)

                property.set!(resource, property.get!(record))
              end
            end

            resource.instance_variable_set(:@_repository, repository)
            resource.instance_variable_set(:@_saved,      true)

            if identity_map
              # defer setting the IdentityMap so second level caches can
              # record the state of the resource after loaded
              identity_map[key_values] = resource
            else
              resource.instance_variable_set(:@_readonly, true)
            end

            resource
          end
        end
      end
    end
  end
end
