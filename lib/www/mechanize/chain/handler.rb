module WWW
  module Handler
    attr_accessor :chain

    def handle(ctx, request)
      chain.pass(self, request)
    end
  end
end
