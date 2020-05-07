# Install all dependencies for the transformer if not already installed.
if ! `apt -qq list r-base 2>/dev/null | grep -qE "(installed|upgradeable)"`; then
  export DEBIAN_FRONTEND=noninteractive
  apt-get update

  apt-get install -y software-properties-common
  apt-get install -y dirmngr --install-recommends
  apt-get install -y apt-transport-https

  echo "Installing R..."
  apt-key adv --keyserver keys.gnupg.net --recv-key 'E19F5F87128899B192B1A2C2AD5F960A256A04AF' --no-tty
  add-apt-repository 'deb http://cloud.r-project.org/bin/linux/debian buster-cran35/'
  apt-get update
  apt-get install -y r-base r-base-core r-base-dev r-recommended
  apt-get install -y r-cran-tidyverse

  R --version
fi
