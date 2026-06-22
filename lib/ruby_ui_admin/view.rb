# frozen_string_literal: true

module RubyUIAdmin
  # A small value object for the current view, so user lambdas (`visible:`, action
  # `self.visible`/`self.message`) can write either `view == :show` or `view.show?`.
  # It behaves like its underlying Symbol for comparison.
  class View
    def self.wrap(value)
      value.is_a?(View) ? value : new(value)
    end

    def initialize(name)
      @name = name&.to_sym
    end

    def to_sym = @name
    def to_s = @name.to_s
    def inspect = "#<RubyUIAdmin::View #{@name.inspect}>"

    def index? = @name == :index
    def show? = @name == :show
    def new? = @name == :new
    def edit? = @name == :edit
    def form? = @name == :new || @name == :edit       # new + edit
    def display? = @name == :index || @name == :show   # index + show

    def ==(other)
      other.respond_to?(:to_sym) ? @name == other.to_sym : false
    end
    alias_method :eql?, :==

    def hash = @name.hash
  end
end
