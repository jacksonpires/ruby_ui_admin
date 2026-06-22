# frozen_string_literal: true

module RubyUIAdmin
  # Evaluates a value that may be a literal or a Proc. When it's a Proc, it's
  # instance_exec'd with all the passed keyword arguments available as readers.
  #
  #   ExecutionContext.new(target: -> { record.name }, record: post).handle
  class ExecutionContext
    def initialize(**args)
      @target = args.delete(:target)
      # When present, unknown methods (view/url helpers like `link_to`, `main_app`,
      # `*_path`) are delegated to this Rails view context inside the block.
      @view_context = args.delete(:view_context)
      @args = args
      args.each do |key, value|
        define_singleton_method(key) { value }
      end
    end

    def handle
      return @target unless @target.respond_to?(:call)

      instance_exec(&@target)
    end

    def method_missing(name, *args, **kwargs, &block)
      return super unless @view_context.respond_to?(name)

      @view_context.public_send(name, *args, **kwargs, &block)
    end

    def respond_to_missing?(name, include_private = false)
      (@view_context&.respond_to?(name)) || super
    end
  end
end
