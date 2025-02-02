# frozen_string_literal: true

require 'spec_helper'
require 'cucumber/cucumber_expressions/parameter_type_registry'
require 'cucumber/cucumber_expressions/parameter_type'
require 'cucumber/cucumber_expressions/cucumber_expression_generator'
require 'cucumber/glue/snippet'
require 'cucumber/formatter/console'

module Cucumber
  module Glue
    describe Snippet do
      include Cucumber::Formatter::Console
      let(:code_keyword) { 'Given' }
      let(:snippet) do
        snippet_class.new(@cucumber_expression_generator, code_keyword, @step_text, @multiline_argument)
      end

      before do
        @step_text = 'we have a missing step'
        @multiline_argument = Core::Test::EmptyMultilineArgument.new
        @registry = CucumberExpressions::ParameterTypeRegistry.new
        @cucumber_expression_generator = CucumberExpressions::CucumberExpressionGenerator.new(@registry)
      end

      describe Snippet::Regexp do
        let(:snippet_class) { described_class }
        let(:snippet_text) { snippet.to_s }

        it 'wraps snippet patterns in parentheses' do
          @step_text = 'A "string" with 4 spaces'
          cucumber_output = <<~CUKE.chomp
            Given(/^A "([^"]*)" with (\\d+) spaces$/) do |arg1, arg2|
              pending # Write code here that turns the phrase above into concrete actions
            end
          CUKE

          expect(snippet_text).to eq(cucumber_output)
        end

        it 'recognises numbers in name and make according regexp' do
          @step_text = 'Cloud 9 yeah'
          cucumber_output = <<~CUKE.chomp
            Given(/^Cloud (\\d+) yeah$/) do |arg1|
              pending # Write code here that turns the phrase above into concrete actions
            end
          CUKE

          expect(snippet_text).to eq(cucumber_output)
        end

        it 'recognises a mix of ints, strings and why not a table too' do
          @step_text = 'I have 9 "awesome" cukes in 37 "boxes"'
          @multiline_argument = Core::Test::DataTable.new([[]])
          cucumber_output = <<~CUKE.chomp
            Given(/^I have (\\d+) "([^"]*)" cukes in (\\d+) "([^"]*)"$/) do |arg1, arg2, arg3, arg4, table|
              # table is a Cucumber::MultilineArgument::DataTable
              pending # Write code here that turns the phrase above into concrete actions
            end
          CUKE

          expect(snippet_text).to eq(cucumber_output)
        end

        it 'recognises quotes in name and make according regexp' do
          @step_text = 'A "first" arg'
          cucumber_output = <<~CUKE.chomp
            Given(/^A "([^"]*)" arg$/) do |arg1|
              pending # Write code here that turns the phrase above into concrete actions
            end
          CUKE

          expect(snippet_text).to eq(cucumber_output)
        end

        it 'recognises several quoted words in name and make according regexp and args' do
          @step_text = 'A "first" and "second" arg'
          cucumber_output = <<~CUKE.chomp
            Given(/^A "([^"]*)" and "([^"]*)" arg$/) do |arg1, arg2|
              pending # Write code here that turns the phrase above into concrete actions
            end
          CUKE

          expect(snippet_text).to eq(cucumber_output)
        end

        it 'does not use quote group when there are no quotes' do
          @step_text = 'A first arg'
          cucumber_output = <<~CUKE.chomp
            Given(/^A first arg$/) do
              pending # Write code here that turns the phrase above into concrete actions
            end
          CUKE

          expect(snippet_text).to eq(cucumber_output)
        end

        it 'is helpful with tables' do
          @step_text = 'A "first" arg'
          @multiline_argument = Core::Test::DataTable.new([[]])
          cucumber_output = <<~CUKE.chomp
            Given(/^A "([^"]*)" arg$/) do |arg1, table|
              # table is a Cucumber::MultilineArgument::DataTable
              pending # Write code here that turns the phrase above into concrete actions
            end
          CUKE

          expect(snippet_text).to eq(cucumber_output)
        end

        it 'is helpful with doc string' do
          @step_text = 'A "first" arg'
          @multiline_argument = MultilineArgument.from('', Core::Test::Location.new(''))
          cucumber_output = <<~CUKE.chomp
            Given(/^A "([^"]*)" arg$/) do |arg1, doc_string|
              pending # Write code here that turns the phrase above into concrete actions
            end
          CUKE

          expect(snippet_text).to eq(cucumber_output)
        end
      end

      describe Snippet::Classic do
        let(:snippet_class) { described_class }

        it 'renders snippet as unwrapped regular expression' do
          cucumber_output = <<~CUKE.chomp
            Given /^we have a missing step$/ do
              pending # Write code here that turns the phrase above into concrete actions
            end
          CUKE

          expect(snippet.to_s).to eq(cucumber_output)
        end
      end

      describe Snippet::Percent do
        let(:snippet_class) { described_class }

        it 'renders snippet as percent-style regular expression' do
          cucumber_output = <<~CUKE.chomp
            Given %r{^we have a missing step$} do
              pending # Write code here that turns the phrase above into concrete actions
            end
          CUKE

          expect(snippet.to_s).to eq(cucumber_output)
        end
      end

      describe Snippet::CucumberExpression do
        let(:snippet_class) { described_class }

        it 'renders snippet as cucumber expression' do
          @step_text = 'I have 2.3 cukes in my belly'
          @registry.define_parameter_type(CucumberExpressions::ParameterType.new(
                                            'veg',
                                            /(cuke|banana)s?/,
                                            Object,
                                            ->(s) { s },
                                            true,
                                            false
                                          ))
          @registry.define_parameter_type(CucumberExpressions::ParameterType.new(
                                            'cucumis',
                                            /(bella|cuke)s?/,
                                            Object,
                                            ->(s) { s },
                                            true,
                                            false
                                          ))

          cucumber_output = <<~CUKE.chomp
            Given('I have {float} {cucumis} in my belly') do |float, cucumis|
            # Given('I have {float} {veg} in my belly') do |float, veg|
              pending # Write code here that turns the phrase above into concrete actions
            end
          CUKE

          expect(snippet.to_s).to eq(cucumber_output)
        end
      end
    end
  end
end
