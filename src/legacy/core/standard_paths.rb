module JABA
  def self.jaba_docs_url = 'https://jabamaus.github.io/jaba'
  def self.install_dir = @@jaba_install_dir ||= "#{__dir__}/../..".cleanpath
  def self.modules_dir = "#{install_dir}/src/modules"
  def self.grab_bag_dir = "#{install_dir}/src/grab_bag"
  def self.examples_dir = "#{install_dir}/examples"
end
