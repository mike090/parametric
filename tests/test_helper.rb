require 'testup/testcase'
require 'minitest/spec'

Minitest::Spec::DSL.alias_method :inspect, :name

module Parametric
  module Spec
    module DSL
      module ContextContainer
        def describe(object = 'anonymous', &block)
          context "#{object} description", "TestCaseDescription", &block
        end

        def context(description, name = 'TestCaseContext', &block)
          clear_tests if tests_root? # возможно временное. Связано с изменением имен тестов при загрузке (load) файлов тестов 
          parent_context = describe_stack.last
          describe_stack << create_context("#{name}<#{description}>", description, parent_context)
          describe_stack.last.instance_eval &block
          describe_stack.pop
        rescue StandardError
          describe_stack.clear
        end

        private

        def tests_root?
          !describe_stack.last
        end

        def describe_stack
          Minitest::Spec.describe_stack
        end

        def create_context(name, desc, parent_context)
          class_methods = create_class_methods parent_context&.class_methods, desc
          Module.new do
            extend Context, ContextContainer
            include parent_context if parent_context

            class << self
              attr_reader :class_methods
            end

            @name = name
            @class_methods = class_methods
          end
        end

        def create_class_methods(parent, desc)
          if parent
            Module.new do  
              include parent

              define_method(:context_description) { (super() || []) << desc }
            end
          else
            tests_container = self
            Module.new do
              define_method(:container) { tests_container }
              define_method(:context_description) { [desc] }
            end
          end
        end    
      end

      module Context
        include Minitest::Spec::DSL, ContextContainer
        
        def it(desc = nil, &block)
          block ||= proc { skip "(no tests defined)" }
          method_name = test_method_name(desc)
          test_case.define_method method_name, &block
          method_name
        end

        alias_method :test, :it

        def test_helpers(*helpers)
          current_context.include *helpers
        end

        def test_case_name(name)
          @test_case_name = name
        end

        private

        def test_method_name(desc)
          if desc
            desc.split.unshift('test').join('_')
          else
            @tests_counter ||= 0
            @tests_counter += 1
            "anonymous_test_%04d" % [ @tests_counter]
          end
        end

        def current_context
          describe_stack.last
        end

        def test_case
          @test_case ||= create_test_case
        end

        def create_test_case
          context = describe_stack.last
          test = Class.new(TestUp::TestCase) do
            extend context.class_methods
            include context, Minitest::Spec::DSL::InstanceMethods
          end
          test.container.add_test_case test, @test_case_name
        end
      end
    end

    module TestsContainer
      def add_test_case(test_case, const_name)
        const_name ||= new_test_name
        self.const_set const_name, test_case
      end

      def clear_tests
        tests = constants(false).grep(/TC_/)
        tests.each do |test|
          Minitest::Runnable.runnables.delete const_get(test, false)
          remove_const(test)
        end
        @tests_counter = 0
        tests
      end

      private

      def new_test_name
        @tests_counter ||= 0
        @tests_counter += 1
        "TC_%04d" % [@tests_counter]
      end
    end

    module TestsRoot
      include TestsContainer, DSL::ContextContainer
    end
  end
end
