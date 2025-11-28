require 'testup/testcase'
require_relative '../../src/parametric/tools/tool_socket'

class Parametric::Tools::TC_ToolSocket < TestUp::TestCase

  attr_reader :subject

  def setup
    @subject = Parametric::Tools::ToolSocket.new
  end

  def teardown
    Sketchup.active_model.select_tool nil
  end

  def mock_tool
    Minitest::Mock.new
  end

  def test_tool_workflow
    view = Sketchup.active_model.active_view
    tool = mock_tool
    subject.select_tool tool
    assert tool.verify, 'tool will not be activated if the socket is not connected'
    tool.expect :activate, nil
    Sketchup.active_model.select_tool subject
    assert tool.verify, 'tool is activated when the socket is connected'
    tool.expect :deactivate, nil, [view]
    new_tool = mock_tool.expect(:activate, nil)
    subject.select_tool new_tool
    assert tool.verify, 'tool is deactivated when the another tool selected'
    assert new_tool.verify, "tool is activated when it's selected"
    new_tool.expect :deactivate, nil, [view]
    Sketchup.active_model.select_tool nil
    assert new_tool.verify, 'tool weel be deactivated when the socket disconneing'
    tool = mock_tool
    subject.select_tool tool
    assert tool.verify, "disconnected socket is'nt active"
  end
end
