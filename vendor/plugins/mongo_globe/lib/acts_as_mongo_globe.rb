# MongoGlobe
module MongoMapper
  module Acts
    module MongoGlobe
      
      def self.included(base)
        base.extend GlobeClassMethods
      end
      
      module GlobeClassMethods
        def acts_as_mongo_globe(options = {})
          include MongoMapper::Acts::MongoGlobe::GlobeInstanceMethods
          extend MongoMapper::Acts::MongoGlobe::GlobeSingletonMethods
          
          alias_method_chain :to_json, :linked_details
          class << self
            alias_method_chain :many, :auto_extensions
          end
        end
        
        
      end
      
      module GlobeInstanceMethods
        def parent_index
          self._parent_document.send("#{self.class.to_s.underscore.pluralize}").each_with_index do |_object, index|
            return index if _object == self
          end
        end
        
        def hierarchy
          h = []
          _object = self
          while (_object.respond_to?(:_parent_document)) 
            h << _object.class.to_s.underscore.pluralize
            h << _object.parent_index.to_s
            _object = _object._parent_document.class
          end
          h
        end
        
        def hierarchy_string
          hierarchy.join(".")
        end
        
        def atomic_set(field, value)
          # do an atomic update, and also update our current version of the class to reflect the atomic update
          self._root_document.set(hierarchy_string + ".#{field}" => value)
          self.send("#{field}=".to_sym, value)
        end
        
        def atomic_push(field, value)
          self._root_document.push(hierarchy_string + ".#{field}" => JSON.parse(value.to_json))
          self.send("#{field}".to_sym).send(:<<, value)
        end
        
        def atomic_pull(field, value)
          self._root_document.pull(hierarchy_string + ".#{field}" => JSON.parse(value.to_json))
          self.send("#{field}".to_sym).send(:delete, value)
        end
        
        def to_json_with_linked_details(*args)   
            object_hash = deep_belongs_to
            
            json = self.to_json_without_linked_details
            
            object_hash.each_pair do |key, value|
              json.gsub!("\"#{value.class.to_s.downcase}_id\":\"#{key}\"","\"#{value.class.to_s.downcase}\":#{value.to_json},\"#{value.class.to_s.downcase}_id\":\"#{key}\"")
            end
            
            json
        end
        
        def deep_belongs_to
          object_hash = {}
          
          belongs_to_objects.each do |belongs_to_object|
            object_hash[belongs_to_object.id.to_s] = belongs_to_object
          end
          many_objects.each do |many_object|
            object_hash.merge!(many_object.deep_belongs_to)
          end
          
          return object_hash
        end
        
        def many_associations
          self.associations.select do |association, association_object|
            association_object.type == :many
          end
        end
        
        def many_objects
          many_associations.collect do |many_association|
            self.send(many_association.first.to_sym)
          end.flatten
        end
        
        def belongs_to_associations 
          self.associations.select do |association, association_object|
            association_object.type == :belongs_to
          end
        end
        
        def belongs_to_objects
          belongs_to_associations.collect do |belongs_to_association|
             self.send(belongs_to_association.first.to_sym)
          end.flatten
        end
      end
      
      module GlobeSingletonMethods
        def many_with_auto_extensions(association_id, options={}, &extension) 
     
          many_without_auto_extensions(association_id, options={}, &extension)
          # many does not return the association object, so we have to fetch
          
          association = associations.fetch(association_id)
          
          # if there are no associations already we need to create the proxy module
          association.options[:extend] = [Module.new] if association.options[:extend].first.nil?

          association.options[:extend].first.send(:define_method, "find_by_#{association_id.to_s[0, association_id.to_s.length - 1]}_id".to_sym) do |_id|
              self.detect {|_object| _object.id.to_s == _id.to_s}
          end 
          
        end
        
        def many_relationship?(_relationship)
          !keys.keys.include?(_relationship.to_s) && associations.fetch(_relationship).type == :many
        end
        
        def atomicize(field, options = {})
          field.is_a?(Array) ? field.each {|f| _atomicize(f, options)} : _atomicize(field, options)
        end
        
        private
        
        def _atomicize(field, options = {})
          if many_relationship?(field)
            define_method("#{field}_include") do |_field|
              atomic_push(field, _field)
            end
            define_method("#{field}_exclude") do |_field|
              atomic_pull(field, _field)
            end
          else
            define_method("#{field}_is") do |_field|
              atomic_set(field, _field)
            end
          end
        end
        
      end
      
    end
  end
end