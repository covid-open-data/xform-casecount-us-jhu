# Install all dependencies for the transformer if not already installed.
if ! `apt -qq list r-base 2>/dev/null | grep -qE "(installed|upgradeable)"`; then
  export DEBIAN_FRONTEND=noninteractive

  ln -fs /usr/share/zoneinfo/UTC /etc/localtime
  apt install -y tzdata
  dpkg-reconfigure --frontend noninteractive tzdata

  # Install the `add-apt-repository` utility.
  apt install -y software-properties-common

  add-apt-repository 'deb https://cloud.r-project.org/bin/linux/ubuntu focal-cran40/'
  apt-key adv --keyserver keyserver.ubuntu.com --recv-keys E298A3A825C0D65DFD57CBB651716619E084DAB9
  apt update
  gpg --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys E298A3A825C0D65DFD57CBB651716619E084DAB9
  gpg -a --export E298A3A825C0D65DFD57CBB651716619E084DAB9 | apt-key add -
  apt install -y r-base r-base-core r-recommended r-base-dev
  apt install -y r-cran-tidyverse
fi
