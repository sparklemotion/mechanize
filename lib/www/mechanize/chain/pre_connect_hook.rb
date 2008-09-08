module WWW
  class Mechanize
    class Chain
      class PreConnectHook
        include WWW::Handler

        attr_accessor :hooks
        def initialize
          @hooks = []
        end

        def handle(ctx, params)
          @hooks.each { |hook| hook.call(params) }
          super
        end
      end

      class PostConnectHook < PreConnectHook
      end
    end
  end
end
