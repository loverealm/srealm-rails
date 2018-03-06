require 'spec_helper'
require 'active_support'
require 'active_support/core_ext'
require './lib/ext/string'
describe String do
  it "Check integer text" do
    expect('12345'.is_i?).to eq(true)
    expect('12345no'.is_i?).to eq(false)
    expect('12345.123'.is_i?).to eq(false)
  end
  
  it 'Check strip dangerous tags' do
    str1 = '<p>asa <a>lik nere</a> and <span class=\'abc\' onclick="alert(\'asasa\')">span here</span> and <a href="abc" target="aaa">pending ass here</p>'
    expect(str1.strip_dangerous_html_tags).to eq("<p>asa <a>lik nere</a> and <span>span here</span> and <a href=\"abc\" target=\"aaa\">pending ass here</a></p>")
    expect('<script>alert("hello world")</script> test'.strip_dangerous_html_tags).to eq("alert(\"hello world\") test")
    str2 = '<blockquote>Exodus (4: 1-3)<footer>1) Moses answered..</footer></blockquote>'
    expect(str2.strip_dangerous_html_tags).to eq(str2)
    str1.is_safe_string = true
    expect(str1.strip_dangerous_html_tags).to eq(str1)
    str3 = "<a href='aa.com' target='_blank'><img src='https://camo.githubusercontent.com/4470f.png'></a>"
    expect(str3.strip_dangerous_html_tags).to eq("<a href=\"aa.com\" target=\"_blank\"><img src=\"https://camo.githubusercontent.com/4470f.png\"></a>")
  end
end