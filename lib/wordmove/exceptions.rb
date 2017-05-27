module Wordmove
  class UndefinedEnvironment < StandardError; end
  class NoAdapterFound < StandardError; end
  class MovefileNotFound < StandardError; end
  class ShellCommandError < StandardError; end
  class UnmetPeerDependencyError < StandardError; end
end
