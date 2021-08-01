module JABA

  using JABACoreExt

  ##
  #
  def self.jaba_docs_url
    'https://jabamaus.github.io/jaba'
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
