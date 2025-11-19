require 'testup/testcase'
require_relative '../../src/parametric/tools/staged'

class TC_Staged < TestUp::TestCase
  class Multistage
    include Parametric::Tools::Staged

    staged_methods :perform

    def next_stage(stage)
      super
    end

    def undo(*params)
      super *params
    end
  end

  def new_step(name, **methods)
    step = Minitest::Mock.new
    methods.each do |method, params|
      step.expect method, "#{name}\##{method}", params || []
    end
    step
  end

  def test_stages
    subject = Multistage.new
    step1 = new_step 'step_1', perform: ['foo'], undo: ['bar']
    step2 = new_step 'step_2', perform: nil, undo: nil
    subject.next_stage step1
    assert_equal 'step_1#perform', subject.perform('foo')
    subject.next_stage step2
    assert_equal 'step_2#perform', subject.perform
    subject.next_stage 'step_3'
    assert_equal 'step_2#undo', subject.undo
    step2.expect :undo, nil, ['bar'] # all changes have been undone
    assert_equal 'step_1#undo', subject.undo('bar')
    assert step1.verify 
    assert step2.verify
  end

  def test_stage_callback
    subject = Multistage.new
    step = MiniTest::Mock.new
    step.expect :activate, true
    subject.next_stage step
    assert step.verify
    step.expect :deactivate, true
    step.expect :reset, true
    subject.undo
    assert step.verify
  end
end
