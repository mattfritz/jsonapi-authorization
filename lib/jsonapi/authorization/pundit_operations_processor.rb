require 'pundit'

module JSONAPI
  module Authorization
    class PunditOperationsProcessor < ::ActiveRecordOperationsProcessor
      set_callback :find_operation, :before, :authorize_find
      set_callback :show_operation, :before, :authorize_show
      set_callback :create_resource_operation, :before, :authorize_create_resource
      set_callback :replace_fields_operation, :before, :authorize_replace_fields

      def authorize_find
        ::Pundit.authorize(pundit_user, @operation.resource_klass._model_class, 'index?')
      end

      def authorize_show
        record = @operation.resource_klass.find_by_key(
          operation_resource_id,
          context: @operation.options[:context]
        )._model

        ::Pundit.authorize(pundit_user, record, 'show?')
      end

      def authorize_replace_fields
        source_record = @operation.resource_klass.find_by_key(
          @operation.resource_id,
          context: @operation.options[:context]
        )._model

        ::Pundit.authorize(pundit_user, source_record, 'update?')

        related_models.each do |rel_model|
          ::Pundit.authorize(pundit_user, rel_model, 'update?')
        end
      end

      def authorize_create_resource
        ::Pundit.authorize(pundit_user, @operation.resource_klass._model_class, 'create?')

        related_models.each do |rel_model|
          ::Pundit.authorize(pundit_user, rel_model, 'update?')
        end
      end

      private

      def pundit_user
        @operation.options[:context][:user]
      end

      # TODO: Communicate with upstream to fix this nasty hack
      def operation_resource_id
        case @operation
        when JSONAPI::ShowOperation
          @operation.id
        else
          @operation.resource_id
        end
      end

      def model_class_for_relationship(assoc_name)
        @operation.resource_klass._relationships[assoc_name].resource_klass._model_class
      end

      def related_models
        data = @operation.options[:data]
        return [] if data.nil?

        [:to_one, :to_many].flat_map do |rel_type|
          data[rel_type].flat_map do |assoc_name, assoc_ids|
            assoc_klass = model_class_for_relationship(assoc_name)
            assoc_klass.find(assoc_ids)
          end
        end
      end
    end
  end
end