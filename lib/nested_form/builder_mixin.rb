module NestedForm
  module BuilderMixin
    # Adds a link to insert a new associated records. The first argument is the name of the link, the second is the name of the association.
    #
    #   f.link_to_add("Add Task", :tasks)
    #
    # You can pass HTML options in a hash at the end and a block for the content.
    #
    #   <%= f.link_to_add(:tasks, :class => "add_task", :href => new_task_path) do %>
    #     Add Task
    #   <% end %>
    #
    # See the README for more details on where to call this method.
    def link_to_add(*args, &block)
      options = args.extract_options!.symbolize_keys
      association = args.pop
      options[:class] = [options[:class], "add_nested_fields"].compact.join(" ")
      options["data-association"] = association
      args << (options.delete(:href) || "javascript:void(0)")
      args << options
      @fields ||= {}
      @template.after_nested_form(association) do
        model_object = object.class.reflect_on_association(association).klass.new
        blueprint = fields_for(association, model_object, :child_index => "new_#{association}", :wrapper_tag => @fields[association][:wrapper_tag], :wrapper_class => @fields[association][:wrapper_class], &@fields[association][:block])
        blueprint_options = { :type => 'text/html', :id => "#{association}_fields_blueprint" }
        @template.content_tag(:script, blueprint, blueprint_options)
      end
      @template.link_to(*args, &block)
    end

    # Adds a link to remove the associated record. The first argment is the name of the link.
    #
    #   f.link_to_remove("Remove Task")
    #
    # You can pass HTML options in a hash at the end and a block for the content.
    #
    #   <%= f.link_to_remove(:class => "remove_task", :href => "#") do %>
    #     Remove Task
    #   <% end %>
    #
    # See the README for more details on where to call this method.
    def link_to_remove(*args, &block)
      options = args.extract_options!.symbolize_keys
      options[:class] = [options[:class], "remove_nested_fields"].compact.join(" ")
      args << (options.delete(:href) || "javascript:void(0)")
      args << options
      (hidden_field(:_destroy) << @template.link_to(*args, &block)).html_safe
    end

    def fields_for_with_nested_attributes(association_name, *args)
      # TODO Test this better
      block = args.pop || Proc.new { |fields| @template.render(:partial => "#{association_name.to_s.singularize}_fields", :locals => {:f => fields}) }

      convert = false
      if Gem::Version.new(Rails::VERSION::STRING) < Gem::Version.new("3.1.0") # 3.0.x
        options = args[0].extract_options!
        convert = true
      else # >= 3.1.0
        options = args.extract_options!
      end

      options[:wrapper_tag] ||= 'div'
      options[:wrapper_class] = ' ' << options[:wrapper_class] if options[:wrapper_class]

      if convert
        args[0] << options
      else
        args << options
      end

      @fields ||= {}
      @fields[association_name] = { :block => block, :wrapper_tag => options[:wrapper_tag], :wrapper_class => options[:wrapper_class] }
      super(association_name, *(args << block))
    end

    def fields_for_nested_model(name, object, options, block)
      @template.content_tag(options[:wrapper_tag], super, :class => "fields#{options[:wrapper_class]}")
    end
  end
end
