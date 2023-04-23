module JABA
  module OS
    def self.windows? = true
    def self.mac? = false
  end

  @@running_tests = false
  def self.running_tests! = @@running_tests = true
  def self.running_tests? = @@running_tests

  def self.error(msg, errobj: nil, want_err_line: true, want_backtrace: true, backtrace: nil)
    msg = msg.ensure_end_with(".") if msg =~ /[a-zA-Z0-9']$/
    e = JabaError.new(msg)
    if errobj.proc?
      backtrace = "#{errobj.source_location[0]}:#{errobj.source_location[1]}"
      errobj = nil
    end
    bt = Array(errobj&.src_loc || backtrace || caller).map(&:to_s)
    e.set_backtrace(bt)
    e.instance_variable_set(:@want_backtrace, want_backtrace)
    e.instance_variable_set(:@want_err_line, want_err_line)
    raise e
  end

  def self.warn(...) = JABA.context.warn(...)
  def self.log(...) = JABA.context.log(...)
end
