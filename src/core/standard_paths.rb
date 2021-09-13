module JABA

  ##
  #
  def self.jaba_docs_url
    'https://jabamaus.github.io/jaba'
  end
  
  ##
  #
  def self.install_dir
    @@jaba_install_dir ||= "#{__dir__}/../..".cleanpath
  end

  ##
  #
  def self.modules_dir
    "#{install_dir}/src/modules"
  end

  ##
  #
  def self.grab_bag_dir
    "#{install_dir}/src/grab_bag"
  end

  ##
  #
  def self.examples_dir
    "#{install_dir}/examples"
  end

end
