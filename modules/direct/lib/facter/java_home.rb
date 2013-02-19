require 'facter'
Facter.add(:JAVA_HOME) do
  setcode do
    Facter::Util::Resolution::exec("readlink -f `which javac` | sed 's:/bin/javac::'")
  end
end
