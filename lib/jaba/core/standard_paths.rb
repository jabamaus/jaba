module JABA

  using JABACoreExt

  ##
  #
  def self.jaba_repo_url
    'https://github.com/jabamaus/jaba.git'
  end
  
  ##
  #
  def self.install_dir
    @@jaba_install_dir ||= "#{__dir__}/../../..".cleanpath
  end

  ##
  #
  def self.modules_dir
    "#{install_dir}/modules"
  end

  ##
  #
  def self.examples_dir
    "#{install_dir}/examples"
  end

end
