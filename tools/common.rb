require_relative '../src2/jaba'

module CommonUtils
  JABA_REPO_URL = "https://github.com/jabamaus/jaba.git"

  def self.git_cmd(cmd)
    puts cmd
    system("git #{cmd}")
    puts 'Done!'
  end

end