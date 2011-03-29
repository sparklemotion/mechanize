class Mechanize::Chain::PreConnectHook
  include Mechanize::Handler

  attr_accessor :hooks

  def initialize
    @hooks = []
  end

  def handle(ctx, params)
    @hooks.each { |hook| hook.call(params) }
    super
  end
end

class Mechanize::Chain::PostConnectHook < Mechanize::Chain::PreConnectHook
end

